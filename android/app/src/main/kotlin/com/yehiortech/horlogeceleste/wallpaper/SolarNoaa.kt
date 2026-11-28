package com.yehiortech.horlogeceleste.wallpaper

import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tan

/**
 * ⭐ SOLAR NOAA — port fidèle de `packages/horloge_celeste_engine/
 * solar_engine.dart` vers Kotlin pour le service de fond d'écran animé
 * (le wallpaper tourne HORS du moteur Flutter : il doit recalculer le
 * coucher du soleil lui-même, sans connexion, même algorithme).
 *
 * Algorithme NOAA (U.S. Naval Observatory), hauteur standard du disque
 * −0,833° (réfraction + rayon apparent) — précision ±1-2 minutes.
 */
object SolarNoaa {

    /// Hauteur standard du centre du soleil pour le coucher (degrés).
    private const val ZENITH_DEG = 90.833

    /**
     * Coucher du soleil du jour civil [annee]/[mois]/[jour] local,
     * en MINUTES APRÈS LE MINUIT LOCAL de ce jour. Null : jour polaire
     * (le soleil ne se couche pas / ne se lève pas) — JAMAIS d'horaire
     * inventé, même convention que le moteur Dart.
     *
     * [decTzMinutes] : décalage horaire total (heure d'été incluse) du
     * fuseau au moment considéré, en minutes.
     */
    fun coucherMinutes(
        annee: Int,
        mois: Int,
        jour: Int,
        latitude: Double,
        longitude: Double,
        decTzMinutes: Int,
    ): Double? = solaireMinutes(annee, mois, jour, latitude, longitude, decTzMinutes, lever = false)

    /**
     * Lever du soleil du jour civil local, en MINUTES APRÈS LE MINUIT
     * LOCAL de ce jour. Null : jour polaire — même convention.
     */
    fun leverMinutes(
        annee: Int,
        mois: Int,
        jour: Int,
        latitude: Double,
        longitude: Double,
        decTzMinutes: Int,
    ): Double? = solaireMinutes(annee, mois, jour, latitude, longitude, decTzMinutes, lever = true)

    /**
     * Calcul NOAA partagé : midi solaire ± angle horaire (+ coucher,
     * − lever). [lever] choisit le signe du demi-arc diurne.
     */
    private fun solaireMinutes(
        annee: Int,
        mois: Int,
        jour: Int,
        latitude: Double,
        longitude: Double,
        decTzMinutes: Int,
        lever: Boolean,
    ): Double? {
        val julianDay = jourJulien(annee, mois, jour)
        val t = (julianDay - 2451545.0) / 36525.0

        val declination = declinationSolaire(t)
        val equationDuTempsMinutes = equationDuTemps(t)

        // Midi solaire vrai en minutes après MINUIT LOCAL (formule NOAA).
        val midiSolaireMinutes =
            720.0 - 4.0 * longitude - equationDuTempsMinutes + decTzMinutes

        val decRad = rad(declination)
        val latRad = rad(latitude)

        // cos(H) = cos(zénith) / (cos(lat)·cos(décl)) − tan(lat)·tan(décl)
        val cosH = cos(rad(ZENITH_DEG)) / (cos(latRad) * cos(decRad)) -
                tan(latRad) * tan(decRad)

        // |cosH| > 1 → polaire : pas de lever/coucher calculable ce jour.
        if (cosH < -1.0 || cosH > 1.0) return null

        val angleHoraireDeg = deg(acos(cosH.coerceIn(-1.0, 1.0)))
        val demiArc = 4.0 * angleHoraireDeg
        return if (lever) midiSolaireMinutes - demiArc
        else midiSolaireMinutes + demiArc
    }

    // ── Mathématiques solaires (NOAA — identiques au moteur Dart) ─────

    /** Jour julien d'une date civile grégorienne à 00 h UTC. */
    private fun jourJulien(annee: Int, mois: Int, jour: Int): Double {
        val a = (14 - mois) / 12
        val y2 = annee + 4800 - a
        val m2 = mois + 12 * a - 3
        val jdn = jour + (153 * m2 + 2) / 5 + 365 * y2 + y2 / 4 -
                y2 / 100 + y2 / 400 - 32045
        return jdn - 0.5
    }

    /** Déclinaison solaire en degrés. */
    private fun declinationSolaire(t: Double): Double {
        val l0 = normaliserDegres(280.46646 + t * (36000.76983 + t * 0.0003032))
        val m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        val c = sin(rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
                sin(rad(2 * m)) * (0.019993 - 0.000101 * t) +
                sin(rad(3 * m)) * 0.000289
        val longitudeVraie = l0 + c
        val longitudeApparente = longitudeVraie -
                0.00569 -
                0.00478 * sin(rad(125.04 - 1934.136 * t))
        val secondes = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))
        val obliquite0 = 23.0 + (26.0 + secondes / 60.0) / 60.0
        val obliquite = obliquite0 +
                0.00256 * cos(rad(125.04 - 1934.136 * t))
        val sinDec = sin(rad(obliquite)) * sin(rad(longitudeApparente))
        return deg(asin(sinDec.coerceIn(-1.0, 1.0)))
    }

    /** Équation du temps en minutes (y = tan²(ε₀/2) — convention NOAA). */
    private fun equationDuTemps(t: Double): Double {
        val l0 = normaliserDegres(280.46646 + t * (36000.76983 + t * 0.0003032))
        val m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        val e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        val secondes = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))
        val obliquite0 = 23.0 + (26.0 + secondes / 60.0) / 60.0
        val obliquite = obliquite0 +
                0.00256 * cos(rad(125.04 - 1934.136 * t))

        val yTan = tan(rad(obliquite / 2.0))
        val y = yTan * yTan
        val yCarre = y * y

        val l0Rad = rad(l0)
        val mRad = rad(m)

        val eotMinutes = 4.0 * deg(
            y * sin(2.0 * l0Rad) -
                    2.0 * e * sin(mRad) +
                    4.0 * e * y * sin(mRad) * cos(2.0 * l0Rad) -
                    0.5 * yCarre * sin(4.0 * l0Rad) -
                    1.25 * e * e * sin(2.0 * mRad)
        )
        return eotMinutes
    }

    // ── Aides ──
    private fun rad(d: Double) = d * Math.PI / 180.0
    private fun deg(r: Double) = r * 180.0 / Math.PI
    private fun normaliserDegres(d: Double): Double {
        var v = d % 360.0
        if (v < 0) v += 360.0
        return v
    }
}
