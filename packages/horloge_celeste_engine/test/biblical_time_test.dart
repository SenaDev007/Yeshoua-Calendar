/// ⭐ TESTS DES TROIS VEILLES ET DES DOUZE HEURES SAISONNIÈRES (§15.2, §15.3).
library;

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

void main() {
  // ── Nuit type (équinoxe) : coucher 18 h 00 → lever 06 h 00 ──
  final coucher = DateTime(2026, 3, 20, 18, 0);
  final lever = DateTime(2026, 3, 21, 6, 0); // lever qui clôt la nuit
  final maintenant = DateTime(2026, 3, 20, 22, 30); // en pleine 1ʳᵉ veille

  // ── Jour type du 20/03 : lever 06 h 00 → coucher 18 h 00 ──
  final leverJour = DateTime(2026, 3, 20, 6, 0);
  final coucherJour = DateTime(2026, 3, 20, 18, 0);

  // Nuit de 11 h 30 (§3.4 : les veilles durent chacune ≈ 3 h 50)
  final coucher1130 = DateTime(2026, 12, 21, 18, 15);
  final lever1130 = DateTime(2026, 12, 22, 5, 45);

  group('Trois veilles de la nuit (§3)', () {
    final veilles = BiblicalTimeEngine.veillesDeLaNuit(
      coucher: coucher,
      lever: lever,
      maintenant: maintenant,
    );

    test('exactement trois veilles nommées et sous-titrées', () {
      expect(veilles.length, 3);
      expect(veilles[0].nom, 'PREMIÈRE VEILLE');
      expect(veilles[0].sousTitre, 'Veille du commencement de la nuit');
      expect(veilles[1].nom, 'DEUXIÈME VEILLE');
      expect(veilles[1].sousTitre, 'Veille du milieu de la nuit');
      expect(veilles[2].nom, 'TROISIÈME VEILLE');
      expect(veilles[2].sousTitre, 'Veille du matin');
    });

    test('la première veille commence AU COUCHER du soleil', () {
      expect(veilles[0].debut, coucher);
    });

    test('la première veille finit au PREMIER TIERS de la nuit', () {
      expect(veilles[0].fin, coucher.add(const Duration(hours: 4)));
    });

    test('la deuxième veille finit aux DEUX TIERS', () {
      expect(veilles[1].debut, veilles[0].fin);
      expect(veilles[1].fin, coucher.add(const Duration(hours: 8)));
    });

    test('la troisième veille finit AU LEVER du soleil', () {
      expect(veilles[2].debut, veilles[1].fin);
      expect(veilles[2].fin, lever);
    });

    test('les trois veilles couvrent EXACTEMENT toute la nuit', () {
      expect(veilles[0].debut, coucher);
      expect(veilles[2].fin, lever);
      // Continuité sans trou ni chevauchement
      expect(veilles[1].debut, veilles[0].fin);
      expect(veilles[2].debut, veilles[1].fin);
      final somme = veilles.fold<Duration>(
          Duration.zero, (a, v) => a + v.duree);
      expect(somme, lever.difference(coucher));
    });

    test('JAMAIS de tranches fixes de 4 h : nuit de 11 h 30 → veilles ≈ 3 h 50',
        () {
      final veilles1130 = BiblicalTimeEngine.veillesDeLaNuit(
        coucher: coucher1130,
        lever: lever1130,
        maintenant: coucher1130.add(const Duration(hours: 2)),
      );
      final dureeNuit = lever1130.difference(coucher1130);
      expect(dureeNuit, const Duration(hours: 11, minutes: 30));
      for (final v in veilles1130) {
        expect(v.duree.inMinutes, 230,
            reason: '11 h 30 / 3 = 3 h 50 exactement');
      }
    });

    test('statuts et progression : à venir / en cours / terminée', () {
      // 22 h 30 : 1ʳᵉ veille (18 h → 22 h) terminée, 2ᵉ (22 h → 02 h) en cours
      final veilles2230 = BiblicalTimeEngine.veillesDeLaNuit(
        coucher: coucher,
        lever: lever,
        maintenant: maintenant,
      );
      expect(veilles2230[0].statut, StatutPeriode.terminee);
      expect(veilles2230[0].progression, 1.0);
      expect(veilles2230[1].statut, StatutPeriode.enCours);
      expect(veilles2230[1].progression, greaterThan(0.0));
      expect(veilles2230[1].progression, lessThan(1.0));
      expect(veilles2230[2].statut, StatutPeriode.aVenir);
      expect(veilles2230[2].progression, 0.0);

      // Plus tard : 23 h 00 → toujours 2ᵉ veille en cours
      final veilles2300 = BiblicalTimeEngine.veillesDeLaNuit(
        coucher: coucher,
        lever: lever,
        maintenant: DateTime(2026, 3, 20, 23, 0),
      );
      expect(veilles2300[0].statut, StatutPeriode.terminee);
      expect(veilles2300[0].progression, 1.0);
      expect(veilles2300[1].statut, StatutPeriode.enCours);
    });

    test('veilleEnCours le soir → 1ʳᵉ veille ; avant l\u2019aube → 3ᵉ veille',
        () {
      final solar = SolarTimes(lever: lever, coucher: coucher, latitude: 0, longitude: 0);
      final solarSuivant = SolarTimes(
        lever: DateTime(2026, 3, 21, 6, 0), // lever qui clôt la nuit du 20
        coucher: DateTime(2026, 3, 21, 18, 0),
        latitude: 0,
        longitude: 0,
      );
      final solarPrecedent = SolarTimes(
        lever: DateTime(2026, 3, 20, 6, 0),
        coucher: DateTime(2026, 3, 19, 18, 0),
        latitude: 0,
        longitude: 0,
      );

      // 20 h 30 : pleine 1ʳᵉ veille
      final soir = BiblicalTimeEngine.veilleEnCours(
        jour: solar,
        jourSuivant: solarSuivant,
        jourPrecedent: solarPrecedent,
        maintenant: DateTime(2026, 3, 20, 19, 30),
      );
      expect(soir, isNotNull);
      expect(soir!.indice, IndiceVeille.premiere);

      // 23 h : deuxième veille
      final nuit = BiblicalTimeEngine.veilleEnCours(
        jour: solar,
        jourSuivant: solarSuivant,
        jourPrecedent: solarPrecedent,
        maintenant: DateTime(2026, 3, 20, 23, 0),
      );
      expect(nuit!.indice, IndiceVeille.deuxieme);

      // 04 h 30 du matin : troisième veille
      final aube = BiblicalTimeEngine.veilleEnCours(
        jour: solar,
        jourSuivant: solarSuivant,
        jourPrecedent: solarPrecedent,
        maintenant: DateTime(2026, 3, 21, 4, 30),
      );
      expect(aube!.indice, IndiceVeille.troisieme);
    });
  });

  group('Douze heures saisonnières (§4)', () {
    final heures = BiblicalTimeEngine.heuresSaisonniere(
      lever: leverJour,
      coucher: coucherJour,
      maintenant: DateTime(2026, 3, 20, 10, 30), // en pleine 5ᵉ heure
    );

    test('12 heures numérotées de 1 à 12', () {
      expect(heures.length, 12);
      for (var i = 0; i < 12; i++) {
        expect(heures[i].numero, i + 1);
      }
    });

    test('la journée diurne est EXACTEMENT couverte', () {
      expect(heures.first.debut, leverJour);
      expect(heures.last.fin, coucherJour,
          reason: 'la douzième heure se termine au coucher du soleil');
      final somme =
          heures.fold<Duration>(Duration.zero, (a, h) => a + h.duree);
      expect(somme, coucherJour.difference(leverJour));
      // Continuité
      for (var i = 1; i < 12; i++) {
        expect(heures[i].debut, heures[i - 1].fin);
      }
    });

    test('heure saisonnière ≠ heure civile : jour de 13 h → 65 min', () {
      final lever13 = DateTime(2026, 6, 21, 6, 0);
      final coucher13 = DateTime(2026, 6, 21, 19, 0);
      final heures13 = BiblicalTimeEngine.heuresSaisonniere(
        lever: lever13,
        coucher: coucher13,
        maintenant: lever13,
      );
      for (final h in heures13) {
        expect(h.duree, const Duration(minutes: 65),
            reason: '13 h / 12 = 65 min');
      }
    });

    test('jour de 11 h → heure saisonnière de 55 min', () {
      final heures11 = BiblicalTimeEngine.heuresSaisonniere(
        lever: DateTime(2026, 12, 21, 7, 0),
        coucher: DateTime(2026, 12, 21, 18, 0),
        maintenant: DateTime(2026, 12, 21, 7, 30),
      );
      for (final h in heures11) {
        expect(h.duree, const Duration(minutes: 55));
      }
    });

    test('équinoxe 12 h → chaque heure fait 60 min (cas particulier)', () {
      for (final h in heures) {
        expect(h.duree, const Duration(hours: 1));
      }
    });

    test('statuts et progression des heures', () {
      // maintenant = 10 h 30 → 5ᵉ heure en cours (8 h + 2 h 30)
      expect(heures[4].numero, 5);
      expect(heures[4].statut, StatutPeriode.enCours);
      expect(heures[3].statut, StatutPeriode.terminee);
      expect(heures[5].statut, StatutPeriode.aVenir);
    });

    test('reperes scripturaires : 3ᵉ, 6ᵉ, 9ᵉ, 11ᵉ heures', () {
      expect(heures[2].repereScripturaire, contains('Troisième heure'));
      expect(heures[5].repereScripturaire, contains('Sixième heure'));
      expect(heures[8].repereScripturaire, contains('Neuvième heure'));
      expect(heures[10].repereScripturaire, contains('Onzième heure'));
      for (var i = 0; i < 12; i++) {
        if (![3, 6, 9, 11].contains(i + 1)) {
          expect(heures[i].repereScripturaire, isNull);
        }
      }
    });
  });

  group('Quatre parties du jour (§4.3)', () {
    final parties = BiblicalTimeEngine.partiesDuJour(
      lever: leverJour,
      coucher: coucherJour,
      maintenant: DateTime(2026, 3, 20, 10, 30), // en pleine 2ᵉ partie
    );

    test('4 parties de 3 heures saisonnières, désignations exactes', () {
      expect(parties.length, 4);
      expect(parties[0].de, 1);
      expect(parties[0].a, 3);
      expect(parties[0].designation, 'Matin');
      expect(parties[1].de, 4);
      expect(parties[1].a, 6);
      expect(parties[1].designation, 'Approche du milieu du jour');
      expect(parties[2].de, 7);
      expect(parties[2].a, 9);
      expect(parties[2].designation, 'Après-midi');
      expect(parties[3].de, 10);
      expect(parties[3].a, 12);
      expect(parties[3].designation, 'Fin du jour');
    });

    test('les 4 parties couvrent tout le jour sans chevauchement', () {
      expect(parties[0].progression, greaterThan(0));
      expect(parties[1].statut, StatutPeriode.enCours);
      expect(parties[2].statut, StatutPeriode.aVenir);
      // Couverture par les heures saisonnières associées
      final heures = BiblicalTimeEngine.heuresSaisonniere(
        lever: leverJour,
        coucher: coucherJour,
        maintenant: DateTime(2026, 3, 20, 10, 30),
      );
      for (var p = 0; p < 4; p++) {
        final heuresDeLaPartie =
            heures.where((h) => h.partie == p + 1).toList();
        expect(heuresDeLaPartie.length, 3);
        expect(heuresDeLaPartie.first.numero, p * 3 + 1);
      }
      // Une partie commence là où la précédente se termine
      for (var i = 1; i < parties.length; i++) {
        // (la 2ᵉ partie commence au 3ᵉ début de la 1ʳᵉ + 3 h saisonnières)
        expect(parties[i].a - parties[i].de, 2);
      }
    });
  });

  group('Période actuelle et cycle complet (§5, §11)', () {
    // Jour 20/03 : lever 06 h 00, coucher 18 h 00 — jour, suivant, précédent
    final solar = SolarTimes(
      lever: leverJour,
      coucher: coucherJour,
      latitude: 6.37,
      longitude: 2.42,
    );
    final solarSuivant = SolarTimes(
      lever: DateTime(2026, 3, 21, 6, 0),
      coucher: DateTime(2026, 3, 21, 18, 0),
      latitude: 6.37,
      longitude: 2.42,
    );
    final solarPrecedent = SolarTimes(
      lever: DateTime(2026, 3, 19, 6, 0),
      coucher: DateTime(2026, 3, 19, 18, 0),
      latitude: 6.37,
      longitude: 2.42,
    );

    test('le jour : JourEnCours avec heure saisonnière et parties', () {
      final p = BiblicalTimeEngine.periodeActuelle(
        jour: solar,
        jourSuivant: solarSuivant,
        jourPrecedent: solarPrecedent,
        maintenant: DateTime(2026, 3, 20, 10, 30),
      );
      expect(p, isA<JourEnCours>());
      final j = p as JourEnCours;
      expect(j.heure.numero, 5);
      expect(j.parties[1].statut, StatutPeriode.enCours);
      expect(j.prochainCoucher, coucherJour);
    });

    test('la nuit : NuitEnCours avec la veille active', () {
      // 20 h 30 : pleine 1ʳᵉ veille
      final p = BiblicalTimeEngine.periodeActuelle(
        jour: solar,
        jourSuivant: solarSuivant,
        jourPrecedent: solarPrecedent,
        maintenant: DateTime(2026, 3, 20, 20, 30),
      );
      expect(p, isA<NuitEnCours>());
      final n = p as NuitEnCours;
      expect(n.veille.indice, IndiceVeille.premiere);
      expect(n.veilles.length, 3);
      expect(n.prochainLever, lever);
    });

    test('cycle complet : 10 jalons dans l\u2019ordre chronologique', () {
      final cycle = BiblicalTimeEngine.cycleComplet(
        coucher: coucher,
        lever: lever,
        coucherSuivant: DateTime(2026, 3, 21, 18, 0),
      );
      expect(cycle.length, 10);
      expect(cycle[0].nom, 'Coucher du soleil');
      expect(cycle[1].nom, 'PREMIÈRE VEILLE');
      expect(cycle[3].nom, 'TROISIÈME VEILLE');
      expect(cycle[4].nom, 'Lever du soleil');
      expect(cycle[8].nom, 'Quatrième partie du jour');
      expect(cycle[9].nom, 'Coucher du soleil');
      for (var i = 1; i < cycle.length; i++) {
        expect(cycle[i].debut.isAfter(cycle[i - 1].debut) ||
            cycle[i].debut == cycle[i - 1].debut,
            isTrue,
            reason: 'jalon $i non-chronologique');
      }
    });

    test('région polaire : PeriodeIndisponible — jamais d\u2019horaire inventé',
        () {
      final polar = SolarTimes(latitude: 78.22, longitude: 15.65);
      final p = BiblicalTimeEngine.periodeActuelle(
        jour: polar,
        jourSuivant: polar,
        jourPrecedent: polar,
        maintenant: DateTime(2026, 12, 21, 12, 0),
      );
      expect(p, isA<PeriodeIndisponible>());
    });
  });
}
