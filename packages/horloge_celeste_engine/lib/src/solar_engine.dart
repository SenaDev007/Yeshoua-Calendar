/// ⭐ SOLAR ENGINE — PHASE 3 du cahier des charges Horloge Céleste.
///
/// Calcul astronomique EMBARQUÉ (aucune connexion Internet, §9.3) :
/// lever et coucher du soleil selon l'algorithme NOAA (U.S. Naval
/// Observatory, précision typique ±1-2 minutes aux latitudes habituelles).
///
/// Cas particuliers gérés (§9.4) :
///   • jour polaire / nuit polaire → `SolarTimes.calculable == false`,
///     l'app affiche l'indisponibilité — JAMAIS d'horaire inventé ;
///   • altitude du disque solaire −0,833° (réfraction atmosphérique
///     standard + rayon du disque), la convention du NOAA.
library;

import 'dart:math' as math;

import 'models.dart';

class SolarEngine {
  SolarEngine._();

  /// Hauteur standard du centre du soleil pour lever/coucher (degrés).
  static const double _zenithDeg = 90.833;

  /// Calcule les horaires solaires du jour local [date] (une date locale
  /// quelconque de la journée, par ex. DateTime.now()).
  ///
  /// Le décalage horaire utilisé est celui de l'heure locale du téléphone
  /// au moment du calcul ; l'englobage « lever/coucher du même jour
  /// civil local » est garanti.
  static SolarTimes calculer(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    final tzOffsetMinutes = date.timeZoneOffset.inMinutes;
    final utcDate = DateTime.utc(date.year, date.month, date.day);

    final julianDay = _julianDay(utcDate);
    final julianCenturies = (julianDay - 2451545.0) / 36525.0;

    final declination = _declinationSolaire(julianCenturies);
    final equationDuTempsMinutes = _equationDuTemps(julianCenturies);

    // Midi solaire vrai en minutes après MINUIT LOCAL (formule NOAA).
    final midiSolaireMinutes =
        720.0 - 4.0 * longitude - equationDuTempsMinutes + tzOffsetMinutes;

    final decRad = _rad(declination);
    final latRad = _rad(latitude);

    // cos(H) = cos(zénith) / (cos(lat)·cos(décl)) − tan(lat)·tan(décl)
    // (forme NOAA, identique à (cos z − sin lat·sin dec)/(cos lat·cos dec))
    final cosH = (_cos(_rad(_zenithDeg)) / (_cos(latRad) * _cos(decRad))) -
        _tan(latRad) * _tan(decRad);

    // |cosH| > 1 → soleil qui ne se lève pas / ne se couche pas (polaire).
    if (cosH < -1.0 || cosH > 1.0) {
      return SolarTimes(
        latitude: latitude,
        longitude: longitude,
      );
    }

    final angleHoraireDeg = _deg(_acos(cosH));

    final leverMinutes = midiSolaireMinutes - 4.0 * angleHoraireDeg;
    final coucherMinutes = midiSolaireMinutes + 4.0 * angleHoraireDeg;

    // Ancrage sur le MINUIT LOCAL du jour civil demandé.
    final minuitLocal = DateTime(date.year, date.month, date.day);
    final lever = minuitLocal.add(Duration(minutes: leverMinutes.round()));
    final coucher =
        minuitLocal.add(Duration(minutes: coucherMinutes.round()));

    return SolarTimes(
      lever: lever,
      coucher: coucher,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Lever / coucher pour JUSQU'À [jours] journées consécutives à partir
  /// de [date] (utile pour l'adapter et pour préparer les alarmes).
  static List<SolarTimes> serie(DateTime date, double lat, double lon,
      {int jours = 3}) {
    return [
      for (var i = 0; i < jours; i++)
        calculer(date.add(Duration(days: i)), lat, lon),
    ];
  }

  // ── Mathématiques solaires (NOAA) ──────────────────────────────────

  /// Jour julien (fraction inclus) pour une date UTC à 00 h.
  static double _julianDay(DateTime utcDate) {
    final y = utcDate.year;
    final m = utcDate.month;
    final d = utcDate.day;
    final a = (14 - m) ~/ 12;
    final y2 = y + 4800 - a;
    final m2 = m + 12 * a - 3;
    // Grégorien
    final jdn = d + (153 * m2 + 2) ~/ 5 + 365 * y2 + y2 ~/ 4 - y2 ~/ 100 + y2 ~/ 400 - 32045;
    return jdn - 0.5;
  }

  /// Déclinaison solaire en degrés.
  static double _declinationSolaire(double t) {
    // Longitude géométrique moyenne (degrés)
    final l0 = _normaliserDegres(
        280.46646 + t * (36000.76983 + t * 0.0003032));
    // Anomalie moyenne (degrés)
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    // Équation du centre
    final c = _sin(_rad(m)) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        _sin(_rad(2 * m)) * (0.019993 - 0.000101 * t) +
        _sin(_rad(3 * m)) * 0.000289;
    // Longitude vraie
    final longitudeVraie = l0 + c;
    // Longitude apparente (correction aberration + nutation)
    final longitudeApparente = longitudeVraie -
        0.00569 -
        0.00478 * _sin(_rad(125.04 - 1934.136 * t));
    // Obliquité moyenne corrigée
    final secondes =
        21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
    final obliquite0 = 23.0 + (26.0 + secondes / 60.0) / 60.0;
    final obliquite = obliquite0 +
        0.00256 * _cos(_rad(125.04 - 1934.136 * t));

    // sin(déclinaison) = sin(obliquité) × sin(longitude apparente)
    final sinDec =
        _sin(_rad(obliquite)) * _sin(_rad(longitudeApparente));
    return _deg(_asin(sinDec));
  }

  /// Équation du temps en minutes.
  static double _equationDuTemps(double t) {
    final l0 = _normaliserDegres(
        280.46646 + t * (36000.76983 + t * 0.0003032));
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

    final secondes = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
    final obliquite0 = 23.0 + (26.0 + secondes / 60.0) / 60.0;
    final obliquite = obliquite0 +
        0.00256 * _cos(_rad(125.04 - 1934.136 * t));

    final yTan = _tan(_rad(obliquite / 2.0));
    // Convention NOAA : y = tan²(ε₀/2) — le CARRÉ de la tangente.
    // (Un simple tan(ε/2) fausse l'équation du temps de ~±25-35 min
    // selon la saison, donc les couchers du soleil avec.)
    final y = yTan * yTan;
    final yCarre = y * y;

    final l0Rad = _rad(l0);
    final mRad = _rad(m);

    final eotMinutes = 4.0 * _deg(
        y * _sin(2.0 * l0Rad) -
            2.0 * e * _sin(mRad) +
            4.0 * e * y * _sin(mRad) * _cos(2.0 * l0Rad) -
            0.5 * yCarre * _sin(4.0 * l0Rad) -
            1.25 * e * e * _sin(2.0 * mRad));
    return eotMinutes;
  }

  // ── Aides trigonométriques ──
  static double _rad(double d) => d * math.pi / 180.0;
  static double _deg(double r) => r * 180.0 / math.pi;
  static double _sin(double r) => math.sin(r);
  static double _cos(double r) => math.cos(r);
  static double _tan(double r) => math.tan(r);
  static double _asin(double v) => math.asin(v.clamp(-1.0, 1.0));
  static double _acos(double v) => math.acos(v.clamp(-1.0, 1.0));
  static double _normaliserDegres(double d) {
    var v = d % 360.0;
    if (v < 0) v += 360.0;
    return v;
  }
}
