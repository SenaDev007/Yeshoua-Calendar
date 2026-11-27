/// ⭐ TESTS DU SHOFAR — planification des entrées de Shabbat et des fêtes
/// de l'Éternel + rappels J-7 / J-3 / J-24 h (AlarmPlanner.planifierShofar).
library;

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

EvenementShofar _shabbat(DateTime entree, DateTime sortie) => EvenementShofar(
      id: 'shabbat-${entree.day}',
      type: 'shabbat',
      titre: 'Shabbat',
      dateGregorienne: sortie,
      entree: entree,
      sortie: sortie,
      reference: 'Lévitique 23:3',
      travailInterdit: true,
    );

EvenementShofar _fete(String id, String nom, DateTime entree, DateTime sortie) {
  final jalons = [
    JalonJalons(cle: 'j7', date: entree.subtract(const Duration(days: 7)), label: '7 jours'),
    JalonJalons(cle: 'j3', date: entree.subtract(const Duration(days: 3)), label: '3 jours'),
    JalonJalons(cle: 'j24h', date: entree.subtract(const Duration(hours: 24)), label: '24 heures'),
  ];
  return EvenementShofar(
    id: id,
    type: 'fete',
    titre: nom,
    dateGregorienne: sortie,
    entree: entree,
    sortie: sortie,
    jalons: jalons,
  );
}

void main() {
  final maintenant = DateTime(2026, 11, 20, 12, 0);

  group('planifierShofar — entrées (Shabbat et fêtes)', () {
    test('le shofar sonne à l\'ENTRÉE de chaque Shabbat (coucher réel)', () {
      final veille = DateTime(2026, 11, 20, 17, 30); // vendredi soir
      final soir = DateTime(2026, 11, 21, 17, 31);
      final plan = AlarmPlanner.planifierShofar(
        evenements: [_shabbat(veille, soir)],
        maintenant: maintenant,
      );
      expect(plan.length, 1);
      expect(plan.first.instant, veille);
      expect(plan.first.payload, 'shofar_shabbat');
      expect(plan.first.son, 'shofar');
      expect(plan.first.id, AlarmPlanner.idShofarBase);
      expect(plan.first.titre, contains('Shabbat'));
    });

    test('les événements déjà passés sont omis (pas de sonnerie rétroactive)',
        () {
      final passe = DateTime(2026, 11, 19, 17, 30);
      final plan = AlarmPlanner.planifierShofar(
        evenements: [_shabbat(passe, passe.add(const Duration(days: 1)))],
        maintenant: maintenant,
      );
      expect(plan, isEmpty);
    });

    test('entrée de fête : payload shofar_fete et titre de la fête', () {
      final entree = DateTime(2026, 12, 9, 17, 20);
      final plan = AlarmPlanner.planifierShofar(
        evenements: [_fete('hanouka', 'Hanoukka', entree, entree.add(const Duration(days: 7)))],
        maintenant: maintenant,
      );
      final entrees = plan.where((p) => p.payload == 'shofar_fete').toList();
      expect(entrees.length, 1);
      expect(entrees.first.instant, entree);
      expect(entrees.first.titre, contains('Hanoukka'));
    });
  });

  group('planifierShofar — rappels J-7 / J-3 / J-24 h des fêtes', () {
    test('les trois jalons futurs sont planifiés au shofar', () {
      final entree = DateTime(2026, 12, 9, 17, 20);
      final plan = AlarmPlanner.planifierShofar(
        evenements: [_fete('fete-x', 'Fête des Tabernacles', entree, entree)],
        maintenant: maintenant,
      );
      final rappels = plan.where((p) => p.payload.startsWith('rappel_')).toList();
      expect(rappels.length, 3);
      final cles = rappels.map((r) => r.payload).toSet();
      expect(cles, {'rappel_j7', 'rappel_j3', 'rappel_j24h'});
      for (final r in rappels) {
        expect(r.son, 'shofar');
        expect(r.instant.isAfter(maintenant), isTrue);
      }
      // J-7 = entrée − 7 jours exactement (instant de coucher décalé).
      final j7 = rappels.firstWhere((r) => r.payload == 'rappel_j7');
      expect(j7.instant, entree.subtract(const Duration(days: 7)));
      // Les identifiants des rappels démarrent à idRappelsBase.
      expect(rappels.every((r) => r.id >= AlarmPlanner.idRappelsBase), isTrue);
    });

    test('les jalons déjà passés sont omis, les futurs conservés', () {
      // Entrée dans 4 jours : J-7 et J-3 passés, J-24 h futur.
      final entree = maintenant.add(const Duration(days: 4));
      final plan = AlarmPlanner.planifierShofar(
        evenements: [_fete('fete-y', 'Pessah', entree, entree)],
        maintenant: maintenant,
      );
      final rappels = plan
          .where((p) => p.payload.startsWith('rappel_'))
          .map((p) => p.payload)
          .toSet();
      expect(rappels, {'rappel_j24h'});
      // Et l'entrée reste planifiée.
      expect(plan.where((p) => p.payload == 'shofar_fete').length, 1);
    });

    test('les Shabbats n\'ont PAS de rappels J-7/J-3/J-24 h', () {
      final veille = DateTime(2026, 11, 27, 17, 30);
      final plan = AlarmPlanner.planifierShofar(
        evenements: [_shabbat(veille, veille.add(const Duration(days: 1)))],
        maintenant: maintenant,
      );
      expect(plan.where((p) => p.payload.startsWith('rappel_')), isEmpty);
    });

    test('plusieurs événements triés par instant croissant', () {
      final plan = AlarmPlanner.planifierShofar(
        evenements: [
          _fete('f1', 'Fête A', DateTime(2026, 12, 9, 17, 20), DateTime(2026, 12, 9, 17, 20)),
          _shabbat(DateTime(2026, 11, 27, 17, 30), DateTime(2026, 11, 28, 17, 31)),
          _fete('f2', 'Fête B', DateTime(2026, 11, 30, 17, 25), DateTime(2026, 11, 30, 17, 25)),
        ],
        maintenant: maintenant,
      );
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].instant.isAfter(plan[i - 1].instant) ||
            plan[i].instant == plan[i - 1].instant, isTrue);
      }
    });
  });
}
