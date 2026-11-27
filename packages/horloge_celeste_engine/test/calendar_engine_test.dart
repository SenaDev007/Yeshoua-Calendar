/// ⭐ TESTS STRUCTURELS DU CALENDRIER 364 JOURS (§15.4, §16).
library;

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

void main() {
  final annee = BiblicalCalendarEngine.construireAnnee(2026);

  group('Structure de l\u2019année', () {
    test('exactement 364 jours = 52 semaines', () {
      expect(annee.jours.length, 364);
      expect(annee.jours.length / 7, 52);
    });

    test('l\u2019année commence un mercredi (création des luminaires)', () {
      expect(annee.debut.weekday, DateTime.wednesday);
      expect(annee.jours.first.jourDuMois, 1);
      expect(annee.jours.first.mois, 1);
      expect(annee.jours.first.nomMois, 'Aviv');
    });

    test('longueurs des mois = [30,30,31,30,30,31,30,30,31,30,30,31]', () {
      for (var m = 1; m <= 12; m++) {
        final jours = annee.jours.where((j) => j.mois == m).length;
        expect(jours, BiblicalCalendarEngine.longueursMois[m - 1],
            reason: 'mois ${BiblicalCalendarEngine.nomsMois[m - 1]}');
      }
      expect(BiblicalCalendarEngine.longueursMois.fold<int>(0, (a, b) => a + b),
          364);
    });

    test('52 Shabbats, tous le 7ᵉ jour de semaine (Samedi civil)', () {
      final shabbats = annee.jours.where((j) => j.estShabbat).toList();
      expect(shabbats.length, 52);
      for (final s in shabbats) {
        expect(s.jourDeSemaine, 7);
        expect(s.nomJourSemaine, 'Samedi');
      }
      // Premier Shabbat = jour de l'année 4 (1er Aviv = mercredi).
      expect(shabbats.first.jourDeAnnee, 4);
      // Pas de discontinuité : un Shabbat tous les 7 jours.
      for (var i = 1; i < shabbats.length; i++) {
        expect(shabbats[i].jourDeAnnee - shabbats[i - 1].jourDeAnnee, 7);
      }
    });

    test('les jours de semaine se suivent sans rupture (364 = 52×7)', () {
      for (var i = 1; i < annee.jours.length; i++) {
        expect(
          annee.jours[i].jourDeSemaine,
          (annee.jours[i - 1].jourDeSemaine % 7) + 1,
        );
      }
    });

    test('trimestres/saisons : 1-3 Printemps, 4-6 Été, 7-9 Automne, 10-12 Hiver',
        () {
      for (final j in annee.jours) {
        expect(j.trimestre, ((j.mois - 1) ~/ 3) + 1);
      }
      expect(BiblicalCalendarEngine.nomsSaisons, [
        'Printemps', 'Été', 'Automne', 'Hiver',
      ]);
    });

    test('continuité entre années consécutives (364 jours exacts)', () {
      final a = BiblicalCalendarEngine.construireAnnee(2025);
      final b = BiblicalCalendarEngine.construireAnnee(2026);
      final finA = a.debut.add(const Duration(days: 363));
      expect(DateTime(b.debut.year, b.debut.month, b.debut.day),
          finA.add(const Duration(days: 1)));
    });

    test('semaine intercalaire : l\u2019écart 2027→2028 fait 8 jours', () {
      final a = BiblicalCalendarEngine.construireAnnee(2027);
      final b = BiblicalCalendarEngine.construireAnnee(2028);
      final finA = a.debut.add(const Duration(days: 363));
      final ecart = DateTime(b.debut.year, b.debut.month, b.debut.day)
          .difference(finA)
          .inDays;
      expect(ecart, 8, reason: '7 jours intercalaires + 1 jour de continuité');
    });
  });

  group('Fêtes de l\u2019Éternel', () {
    test('10 fêtes aux dates bibliques fixes', () {
      const attendues = {
        "Tête de l'année": '1 Aviv',
        'Pessah (Pâque)': '14 Aviv',
        'Pains sans levain — 1er jour': '15 Aviv',
        'Pains sans levain — 7e jour': '21 Aviv',
        'Reshit Katzir (Prémices)': '26 Aviv',
        'Shavouot (Pentecôte)': '15 Sivan',
        'Yom Teroua (Trompettes)': '1 Éthanim',
        'Yom Kippour (Expiations)': '10 Éthanim',
        'Souccot (Tabernacles) — 1er jour': '15 Éthanim',
        'Shemini Atzeret (8e jour)': '22 Éthanim',
      };
      for (final f in annee.fetes) {
        expect(attendues[f.nomFr], f.dateBiblique,
            reason: '${f.nomFr} : ${f.dateBiblique}');
      }
      expect(annee.fetes.length, 10);
    });

    test('Shavouot = 50ᵉ jour après Reshit Katzir (Lévitique 23:15-16)', () {
      final reshit = annee.fetes
          .firstWhere((f) => f.nomFr.startsWith('Reshit'));
      final shavouot =
          annee.fetes.firstWhere((f) => f.nomFr.startsWith('Shavouot'));
      final difference = DateTime(shavouot.dateGregorienne.year,
              shavouot.dateGregorienne.month, shavouot.dateGregorienne.day)
          .difference(DateTime(reshit.dateGregorienne.year,
              reshit.dateGregorienne.month, reshit.dateGregorienne.day))
          .inDays;
      expect(difference, 49,
          reason: 'Reshit compté comme 1ᵉʳ jour → 50ᵉ = +49 jours');
    });

    test('Souccot dure 7 jours puis Shemini Atzeret (8ᵉ jour)', () {
      final souccot =
          annee.fetes.firstWhere((f) => f.nomFr.startsWith('Souccot'));
      final shemini =
          annee.fetes.firstWhere((f) => f.nomFr.startsWith('Shemini'));
      expect(souccot.dureeJours, 7);
      final difference = DateTime(shemini.dateGregorienne.year,
              shemini.dateGregorienne.month, shemini.dateGregorienne.day)
          .difference(DateTime(souccot.dateGregorienne.year,
              souccot.dateGregorienne.month, souccot.dateGregorienne.day))
          .inDays;
      expect(difference, 7, reason: '22 Éthanim = 15 Éthanim + 7');
    });

    test('joursRestants : même convention que le backend', () {
      final fete = annee.fetes.first;
      // joursRestants = (fête − aujourd'hui) en jours entiers
      final aujourdhui = DateTime(2026, 1, 1);
      final attendu = DateTime(fete.dateGregorienne.year,
              fete.dateGregorienne.month, fete.dateGregorienne.day)
          .difference(DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day))
          .inDays;
      expect(BiblicalCalendarEngine.joursRestants(fete, maintenant: aujourdhui),
          attendu);
    });
  });

  group('Recherche d\u2019année et de jour', () {
    test('anneePourDate retrouve l\u2019année en cours (milieu d\u2019année)', () {
      final a = BiblicalCalendarEngine.anneePourDate(DateTime(2026, 11, 26));
      expect(a.annee, 2026);
      expect(a.libelle, '2026-2027');
    });

    test('anneePourDate au tout début de l\u2019année biblique', () {
      final a = BiblicalCalendarEngine.anneePourDate(DateTime(2026, 3, 18));
      expect(a.annee, 2026);
    });

    test('anneePourDate en décembre (fin d\u2019année biblique en cours)', () {
      final a = BiblicalCalendarEngine.anneePourDate(DateTime(2026, 12, 25));
      expect(a.annee, 2026, reason: 'l\u2019année biblique 2026-2027 est en cours');
    });

    test('jourPourDate retrouve le bon jour biblique', () {
      final j = annee.jourPourDate(DateTime(2026, 3, 18));
      expect(j, isNotNull);
      expect(j!.jourDeAnnee, 1);
      expect(j.mois, 1);
      expect(j.jourDuMois, 1);
    });

    test('jourPourDate → null hors de l\u2019année', () {
      expect(annee.jourPourDate(DateTime(2019, 5, 5)), isNull);
    });

    test('bornes API 1900-2100 respectées', () {
      expect(BiblicalCalendarEngine.debutAnneeBiblique(1900).weekday,
          DateTime.wednesday);
      expect(BiblicalCalendarEngine.debutAnneeBiblique(2100).weekday,
          DateTime.wednesday);
    });
  });
}
