package com.yehiortech.horlogeceleste.wallpaper

import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Movie
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
import java.io.BufferedInputStream
import java.text.SimpleDateFormat
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
 * préservée) — v1.0.9 : MÊME HORLOGE QUE LA PAGE HORLOGE (demande
 * utilisateur) :
 *   • FOND = GIF ANIMÉ de la page d'accueil (2e carte « Période en cours » :
 *     periode-jour.gif / periode-nuit.gif selon la phase réelle) + voile
 *     sombre pour la lisibilité — repli : ciel étoilé + halo doré ;
 *   • cadran CIVIL 24 h IDENTIQUE au painter Flutter : 00 en HAUT, 06 à
 *     DROITE, 12 en BAS, 18 à GAUCHE ; chiffres pairs en grands caractères
 *     et impairs en petits ; minuteur interne 05…60 ; pastilles sombres
 *     derrière 06 h et 18 h (lisibilité sur les zones lumineuses du décor) ;
 *   • AIGUILLES À L'HEURE CIVILE RÉELLE (aiguille des heures : un tour par
 *     24 h — conformes à l'horloge numérique de l'app) + trotteuse rouge
 *     avec contrepoids (fluide ~30 img/s ou tic-tac, même réglage) ;
 *   • ARC du cycle biblique écoulé depuis le DERNIER COUCHER RÉEL (NOAA,
 *     SolarNoaa — le même algorithme que le moteur Dart) ;
 *   • médaillon central : HEURE CIVILE (conforme aux aiguilles) + période
 *     biblique calculée nativement (3 veilles / 12 heures saisonnières) ;
 *   • date biblique AU-DESSUS du cadran (instantané partagé) et ligne
 *     d'informations SOUS le cadran : heure civile · prochain coucher ·
 *     position — exactement les informations de la page horloge ;
 *   • prochaine alarme programmée (« dans 7 h 12 ») ;
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
        const val NOM_ASSET_GIF_JOUR =
            "flutter_assets/assets/images/periode-jour.gif"
        const val NOM_ASSET_GIF_NUIT =
            "flutter_assets/assets/images/periode-nuit.gif"
        const val NOM_ASSET_FOND =
            "flutter_assets/assets/images/cadran-biblique-fond.png"

        // Repli : position par défaut de l'app (AppConfig — Cotonou).
        const val LAT_DEFAUT = 6.37
        const val LON_DEFAUT = 2.42

        // Géométrie du cadran civil 24 h (identique à horloge_analogique.dart).
        const val DEGRES_PAR_HEURE = 15.0 // 360 / 24
        const val DEGRES_PAR_MINUTE = 6.0 // 360 / 60
        const val RAYON_CANONIQUE = 150.0 // cadre de référence du painter

        // Cadence du mode fluide (~30 img/s — bon compromis batterie).
        const val CADENCE_FLUIDE_MS = 33L

        // Périodes bibliques (mêmes textes que BiblicalTimeEngine).
        val VEILLES_NOMS = arrayOf(
            "Première VEILLE", "Deuxième VEILLE", "Troisième VEILLE",
        )
        val PARTIES_JOUR = arrayOf(
            "Matin", "Approche du milieu du jour", "Après-midi", "Fin du jour",
        )
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

    /** Période biblique en cours (médaillon). */
    private data class Periode(
        val nuit: Boolean,
        val libelle: String,   // « Première VEILLE » / « Heure 7 »
        val sousTitre: String, // sous-titre ou repère
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
        private var positionLibelle = ""
        private var dateBibliqueTxt = ""
        private var alarmes: List<AlarmeInfo> = emptyList()

        // ── Ressources graphiques ──
        private var fondCadran: Bitmap? = null
        private var filmJour: Movie? = null
        private var filmNuit: Movie? = null
        private val filmDebutMs = System.currentTimeMillis()

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
        private val pVoile = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pCiel = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pHalo = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pEtoile = Paint(Paint.ANTI_ALIAS_FLAG)
        private val pPastille = Paint(Paint.ANTI_ALIAS_FLAG)
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
        private val pDate = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        }
        private val pInfoTxt = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
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

        // ── Cycle de vie ──

        override fun onCreate(holder: SurfaceHolder) {
            super.onCreate(holder)
            chargerSnapshot()
            fondCadran = chargerBitmapFond()
            filmJour = chargerFilm(NOM_ASSET_GIF_JOUR)
            filmNuit = chargerFilm(NOM_ASSET_GIF_NUIT)
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
                positionLibelle = obj.optString("positionLibelle", "")
                dateBibliqueTxt = obj.optString("dateBibliqueTxt", "")
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

        /** GIF animé de l'accueil (2e carte « Période en cours »). */
        private fun chargerFilm(nom: String): Movie? = try {
            applicationContext.assets.open(nom).use { flux ->
                Movie.decodeStream(BufferedInputStream(flux, 8192))
            }
        } catch (_: Exception) {
            null // Repli : ciel céleste peint.
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

        private fun minutesDuJour(
            c: Calendar,
            lever: Boolean,
        ): Double? = SolarNoaa.run {
            if (lever) leverMinutes(
                c.get(Calendar.YEAR),
                c.get(Calendar.MONTH) + 1,
                c.get(Calendar.DAY_OF_MONTH),
                latitude,
                longitude,
                c.timeZone.getOffset(c.timeInMillis) / 60000,
            )
            else coucherMinutes(
                c.get(Calendar.YEAR),
                c.get(Calendar.MONTH) + 1,
                c.get(Calendar.DAY_OF_MONTH),
                latitude,
                longitude,
                c.timeZone.getOffset(c.timeInMillis) / 60000,
            )
        }

        /** Instant du lever / coucher du jour civil [jour] (Calendar), ou null. */
        private fun solairePour(jour: Calendar, lever: Boolean): Calendar? {
            val minutes = minutesDuJour(jour, lever) ?: return null
            val c = (jour.clone() as Calendar)
            c.set(Calendar.HOUR_OF_DAY, 0)
            c.set(Calendar.MINUTE, 0)
            c.set(Calendar.SECOND, 0)
            c.set(Calendar.MILLISECOND, 0)
            c.add(Calendar.MILLISECOND, (minutes * 60000.0).roundToInt())
            return c
        }

        private fun leverPour(jour: Calendar): Calendar? = solairePour(jour, lever = true)

        private fun coucherPour(jour: Calendar): Calendar? = solairePour(jour, lever = false)

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

        /** PROCHAIN coucher à venir (aujourd'hui ou demain) — ligne infos. */
        private fun prochainCoucher(now: Calendar): Calendar? {
            val aujourdhui = coucherPour(now)
            if (aujourdhui != null && aujourdhui.timeInMillis > now.timeInMillis) {
                return aujourdhui
            }
            val demain = (now.clone() as Calendar)
            demain.add(Calendar.DAY_OF_YEAR, 1)
            return coucherPour(demain)
        }

        /**
         * Période biblique en cours — miroir de BiblicalTimeEngine : 3
         * veilles (tiers réels de la nuit, coucher → lever) puis 12 heures
         * saisonnières (lever → coucher). Repli : « — » si polaire.
         */
        private fun periodeBiblique(now: Calendar): Periode {
            val coucherAuj = coucherPour(now)
            val leverAuj = leverPour(now)

            // Nuit commencée ce soir : du coucher d'aujourd'hui au lever de demain.
            if (coucherAuj != null && now.timeInMillis >= coucherAuj.timeInMillis) {
                val demain = (now.clone() as Calendar)
                demain.add(Calendar.DAY_OF_YEAR, 1)
                val leverDemain = leverPour(demain)
                if (leverDemain != null) {
                    val duree = leverDemain.timeInMillis - coucherAuj.timeInMillis
                    val ecoule = now.timeInMillis - coucherAuj.timeInMillis
                    val idx = ((ecoule.toDouble() / duree) * 3.0).toInt()
                        .coerceIn(0, 2)
                    return Periode(true, VEILLES_NOMS[idx], "Nuit biblique")
                }
            }
            // Jour en cours : du lever d'aujourd'hui au coucher d'aujourd'hui.
            if (leverAuj != null && now.timeInMillis >= leverAuj.timeInMillis &&
                (coucherAuj == null || now.timeInMillis < coucherAuj.timeInMillis)
            ) {
                if (coucherAuj != null) {
                    val duree = coucherAuj.timeInMillis - leverAuj.timeInMillis
                    val ecoule = now.timeInMillis - leverAuj.timeInMillis
                    val num = (((ecoule.toDouble() / duree) * 12.0).toInt() + 1)
                        .coerceIn(1, 12)
                    val partie = PARTIES_JOUR[(num - 1) / 3]
                    return Periode(false, "Heure $num", partie)
                }
            }
            // Nuit de la veille : du coucher d'hier au lever d'aujourd'hui.
            val hier = (now.clone() as Calendar)
            hier.add(Calendar.DAY_OF_YEAR, -1)
            val coucherHier = coucherPour(hier)
            if (coucherHier != null && leverAuj != null) {
                val duree = leverAuj.timeInMillis - coucherHier.timeInMillis
                val ecoule = now.timeInMillis - coucherHier.timeInMillis
                val idx = ((ecoule.toDouble() / duree) * 3.0).toInt()
                    .coerceIn(0, 2)
                return Periode(true, VEILLES_NOMS[idx], "Nuit biblique")
            }
            // Région polaire : aucun horaire inventé.
            return Periode(true, "—", "")
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
            val cy = hf * 0.46f
            val R = min(wf, hf) * 0.30f
            val s = (R / RAYON_CANONIQUE).toFloat()

            val now = Calendar.getInstance()
            val periode = periodeBiblique(now)

            val minutes = cycleMinutes(now)

            // ── 1. FOND : GIF animé de l'accueil (jour/nuit) + voile, ou
            //         repli ciel étoilé + halo doré ──
            peindreFond(canvas, wf, hf, periode.nuit, R)

            // ── 2. Date biblique au-dessus du cadran ──
            peindreDate(canvas, wf, hf, R, s)

            // ── 3. Cadran (identique à la page horloge) ──
            peindreCadran(canvas, cx, cy, R, s, periode.nuit, minutes, now)

            // ── 4. Ligne d'informations : heure civile · prochain coucher ·
            //         position (exactement les informations de la page) ──
            peindreInfos(canvas, wf, hf, R, s, now)

            // ── 5. Prochaine alarme ──
            peindreAlarme(canvas, wf, hf, R, s)
        }

        /** Fond plein écran : GIF animé de la phase + voile, ou repli. */
        private fun peindreFond(
            canvas: Canvas,
            wf: Float,
            hf: Float,
            nuit: Boolean,
            R: Float,
        ) {
            val film = if (nuit) filmNuit else filmJour
            if (film != null && film.width() > 0 && film.height() > 0) {
                val duree = if (film.duration() > 0) film.duration() else 1000
                film.setTime(
                    ((System.currentTimeMillis() - filmDebutMs) % duree).toInt()
                )
                // Cover : remplir tout l'écran sans déformer le GIF.
                val echelle = max(wf / film.width(), hf / film.height())
                canvas.drawColor(Color.BLACK)
                canvas.save()
                canvas.translate(
                    (wf - film.width() * echelle) / 2f,
                    (hf - film.height() * echelle) / 2f,
                )
                canvas.scale(echelle, echelle)
                film.draw(canvas, 0f, 0f, pFondImg)
                canvas.restore()
            } else {
                // Repli : ciel céleste + étoiles + halo doré (défaut v1.0.7).
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
            }
            // Voile sombre vertical — lisibilité des textes (comme la carte
            // « Période en cours » de l'accueil).
            pVoile.shader = LinearGradient(
                0f, 0f, 0f, hf,
                intArrayOf(
                    0x660B1226,
                    0x260B1226,
                    0x880B1226,
                ),
                floatArrayOf(0f, 0.45f, 1f),
                Shader.TileMode.CLAMP,
            )
            canvas.drawRect(0f, 0f, wf, hf, pVoile)
        }

        /** Date biblique au-dessus du cadran (instantané) ou date civile. */
        private fun peindreDate(
            canvas: Canvas,
            wf: Float,
            hf: Float,
            R: Float,
            s: Float,
        ) {
            val texte = if (dateBibliqueTxt.isNotEmpty()) {
                dateBibliqueTxt
            } else {
                SimpleDateFormat("EEEE d MMMM yyyy", Locale.FRENCH)
                    .format(System.currentTimeMillis())
                    .replaceFirstChar { it.uppercase(Locale.FRENCH) }
            }
            pDate.textSize = max(R * 0.075f, 13f * s)
            pDate.color = 0xFFF0D68A.toInt()
            pDate.alpha = 235
            val tw = pDate.measureText(texte)
            if (tw > wf - 24f) {
                pDate.textSize *= (wf - 24f) / tw
            }
            canvas.drawText(
                texte, wf / 2f,
                baselineCentre(pDate, hf * 0.075f), pDate,
            )
        }

        /**
         * Minutes écoulées depuis le DERNIER COUCHER RÉEL (0→1440) —
         * arc du cycle biblique ; repli 18 h 00 si calcul polaire
         * indisponible (comme l'app).
         */
        private fun cycleMinutes(now: Calendar): Double {
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

        /**
         * Cadran CIVIL 24 h — MÊME dessin que la page horloge : 00 en haut,
         * 06 à droite, 12 en bas, 18 à gauche ; aiguilles à l'heure civile
         * réelle ; arc du cycle biblique écoulé depuis le dernier coucher.
         */
        private fun peindreCadran(
            canvas: Canvas,
            cx: Float,
            cy: Float,
            R: Float,
            s: Float,
            nuit: Boolean,
            minutes: Double,
            now: Calendar,
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
                pCiel.shader = RadialGradient(
                    cx - R * 0.9f, cy, R * 1.6f,
                    intArrayOf(0xFF31407E.toInt(), 0xFF10163A.toInt()),
                    null, Shader.TileMode.CLAMP,
                )
                canvas.drawArc(rect, 180f, 180f, true, pCiel)
                pCiel.shader = RadialGradient(
                    cx + R * 0.9f, cy, R * 1.6f,
                    intArrayOf(0xFF96C7F0.toInt(), 0xFF78B4E2.toInt()),
                    null, Shader.TileMode.CLAMP,
                )
                canvas.drawArc(rect, 0f, 180f, true, pCiel)
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

            // Chiffres des 24 HEURES CIVILES (00 haut · 06 droite · 12 bas ·
            // 18 gauche), pairs en grands caractères, impairs en petits —
            // 06 et 18 sur PASTILLE SOMBRE (l'effet de lumière du décor
            // rendait ces deux chiffres illisibles — corrigé v1.0.9).
            for (h in 0..23) {
                val angle = h * DEGRES_PAR_HEURE
                val pair = h % 2 == 0
                val marqueur = h == 6 || h == 18
                if (marqueur) {
                    val (px, py) = pos(cx, cy, angle, R - 26f * s)
                    pPastille.color = 0xB30B1226.toInt()
                    canvas.drawCircle(px, py, R * 0.10f, pPastille)
                }
                val demiNuit = angle >= 262.5 || angle < 97.5
                pChiffre.textSize =
                    (R * (if (pair) 0.085f else 0.058f)).coerceAtLeast(8f)
                when {
                    marqueur -> pChiffre.color = 0xFFFFFFFF.toInt()
                    demiNuit -> {
                        pChiffre.color = 0xFFE7D3A1.toInt()
                        pChiffre.alpha = if (pair) 242 else 183
                    }
                    else -> {
                        pChiffre.color = 0xFF1E293B.toInt()
                        pChiffre.alpha = if (pair) 235 else 158
                    }
                }
                val r = R - 26f * s
                val (x, y) = pos(cx, cy, angle, r)
                canvas.drawText(
                    h.toString().padStart(2, '0'), x,
                    baselineCentre(pChiffre, y), pChiffre,
                )
            }

            // Marqueurs solaires : 18 h (coucher — gauche) et 06 h (lever —
            // droite), petits soleils dorés sur le pourtour.
            for (a in doubleArrayOf(270.0, 90.0)) {
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
                180.0f, // 270° − 90° : origine GAUCHE du cadran
                (minutes / 1440.0 * 360.0).toFloat(),
                false,
                pArc,
            )

            // ── Médaillon central : HEURE CIVILE (conforme aux aiguilles et
            // à l'horloge numérique) + période biblique en cours ──
            val rm = R * 0.34f
            pMedaillon.color = if (nuit) 0xCC1E293B.toInt() else 0xCCEFF6FF.toInt()
            canvas.drawCircle(cx, cy, rm, pMedaillon)
            pMedaillonLisere.strokeWidth = 1.6f * s
            pMedaillonLisere.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(cx, cy, rm, pMedaillonLisere)

            val periode = periodeBiblique(now)
            val texteHeure = String.format(
                Locale.US, "%02d h %02d",
                now.get(Calendar.HOUR_OF_DAY),
                now.get(Calendar.MINUTE),
            )

            pTitre.textSize = (R * 0.052f).coerceAtLeast(8f)
            pTitre.letterSpacing = 0.08f
            pTitre.color =
                if (nuit) 0xFFF0D68A.toInt() else 0xFF3B82F6.toInt()
            pTitre.alpha = 217 // 0.85
            canvas.drawText(
                "HEURE CIVILE", cx,
                baselineCentre(pTitre, cy - rm * 0.50f), pTitre,
            )

            pHeureTxt.textSize = (R * 0.105f).coerceAtLeast(13f)
            pHeureTxt.color = 0xFFF0D68A.toInt()
            canvas.drawText(
                texteHeure, cx,
                baselineCentre(pHeureTxt, cy + rm * 0.05f), pHeureTxt,
            )

            pPeriode.textSize = (R * 0.058f).coerceAtLeast(9f)
            if (periode.nuit) {
                pPeriode.color = 0xFFE7D3A1.toInt()
            } else {
                pPeriode.color = 0xFFFFFFFF.toInt()
            }
            pPeriode.alpha = 230
            canvas.drawText(
                periode.libelle, cx,
                baselineCentre(pPeriode, cy + rm * 0.55f), pPeriode,
            )

            // ── AIGUILLES À L'HEURE CIVILE RÉELLE (conformes à l'horloge
            // numérique — aiguille des heures : UN TOUR PAR 24 h) ──
            val fractionSeconde = if (trotteuseFluide) {
                (System.currentTimeMillis() % 1000L) / 1000.0
            } else {
                0.0
            }
            val angleHeures =
                (now.get(Calendar.HOUR_OF_DAY) +
                        now.get(Calendar.MINUTE) / 60.0 +
                        now.get(Calendar.SECOND) / 3600.0) * DEGRES_PAR_HEURE
            val angleMinutes =
                (now.get(Calendar.MINUTE) + now.get(Calendar.SECOND) / 60.0) *
                        DEGRES_PAR_MINUTE
            val angleSecondes =
                (now.get(Calendar.SECOND) + fractionSeconde) *
                        DEGRES_PAR_MINUTE

            val couleurAiguilles =
                if (nuit) 0xFFE7D3A1.toInt() else 0xFF1E293B.toInt()
            aiguille(canvas, cx, cy, angleHeures, R * 0.46f, 7f * s, couleurAiguilles)
            aiguille(canvas, cx, cy, angleMinutes, R * 0.64f, 4.5f * s, couleurAiguilles)
            aiguille(canvas, cx, cy, angleSecondes, R * 0.74f, 2f * s, 0xFFE53935.toInt())

            // Contrepoids de la trotteuse (rouge — même teinte que l'app).
            val aS = angleSecondes * Math.PI / 180.0
            val dxS = Math.sin(aS).toFloat()
            val dyS = (-Math.cos(aS)).toFloat()
            pTrait.strokeWidth = 2f * s
            pTrait.color = 0xFFE53935.toInt()
            canvas.drawLine(cx, cy, cx - dxS * 18f * s, cy - dyS * 18f * s, pTrait)
            pPoint.color = 0xFFE53935.toInt()
            canvas.drawCircle(cx - dxS * 18f * s, cy - dyS * 18f * s, 3.2f * s, pPoint)

            // Moyeu central doré.
            pPoint.color = 0xFFCFA63A.toInt()
            canvas.drawCircle(cx, cy, 6.5f * s, pPoint)
            pPoint.color = 0xFFFFFFFF.toInt()
            canvas.drawCircle(cx, cy, 2.6f * s, pPoint)
        }

        /** Texte « HH h MM » d'un instant civil. */
        private fun heureTxt(c: Calendar): String = String.format(
            Locale.US, "%02d h %02d",
            c.get(Calendar.HOUR_OF_DAY),
            c.get(Calendar.MINUTE),
        )

        /**
         * Ligne d'informations sous le cadran — exactement les informations
         * de la page horloge : heure civile · prochain coucher · position.
         */
        private fun peindreInfos(
            canvas: Canvas,
            wf: Float,
            hf: Float,
            R: Float,
            s: Float,
            now: Calendar,
        ) {
            val prochain = prochainCoucher(now)
            val position = positionLibelle
                .takeIf { it.isNotEmpty() }
                ?.let {
                    if (it.length > 18) it.substring(0, 18) + "…" else it
                } ?: ""
            val texte = buildString {
                append("Heure civile ")
                append(heureTxt(now))
                if (prochain != null) {
                    append("  ·  Prochain coucher ")
                    append(heureTxt(prochain))
                }
                if (position.isNotEmpty()) {
                    append("  ·  ")
                    append(position)
                }
            }

            pInfoTxt.textSize = max(R * 0.058f, 12f * s)
            val tw = pInfoTxt.measureText(texte)
            if (tw > wf - 28f) {
                pInfoTxt.textSize *= (wf - 28f) / tw
            }
            val y = hf * 0.775f
            val marge = pInfoTxt.textSize * 0.85f
            val rect = RectF(
                wf / 2f - pInfoTxt.measureText(texte) / 2f - marge,
                y - pInfoTxt.textSize * 1.05f,
                wf / 2f + pInfoTxt.measureText(texte) / 2f + marge,
                y + pInfoTxt.textSize * 0.55f,
            )
            pPill.color = Color.argb(115, 8, 14, 34)
            canvas.drawRoundRect(rect, rect.height() / 2f, rect.height() / 2f, pPill)
            pInfoTxt.color = 0xFFF5F0E6.toInt()
            canvas.drawText(texte, wf / 2f, baselineCentre(pInfoTxt, y), pInfoTxt)
        }

        private fun peindreAlarme(
            canvas: Canvas,
            wf: Float,
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
            val texte =
                "Prochaine alarme · ${alarme.libelle} · ${heureTxt(instant)} · $delta"

            pAlarmeTxt.textSize = max(R * 0.05f, 11f * s)
            val tw = pAlarmeTxt.measureText(texte)
            val marge = pAlarmeTxt.textSize * 0.85f
            val y = hf * 0.875f
            val rect = RectF(
                wf / 2f - tw / 2f - marge,
                y - pAlarmeTxt.textSize * 1.05f,
                wf / 2f + tw / 2f + marge,
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
            pAlarmeTxt.textAlign = Paint.Align.CENTER
            canvas.drawText(texte, wf / 2f, baselineCentre(pAlarmeTxt, y), pAlarmeTxt)
        }
    }
}
