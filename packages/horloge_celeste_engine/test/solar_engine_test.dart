/// ⭐ TESTS DU MOTEUR SOLAIRE (§15.1) — comparés aux couchers de soleil
/// RÉELS calculés par le backend pour Jérusalem (données golden des
/// événements shofar), puis aux propriétés astronomiques attendues.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

/// Jérusalem — coordonnées du backend (31.7683 N, 35.2137 E).
const latJerusalem = 31.7683;
const lonJerusalem = 35.2137;

void main() {
  group('Couchers de soleil Jérusalem — parité avec le backend', () {
    // Le backend calcule l'entrée/sortie des événements shofar au coucher
    // du soleil RÉEL de Jérusalem : ces instants servent de référence.
    test('les couchers du backend suivent la même réalité saisonnière', () {
      final data = jsonDecode(
          File('test/golden/evenements-full.json').readAsStringSync())
          as Map<String, dynamic>;
      final evenements =
          (data['evenements'] as List).cast<Map<String, dynamic>>();
      expect(evenements, isNotEmpty);

      var comparees = 0;
      var maxEcartMinutes = 0.0;
      final ecarts = <double>[];
      for (final e in evenements) {
        final entree = DateTime.parse(e['entree'] as String);
        final dateEntree = DateTime(entree.year, entree.month, entree.day);
        final solar = SolarEngine.calculer(
            dateEntree, latJerusalem, lonJerusalem);
        expect(solar.calculable, isTrue, reason: 'Jérusalem : calculable');
        // Comparaison en UTC (les golden sont des instants UTC)
        final calculeUTC = solar.coucher!.toUtc();
        final ecartMin =
            (calculeUTC.difference(entree).inMilliseconds.abs() / 60000.0);
        ecarts.add(ecartMin);
        maxEcartMinutes = ecarts.reduce((a, b) => a > b ? a : b);
        comparees++;
      }
      // REMARQUE D'AUDIT (mise à jour 27/11/2026) : l'ancien écart de
      // ~39 min venait du MOTEUR (équation du temps avec y = tan au lieu
      // de y = tan²(ε₀/2), bug corrigé). Après correction, l'écart
      // moteur ↔ backend est max ~2 min (moyenne 0,5 min) sur les golden.
      expect(maxEcartMinutes, lessThan(5.0),
          reason:
              'écart max constaté : $maxEcartMinutes min sur $comparees événements '
              '(parité backend après correction EqT)');
    });
  });

  group('Précision absolue (régression EqT — y = tan²(ε/2) NOAA)', () {
    // Régression : l'équation du temps exige y = tan²(ε₀/2). Avec un simple
    // tan(ε₀/2), les couchers étaient décalés de ~±25-35 min selon la
    // saison (ex. Cotonou 27/11 : 17:58 au lieu de 18:31 publié).
    test('Cotonou 27/11/2026 — coucher = 18:31-18:32 locales (publié 18:31)',
        () {
      final solar = SolarEngine.calculer(DateTime(2026, 11, 27), 6.3654, 2.4183);
      expect(solar.calculable, isTrue);
      final coucher = solar.coucher!;
      expect(coucher.hour * 60 + coucher.minute,
          inInclusiveRange(18 * 60 + 29, 18 * 60 + 33),
          reason: 'timeanddate publie 18:31 pour Cotonou le 27/11/2026');
    });

    test('Jérusalem 27/11/2026 — coucher ≈ 16:35-16:37 locales', () {
      final solar =
          SolarEngine.calculer(DateTime(2026, 11, 27), latJerusalem, lonJerusalem);
      expect(solar.calculable, isTrue);
      final coucher = solar.coucher!;
      expect(coucher.hour * 60 + coucher.minute,
          inInclusiveRange(16 * 60 + 33, 16 * 60 + 39),
          reason: 'référence NOAA pleine précision : 16:35-16:36 locales');
    });

    test('équation du temps : ancrage NOAA (jan ≈ −3 min, nov ≈ +12 min)', () {
      // Sans accès public à EqT, on la retrouve par différence : le midi
      // solaire local = 12:00 + (4·lon + EqT − tz)/60... ancrage indirect
      // via le midi solaire de Cotonou (lon 2.4183, UTC+1) :
      // 27/11 : EqT ≈ +12,6 min → midi solaire ≈ 12:40 locales.
      final solar = SolarEngine.calculer(DateTime(2026, 11, 27), 6.3654, 2.4183);
      // Midi solaire = moyenne de lever et coucher (symétrie de la formule).
      final leverMin = solar.lever!.hour * 60 + solar.lever!.minute;
      final coucherMin = solar.coucher!.hour * 60 + solar.coucher!.minute;
      final midiMinutes = ((leverMin + coucherMin) / 2).round();
      expect(midiMinutes, inInclusiveRange(12 * 60 + 34, 12 * 60 + 42),
          reason: 'EqT +12-13 min ⇒ midi solaire local ≈ 12:38 (UTC+1, lon 2.42°)');
    });
  });

  group('Propriétés astronomiques (§15.1)', () {
    test('Cotonou (6.37N, 2.42E) — jour tropical ≈ 12 h ± 1 h à l\u2019équinoxe',
        () {
      final solar = SolarEngine.calculer(DateTime(2026, 3, 20), 6.37, 2.42);
      expect(solar.calculable, isTrue);
      final duree = solar.coucher!.difference(solar.lever!);
      expect(duree.inMinutes, inInclusiveRange(12 * 60 - 60, 12 * 60 + 60));
      // Le jour dure moins de 24 h et le lever précède le coucher.
      expect(solar.lever!.isBefore(solar.coucher!), isTrue);
    });

    test('La durée du jour CHANGE avec les saisons (Paris)', () {
      // Équinoxe (mars) vs solstice d'été à Paris (48.85 N, 2.35 E).
      final equinoxe =
          SolarEngine.calculer(DateTime(2026, 3, 20), 48.85, 2.35);
      final solstice =
          SolarEngine.calculer(DateTime(2026, 6, 21), 48.85, 2.35);
      final hiver = SolarEngine.calculer(DateTime(2026, 12, 21), 48.85, 2.35);

      final dureeEquinoxe = equinoxe.coucher!.difference(equinoxe.lever!);
      final dureeSolstice = solstice.coucher!.difference(solstice.lever!);
      final dureeHiver = hiver.coucher!.difference(hiver.lever!);

      expect(dureeSolstice.inMinutes, greaterThan(dureeEquinoxe.inMinutes + 60),
          reason: 'le jour d\u2019été est plus long que l\u2019équinoxe à Paris');
      expect(dureeEquinoxe.inMinutes, greaterThan(dureeHiver.inMinutes + 60),
          reason: 'l\u2019équinoxe est plus long que le solstice d\u2019hiver');
      expect(dureeHiver.inMinutes, lessThan(9 * 60),
          reason: 'Paris, 21 décembre : jour < 9 h');
      expect(dureeSolstice.inMinutes, greaterThan(15 * 60),
          reason: 'Paris, 21 juin : jour > 15 h');
    });

    test('Hémisphère sud inversé : Johannesburg plus long en décembre',
        () {
      final decembre =
          SolarEngine.calculer(DateTime(2026, 12, 21), -26.2, 28.05);
      final juin = SolarEngine.calculer(DateTime(2026, 6, 21), -26.2, 28.05);
      expect(
        decembre.coucher!.difference(decembre.lever!).inMinutes,
        greaterThan(juin.coucher!.difference(juin.lever!).inMinutes),
      );
    });

    test('région polaire : Longyearbyen 78.2 N, 21 décembre → NON calculable',
        () {
      final solar =
          SolarEngine.calculer(DateTime(2026, 12, 21), 78.22, 15.65);
      expect(solar.calculable, isFalse,
          reason: 'nuit polaire : aucun lever/coucher à ne PAS inventer');
      expect(solar.lever, isNull);
      expect(solar.coucher, isNull);
    });

    test('région polaire : Longyearbyen 21 juin → jour polaire', () {
      final solar = SolarEngine.calculer(DateTime(2026, 6, 21), 78.22, 15.65);
      expect(solar.calculable, isFalse,
          reason: 'soleil de minuit : aucun lever/coucher à ne PAS inventer');
    });

    test('série de journées consécutives pour l\u2019adapter', () {
      final serie = SolarEngine.serie(DateTime(2026, 11, 27), 6.37, 2.42,
          jours: 3);
      expect(serie.length, 3);
      for (final s in serie) {
        expect(s.calculable, isTrue);
      }
      // Les couchers progressent d\u2019environ 24 h (± 5 min équation du temps)
      for (var i = 1; i < serie.length; i++) {
        final ecart =
            serie[i].coucher!.difference(serie[i - 1].coucher!).inMinutes;
        expect(ecart, inInclusiveRange(24 * 60 - 5, 24 * 60 + 5));
      }
    });
  });
}
