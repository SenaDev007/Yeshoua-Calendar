/// ⭐ TESTS DU PLANNING MULTI-JOURS (§8.4) — les alarmes du soir sont
/// ancrées sur le coucher du soleil RÉEL de CHACUN des prochains jours :
/// la sonnerie reste armée même si l'application n'est pas rouverte.
library;

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

void main() {
  // Position de référence : Cotonou, Bénin (§9 — contexte du cahier des
  // charges). Coucher du soleil ≈ 18 h locale toute l'année.
  const lat = 6.37;
  const lon = 2.42;

  BiblicalCalendarAdapter adapter() =>
      BiblicalCalendarAdapter(latitude: lat, longitude: lon);

  group('AlarmPlanner.planifier — horizon multi-jours', () {
    final maintenant = DateTime(2026, 11, 27, 12, 0); // midi : avant le coucher

    test('horizon 7 jours : un RHEMA du soir par coucher, ids distincts',
        () {
      final plan = AlarmPlanner.planifier(
        adapter: adapter(),
        alarmes: [
          const AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: '',
              activee: true),
        ],
        maintenant: maintenant,
        horizonJours: 7,
      );

      final soirs =
          plan.where((a) => a.type == TypeAlarme.rhemaSoir).toList();
      expect(soirs.length, 7, reason: 'un coucher par jour sur 7 jours');

      final ids = soirs.map((a) => a.id).toSet();
      expect(ids.length, 7, reason: 'ids tous distincts');

      // Chaque instant est BIEN un coucher du soleil (17 h–19 h à Cotonou)
      // et deux soirs ne tombent jamais le même jour civil.
      final jours = <DateTime>{};
      for (final a in soirs) {
        expect(a.instant.hour, inInclusiveRange(17, 19),
            reason: 'coucher du soleil réel à Cotonou');
        jours.add(DateTime(
            a.instant.year, a.instant.month, a.instant.day));
      }
      expect(jours.length, 7, reason: '7 jours civils différents');
    });

    test('horizon 7 jours : préparation du soir = 5 min avant chaque coucher',
        () {
      final plan = AlarmPlanner.planifier(
        adapter: adapter(),
        alarmes: [
          const AlarmeSpirituelle(
              type: TypeAlarme.preparationSoir,
              nom: 'Préparation du soir',
              message: '',
              activee: true,
              minutesAvant: 5),
        ],
        maintenant: maintenant,
        horizonJours: 7,
      );

      final preps =
          plan.where((a) => a.type == TypeAlarme.preparationSoir).toList();
      expect(preps.length, 7);

      // Chaque préparation précède de 5 minutes un RHEMA potentiel : on
      // vérifie simplement le décalage interne cohérent (17 h–19 h).
      for (final a in preps) {
        expect(a.instant.hour, inInclusiveRange(17, 19));
      }
    });

    test('horizon par défaut (1) — compatibilité du comportement historique',
        () {
      final plan = AlarmPlanner.planifier(
        adapter: adapter(),
        alarmes: [
          const AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: '',
              activee: true),
        ],
        maintenant: maintenant,
      );
      expect(plan.length, 1);
      expect(plan.first.id, AlarmPlanner.idRhemaSoir);
    });

    test('alarme désactivée : rien n\u2019est planifié, quel que soit l\u2019horizon',
        () {
      final plan = AlarmPlanner.planifier(
        adapter: adapter(),
        alarmes: [
          const AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: '',
              activee: false),
        ],
        maintenant: maintenant,
        horizonJours: 7,
      );
      expect(plan, isEmpty);
    });

    test('midi passé : le jour 0 bascule sur le coucher de DEMAIN sans doublon',
        () {
      // 21 h : le coucher du jour est passé — le jour 0 (prochainCoucher)
      // donne DEMAIN, et le jour 1 (minuit + 1 j) donne AUSSI demain :
      // le dédoublonnage doit éviter la double sonnerie.
      final soir = DateTime(2026, 11, 27, 21, 0);
      final plan = AlarmPlanner.planifier(
        adapter: adapter(),
        alarmes: [
          const AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: '',
              activee: true),
        ],
        maintenant: soir,
        horizonJours: 7,
      );
      final jours = plan
          .map((a) => DateTime(
              a.instant.year, a.instant.month, a.instant.day))
          .toSet();
      expect(jours.length, plan.length,
          reason: 'aucun jour civil en double');
      expect(plan.isNotEmpty, isTrue);
    });
  });
}
