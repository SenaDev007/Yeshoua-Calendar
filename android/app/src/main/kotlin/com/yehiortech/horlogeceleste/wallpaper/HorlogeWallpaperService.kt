package com.yehiortech.horlogeceleste.wallpaper

import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.RadialGradient
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import java.util.Calendar
import java.util.Locale
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * ⭐ FOND D'ÉCRAN ANIMÉ « HORLOGE CÉLESTE » (§9.5) — écran de verrouillage
 * biblique natif.
 *
 * PRINCIPE : Android interdit le remplacement du verrouillage système, mais
 * depuis Android 13 l'utilisateur peut affecter un fond d'écran animé
 * UNIQUEMENT à l'écran de verrouillage (sélecteur système). Voilà l'effet
 * voulu : quand le téléphone se verrouille, l'horloge biblique apparaît.
 *
 * RENDU (100 % natif Kotlin — AUCUN moteur Flutter en arrière-plan, batterie
 * préservée) :
 *   • fond nocturne céleste + étoiles discrètes + halo doré ;
 *   • cadran 24 HEURES BIBLIQUES (1→24), coucher du soleil à GAUCHE
 *     (heure biblique 01:00), 15° par heure — identique au widget Flutter ;
 *   • image de fond du cadran partagée avec l'app (moitié nuit / moitié
 *     jour), dégradés de repli ;
 *   • aiguilles ancrées au TEMPS ÉCOULÉ depuis le DERNIER COUCHER RÉEL
 *     (même algorithme NOAA que le moteur Dart — SolarNoaa) ;
 *   • médaillon central : heure biblique + Nuit/Jour ;
 *   • prochaine alarme programmée sous le cadran (« dans 7 h 12 ») ;
 *   • TROTTEUSE FLUIDE (~30 img/s) ou TIC-TAC par seconde, au choix dans
 *     les Réglages — lu depuis l'instantané partagé (shared_preferences) ;
 *   • rendu SUSPENDU dès que l'écran du wallpaper est caché.
 */
class HorlogeWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = HorlogeEngine()

    // ── Constantes partagées avec le moteur Dart ─────────────────────────
    private companion object {
        // shared_preferences Android : fichier + préfixe imposés par le
        // plugin Flutter (toutes les clés Dart sont « flutter.<clé> »).
        const val NOM_PREFS = "FlutterSharedPreferences"
        const val CLE_SNAPSHOT = "flutter.hc_wallpaper_snapshot"
        const val NOM_ASSET_FOND =
            "flutter_assets/assets/images/cadran-biblique-fond.png"

        // Repli : position par défaut de l'app (AppConfig — Cotonou).
        const val LAT_DEFAUT = 6.37
        const val LON_DEFAUT = 2.42

        // Géométrie du cadran (identique à horloge_analogique.dart).
        const val ANGLE_ORIGINE = 270.0 // heure biblique 1 = GAUCHE
        const val DEGRES_PAR_HEURE = 15.0
        const val RAYON_CANONIQUE = 150.0 // cadre de référence du painter

        // Cadence du mode fluide (~30 img/s — bon compromis batterie).
        const val CADENCE_FLUIDE_MS = 33L
    }

    /** Une alarme de l'instantané (libellé + règle de déclenchement). */
    private data class AlarmeInfo(
        val libelle: String,
        val type: String, // "fixe" | "coucher" | "preparation"
        val heure: Int,
        val minute: Int,
        val minutesAvant: Int,
        val activee: Boolean,
    )

    inner class HorlogeEngine : Engine() {

        private val handler = Handler(Looper.getMainLooper())
        private val tacheRendu = Runnable { dessiner() }

        private var visible = false
        private var largeur = 0
        private var hauteur = 0

        // ── Instantané partagé (écrit par l'app Flutter) ──
        private var latitude = LAT_DEFAUT
        private var longitude = LON_DEFAUT
        private var trotteuseFluide = true
        private var alarmes: List<AlarmeInfo> = emptyList()

        // ── Ressources graphiques ──
        private var fondCadran: Bitmap? = null

        private val prefs: SharedPreferences =
            applicationContext.getSharedPreferences(NOM_PREFS, 0)

        /** Écouteur FORT (champ) — sans lui le GC désactiverait l'écoute. */
        private val ecouteurSnapshot =
            SharedPreferences.OnSharedPreferenceChangeListener { _, cle ->
                if (cle == CLE_SNAPSHOT) {
                    chargerSnapshot()
                    if (visible) {
                        handler.removeCallbacks(tacheRendu)
                        handler.post(tacheRendu)
                    }
                }
            }

        // ── Pinceaux réutilisés (zéro allocation par image) ──
        private val pFondImg = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            isFilterBitmap = true
        }
        private val pFondDeg = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pCiel = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pHalo = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pEtoile = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pLisere = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
        }
        private val pAnneau = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
        }
        private val pGrad = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }
        private val pChiffre = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        private val pMedaillon = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pMedaillonLisere = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
        }
        private val pTitre = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        private val pHeureTxt = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        private val pPeriode = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        private val pAiguille = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pTrait = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            strokeCap = Paint.Cap.ROUND
        }
        private val pPoint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pArc = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }
        private val pPill = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pAlarmeTxt = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }

        // ── Cycle de vie ──

        override fun onCreate(holder: SurfaceHolder) {
            super.onCreate(holder)
            chargerSnapshot()
            fondCadran = chargerBitmapFond()
            prefs.registerOnSharedPreferenceChangeListener(ecouteurSnapshot)
        }

        override fun onDestroy() {
            visible = false // Stoppe net toute boucle de rendu résiduelle.
            handler.removeCallbacks(tacheRendu)
            prefs.unregisterOnSharedPreferenceChangeListener(ecouteurSnapshot)
            fondCadran?.recycle()
            fondCadran = null
            super.onDestroy()
        }

        override fun onVisibilityChanged(vis: Boolean) {
            visible = vis
            if (visible) {
                chargerSnapshot()
                handler.removeCallbacks(tacheRendu)
                handler.post(tacheRendu)
            } else {
                handler.removeCallbacks(tacheRendu)
            }
        }

        override fun onSurfaceChanged(
            holder: SurfaceHolder,
            format: Int,
            width: Int,
            height: Int,
        ) {
            super.onSurfaceChanged(holder, format, width, height)
            largeur = width
            hauteur = height
            if (visible) {
                handler.removeCallbacks(tacheRendu)
                handler.post(tacheRendu)
            }
        }

        // ── Instantané partagé ──

        private fun chargerSnapshot() {
            try {
                val brut = prefs.getString(CLE_SNAPSHOT, null) ?: return
                val obj = org.json.JSONObject(brut)
                latitude = obj.optDouble("lat", latitude)
                longitude = obj.optDouble("lon", longitude)
                trotteuseFluide = obj.optBoolean("trotteuseFluide", true)
                val arr = obj.optJSONArray("alarmes")
                if (arr != null) {
                    val liste = ArrayList<AlarmeInfo>(arr.length())
                    for (i in 0 until arr.length()) {
                        val a = arr.getJSONObject(i)
                        liste.add(
                            AlarmeInfo(
                                libelle = a.optString("libelle", "Alarme"),
                                type = a.optString("type", "fixe"),
                                heure = a.optInt("heure", 5),
                                minute = a.optInt("minute", 0),
                                minutesAvant = a.optInt("minutesAvant", 5),
                                activee = a.optBoolean("activee", false),
                            )
                        )
                    }
                    alarmes = liste
                }
            } catch (_: Exception) {
                // Instantané illisible : on garde les valeurs précédentes.
            }
        }

        private fun chargerBitmapFond(): Bitmap? = try {
            applicationContext.assets.open(NOM_ASSET_FOND).use { flux ->
                BitmapFactory.decodeStream(flux, null, BitmapFactory.Options())
            }
        } catch (_: Exception) {
            null // Dégradés de repli (voir peindreCadran).
        }

        // ── Boucle de rendu ──

        private fun dessiner() {
            if (!visible || largeur <= 0 || hauteur <= 0) return
            val holder = surfaceHolder
            val canvas = holder.lockCanvas()
            if (canvas == null) {
                // Surface pas prête : nouvelle tentative courte.
                handler.postDelayed(tacheRendu, 250L)
                return
            }
            try {
                peindre(canvas, largeur, hauteur)
            } catch (_: Exception) {
                // Jamais de crash d'un fond d'écran (métadonnées corrompues…).
            } finally {
                try {
                    holder.unlockCanvasAndPost(canvas)
                } catch (_: Exception) {
                }
            }
            planifierProchaine()
        }

        private fun planifierProchaine() {
            if (!visible) return
            handler.removeCallbacks(tacheRendu)
            val delai = if (trotteuseFluide) {
                CADENCE_FLUIDE_MS
            } else {
                // Aligné sur la FRONTIÈRE de la seconde suivante (tic-tac).
                1000L - (System.currentTimeMillis() % 1000L) + 2L
            }
            handler.postDelayed(tacheRendu, delai)
        }

        // ── Astronomie locale (mêmes règles que le moteur Dart) ──

        /** Coucher du soleil du jour [c] — Calendar aligné, ou null (polaire). */
        private fun coucherPour(jour: Calendar): Calendar? {
            val minutes = SolarNoaa.coucherMinutes(
                jour.get(Calendar.YEAR),
                jour.get(Calendar.MONTH) + 1,
                jour.get(Calendar.DAY_OF_MONTH),
                latitude,
                longitude,
                jour.timeZone.getOffset(jour.timeInMillis) / 60000,
            ) ?: return null
            val c = (jour.clone() as Calendar)
            c.set(Calendar.HOUR_OF_DAY, 0)
            c.set(Calendar.MINUTE, 0)
            c.set(Calendar.SECOND, 0)
            c.set(Calendar.MILLISECOND, 0)
            c.add(Calendar.MILLISECOND, (minutes * 60000.0).roundToInt())
            return c
        }

        /** DERNIER coucher écoulé (hier si celui d'aujourd'hui est à venir). */
        private fun dernierCoucher(now: Calendar): Calendar? {
            val aujourdhui = coucherPour(now)
            if (aujourdhui != null && now.timeInMillis >= aujourdhui.timeInMillis) {
                return aujourdhui
            }
            val hier = (now.clone() as Calendar)
            hier.add(Calendar.DAY_OF_YEAR, -1)
            return coucherPour(hier)
        }

        /** Instant de déclenchement d'une alarme (aujourd'hui ou demain). */
        private fun quand(alarme: AlarmeInfo, now: Calendar): Calendar? =
            when (alarme.type) {
                "fixe" -> {
                    val c = (now.clone() as Calendar)
                    c.set(Calendar.HOUR_OF_DAY, alarme.heure.coerceIn(0, 23))
                    c.set(Calendar.MINUTE, alarme.minute.coerceIn(0, 59))
                    c.set(Calendar.SECOND, 0)
                    c.set(Calendar.MILLISECOND, 0)
                    if (c.timeInMillis <= now.timeInMillis) {
                        c.add(Calendar.DAY_OF_YEAR, 1)
                    }
                    c
                }
                "coucher" -> {
                    val c = coucherPour(now)
                    if (c != null && c.timeInMillis > now.timeInMillis) {
                        c
                    } else {
                        val demain = (now.clone() as Calendar)
                        demain.add(Calendar.DAY_OF_YEAR, 1)
                        coucherPour(demain)
                    }
                }
                "preparation" -> {
                    val c = coucherPour(now)?.apply {
                        add(Calendar.MILLISECOND, -alarme.minutesAvant * 60000)
                    }
                    if (c != null && c.timeInMillis > now.timeInMillis) {
                        c
                    } else {
                        val demain = (now.clone() as Calendar)
                        demain.add(Calendar.DAY_OF_YEAR, 1)
                        coucherPour(demain)?.apply {
                            add(Calendar.MILLISECOND, -alarme.minutesAvant * 60000)
                        }
                    }
                }
                else -> null
            }

        /** Prochaine alarme active — (alarme, instant) ou null. */
        private fun prochaineAlarme(now: Calendar): Pair<AlarmeInfo, Calendar>? {
            var meilleure: Pair<AlarmeInfo, Calendar>? = null
            for (a in alarmes) {
                if (!a.activee) continue
                val c = quand(a, now) ?: continue
                if (meilleure == null || c.timeInMillis < meilleure.second.timeInMillis) {
                    meilleure = a to c
                }
            }
            return meilleure
        }

        // ── Peinture ──

        /** Baseline verticale pour centrer un texte sur [y]. */
        private fun baselineCentre(p: Paint, y: Float): Float {
            val fm = p.fontMetrics
            return y - (fm.ascent + fm.descent) / 2f
        }

        /** Position sur le cadran : angle en ° depuis le HAUT, horaire. */
        private fun pos(cx: Float, cy: Float, degres: Double, rayon: Float):
                Pair<Float, Float> {
            val a = degres * Math.PI / 180.0
            val x = cx + (Math.sin(a) * rayon).toFloat()
            val y = cy - (Math.cos(a) * rayon).toFloat()
            return x to y
        }

        /** Aiguille triangulaire effilée depuis le centre. */
        private fun aiguille(
            canvas: Canvas,
            cx: Float,
            cy: Float,
            angleDegres: Double,
            longueur: Float,
            largeur: Float,
            couleur: Int,
        ) {
            val a = angleDegres * Math.PI / 180.0
            val dx = Math.sin(a).toFloat()
            val dy = (-Math.cos(a)).toFloat()
            val boutX = cx + dx * longueur
            val boutY = cy + dy * longueur
            val px = -dy
            val py = dx
            val demi = largeur / 2f
            val chemin = Path()
            chemin.moveTo(cx + px * demi, cy + py * demi)
            chemin.lineTo(boutX, boutY)
            chemin.lineTo(cx - px * demi, cy - py * demi)
            chemin.close()
            pAiguille.color = couleur
            canvas.drawPath(chemin, pAiguille)
        }

        private fun peindre(canvas: Canvas, w: Int, h: Int) {
            val wf = w.toFloat()
            val hf = h.toFloat()
            val cx = wf / 2f
            val cy = hf * 0.44f
            val R = min(wf, hf) * 0.33f
            val s = (R / RAYON_CANONIQUE).toFloat()

            val minutes = cycleMinutes()
            val nuitCourante = heureBiblique(minutes).first

            // ── 1. Ciel céleste + étoiles + halo doré ──
            pCiel.shader = LinearGradient(
                0f, 0f, 0f, hf,
                intArrayOf(0xFF1B2A5E.toInt(), 0xFF0C1228.toInt()),
                null, Shader.TileMode.CLAMP,
            )
            canvas.drawRect(0f, 0f, wf, hf, pCiel)

            pEtoile.color = 0xFFFFFFFF.toInt()
            for (i in 0 until 42) {
                val fx = ((i * 73) % 97) / 97.0
                val fy = ((i * 137) % 89) / 89.0
                val x = (fx * wf).toFloat()
                val y = (fy * hf * 0.62).toFloat()
                pEtoile.alpha = 45 + (i % 4) * 15
                val rr = max(0.8f, (1.0f + (i % 3) * 0.7f) * (R / 356f))
                canvas.drawCircle(x, y, rr, pEtoile)
            }

            pHalo.shader = RadialGradient(
                cx, cy, R * 1.5f,
                intArrayOf(0x2CCFA63A, 0x00CFA63A),
                null, Shader.TileMode.CLAMP,
            )
            canvas.drawCircle(cx, cy, R * 1.5f, pHalo)

            // ── 2. Cadran ──
            peindreCadran(canvas, cx, cy, R, s, nuitCourante, minutes)

            // ── 3. Prochaine alarme ──
            peindreAlarme(canvas, cx, hf, R, s)
        }

        /**
         * Minutes écoulées depuis le DERNIER COUCHER RÉEL (0→1440) —
         * repli 18 h 00 si calcul polaire indisponible (comme l'app).
         */
        private fun cycleMinutes(): Double {
            val now = Calendar.getInstance()
            val dernier = dernierCoucher(now)
            if (dernier != null) {
                val e = (now.timeInMillis - dernier.timeInMillis) / 60000.0
                if (e >= 0) return e % 1440.0
                return 0.0
            }
            val hCivile = (now.get(Calendar.HOUR_OF_DAY) - 18 + 24) % 24
            return hCivile * 60.0 + now.get(Calendar.MINUTE) +
                    now.get(Calendar.SECOND) / 60.0
        }

        /** (estNuit?, minutes) — nuit = heures bibliques 1→12 (moitié haute). */
        private fun heureBiblique(minutes: Double): Pair<Boolean, Int> {
            val n = (floor(minutes).toInt() / 60) % 24
            return Pair(n < 12, n)
        }

        private fun peindreCadran(
            canvas: Canvas,
            cx: Float,
            cy: Float,
            R: Float,
            s: Float,
            nuit: Boolean,
            minutes: Double,
        ) {
            val rect = RectF(cx - R, cy - R, cx + R, cy + R)

            // Fond du cadran : image partagée (nuit/jour) ou dégradés.
            val img = fondCadran
            if (img != null && !img.isRecycled) {
                val cercle = Path()
                cercle.addCircle(cx, cy, R, Path.Direction.CW)
                canvas.save()
                canvas.clipPath(cercle)
                canvas.drawBitmap(img, null, rect, pFondImg)
                canvas.restore()
            } else {
                pFondDeg.shader = RadialGradient(
                    cx - R * 0.9f, cy, R * 1.6f,
                    intArrayOf(0xFF31407E.toInt(), 0xFF10163A.toInt()),
                    null, Shader.TileMode.CLAMP,
                )
                canvas.drawArc(rect, 180f, 180f, true, pFondDeg)
                pFondDeg.shader = RadialGradient(
                    cx + R * 0.9f, cy, R * 1.6f,
                    intArrayOf(0xFF96C7F0.toInt(), 0xFF78B4E2.toInt()),
                    null, Shader.TileMode.CLAMP,
                )
                canvas.drawArc(rect, 0f, 180f, true, pFondDeg)
            }

            // Liseré extérieur or + anneau fin (signature).
            pLisere.strokeWidth = 3f * s
            pLisere.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(cx, cy, R, pLisere)
            pAnneau.strokeWidth = 1.4f * s
            pAnneau.color = 0x8CCFA63A.toInt()
            canvas.drawCircle(cx, cy, R - 9f * s, pAnneau)

            // Graduations : 24 heures majeures + quarts mineures.
            for (i in 0 until 96) {
                val angle = i * 3.75
                val majeure = i % 4 == 0
                val r1 = R - (if (majeure) 24f else 15f) * s
                val r2 = R - 13f * s
                pGrad.strokeWidth = (if (majeure) 2.6f else 1.1f) * s
                if (majeure) {
                    pGrad.color = 0xFFF0D68A.toInt()
                    pGrad.alpha = 217 // 0.85
                } else {
                    pGrad.color = 0xFFFFFFFF.toInt()
                    pGrad.alpha = 89 // 0.35
                }
                val (x1, y1) = pos(cx, cy, angle, r1)
                val (x2, y2) = pos(cx, cy, angle, r2)
                canvas.drawLine(x1, y1, x2, y2, pGrad)
            }

            // Chiffres des 24 heures bibliques.
            pChiffre.textSize = (R * 0.093f).coerceAtLeast(9f)
            for (h in 1..24) {
                val angle = (ANGLE_ORIGINE + (h - 1) * DEGRES_PAR_HEURE) % 360.0
                val demiNuit = angle >= 262.5 || angle < 97.5
                if (demiNuit) {
                    pChiffre.color = 0xFFE7D3A1.toInt()
                    pChiffre.alpha = 242 // 0.95
                } else {
                    pChiffre.color = 0xFF1E293B.toInt()
                    pChiffre.alpha = 230 // 0.9
                }
                val r = R - 40f * s
                val (x, y) = pos(cx, cy, angle, r)
                canvas.drawText(h.toString(), x, baselineCentre(pChiffre, y), pChiffre)
            }

            // Marqueurs solaires : coucher (heure 1, gauche) et lever (13, droite).
            for (a in doubleArrayOf(
                ANGLE_ORIGINE,
                (ANGLE_ORIGINE + 12 * DEGRES_PAR_HEURE) % 360.0,
            )) {
                val (x, y) = pos(cx, cy, a, R - 5.5f * s)
                pPoint.color = 0xFFCFA63A.toInt()
                canvas.drawCircle(x, y, 5f * s, pPoint)
                pPoint.color = 0xE6FFFFFF.toInt()
                canvas.drawCircle(x, y, 2.2f * s, pPoint)
            }

            // ── Arc du cycle écoulé : du coucher (270°) à l'heure courante ──
            pArc.strokeWidth = 4.5f * s
            pArc.color = 0xBFCFA63A.toInt() // 0.75
            val rectArc = RectF(cx - (R - 5f * s), cy - (R - 5f * s),
                cx + (R - 5f * s), cy + (R - 5f * s))
            canvas.drawArc(
                rectArc,
                (ANGLE_ORIGINE - 90.0).toFloat(),
                (minutes / 1440.0 * 360.0).toFloat(),
                false,
                pArc,
            )

            // ── Médaillon central ──
            val rm = R * 0.34f
            pMedaillon.color = if (nuit) 0xFF1E293B.toInt() else 0xFFEFF6FF.toInt()
            canvas.drawCircle(cx, cy, rm, pMedaillon)
            pMedaillonLisere.strokeWidth = 1.6f * s
            pMedaillonLisere.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(cx, cy, rm, pMedaillonLisere)

            val hB = (floor(minutes).toInt() / 60) % 24 + 1
            val mB = floor(minutes).toInt() % 60
            val texteHeure = String.format(Locale.US, "%02d h %02d", hB, mB)

            pTitre.textSize = (R * 0.052f).coerceAtLeast(8f)
            pTitre.letterSpacing = 0.08f
            if (nuit) {
                pTitre.color = 0xFFF0D68A.toInt()
            } else {
                pTitre.color = 0xFF3B82F6.toInt()
            }
            pTitre.alpha = 217 // 0.85
            canvas.drawText(
                "HEURE BIBLIQUE", cx,
                baselineCentre(pTitre, cy - rm * 0.50f), pTitre,
            )

            pHeureTxt.textSize = (R * 0.105f).coerceAtLeast(13f)
            pHeureTxt.color = 0xFFF0D68A.toInt()
            canvas.drawText(
                texteHeure, cx,
                baselineCentre(pHeureTxt, cy + rm * 0.05f), pHeureTxt,
            )

            pPeriode.textSize = (R * 0.058f).coerceAtLeast(9f)
            if (nuit) {
                pPeriode.color = 0xFFE7D3A1.toInt()
                pPeriode.alpha = 230
                canvas.drawText(
                    "Nuit", cx,
                    baselineCentre(pPeriode, cy + rm * 0.55f), pPeriode,
                )
            } else {
                pPeriode.color = 0xFFFFFFFF.toInt()
                pPeriode.alpha = 230
                canvas.drawText(
                    "Jour", cx,
                    baselineCentre(pPeriode, cy + rm * 0.55f), pPeriode,
                )
            }

            // ── Aiguilles (angles depuis le DERNIER COUCHER RÉEL) ──
            val indiceHeure = (floor(minutes).toInt() / 60) % 24
            val angleBaseHeure = ANGLE_ORIGINE + indiceHeure * DEGRES_PAR_HEURE
            val fractionHeure = (minutes % 60.0) / 60.0
            val angleHeures = ANGLE_ORIGINE + minutes / 1440.0 * 360.0
            val angleMinutes = angleBaseHeure + fractionHeure * 360.0
            val fractionSeconde = if (trotteuseFluide) {
                (System.currentTimeMillis() % 1000L) / 1000.0
            } else {
                0.0
            }
            val angleSecondes = angleBaseHeure +
                    ((floor(minutes % 60.0).toInt() + fractionSeconde) / 60.0) *
                    360.0

            val couleurAiguilles = if (nuit) 0xFFE7D3A1.toInt() else 0xFF1E293B.toInt()
            aiguille(canvas, cx, cy, angleHeures, R * 0.46f, 7f * s, couleurAiguilles)
            aiguille(canvas, cx, cy, angleMinutes, R * 0.64f, 4.5f * s, couleurAiguilles)
            aiguille(canvas, cx, cy, angleSecondes, R * 0.74f, 2f * s, 0xFFCFA63A.toInt())

            // Contrepoids de la trotteuse.
            val aS = angleSecondes * Math.PI / 180.0
            val dxS = Math.sin(aS).toFloat()
            val dyS = (-Math.cos(aS)).toFloat()
            pTrait.strokeWidth = 2f * s
            pTrait.color = 0xFFCFA63A.toInt()
            canvas.drawLine(cx, cy, cx - dxS * 18f * s, cy - dyS * 18f * s, pTrait)
            pPoint.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(cx - dxS * 18f * s, cy - dyS * 18f * s, 3.2f * s, pPoint)

            // Moyeu central doré.
            pPoint.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(cx, cy, 6.5f * s, pPoint)
            pPoint.color = 0xFFFFFFFF.toInt()
            canvas.drawCircle(cx, cy, 2.6f * s, pPoint)
        }

        private fun peindreAlarme(
            canvas: Canvas,
            cx: Float,
            hf: Float,
            R: Float,
            s: Float,
        ) {
            val maintenant = Calendar.getInstance()
            val suivante = prochaineAlarme(maintenant) ?: return
            val (alarme, instant) = suivante

            val diffMin =
                ((instant.timeInMillis - maintenant.timeInMillis) / 60000L)
                    .coerceAtLeast(0L)
            val delta = if (diffMin >= 60L) {
                "dans ${diffMin / 60L} h ${diffMin % 60L} min"
            } else {
                "dans $diffMin min"
            }
            val heureAffichee = String.format(
                Locale.US, "%02d h %02d",
                instant.get(Calendar.HOUR_OF_DAY),
                instant.get(Calendar.MINUTE),
            )
            val texte =
                "Prochaine alarme · ${alarme.libelle} · $heureAffichee · $delta"

            pAlarmeTxt.textSize = max(R * 0.05f, 11f * s)
            val tw = pAlarmeTxt.measureText(texte)
            val marge = pAlarmeTxt.textSize * 0.85f
            val y = hf * 0.905f
            val rect = RectF(
                cx - tw / 2f - marge,
                y - pAlarmeTxt.textSize * 1.05f,
                cx + tw / 2f + marge,
                y + pAlarmeTxt.textSize * 0.55f,
            )
            pPill.color = Color.argb(105, 8, 14, 34)
            canvas.drawRoundRect(rect, rect.height() / 2f, rect.height() / 2f, pPill)

            pPoint.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(
                rect.left + marge * 0.7f, y,
                pAlarmeTxt.textSize * 0.16f, pPoint,
            )

            pAlarmeTxt.color = 0xFFF5F0E6.toInt()
            canvas.drawText(texte, cx, baselineCentre(pAlarmeTxt, y), pAlarmeTxt)
        }
    }
}
