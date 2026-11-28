/// ⭐ TESTS DE LA BASCULE DE LA DATE BIBLIQUE AU COUCHER DU SOLEIL RÉEL
/// (§2.3, §14 — demande utilisateur v1.0.8 : « dès le coucher du soleil,
/// la date bascule automatiquement au lendemain, selon le pays — jamais à
/// minuit civil » ; valable partout : horloge, calendrier, alarmes,
/// notifications Shabbat/fêtes).
///
/// Position de référence : Kinshasa (RD Congo, UTC+1 sans heure d'été) —
/// le coucher du soleil y varie selon la saison ; les instants de test
/// sont construits RELATIVEMENT au coucher calculé par le SolarEngine,
/// donc la vérification reste vraie pour n'importe quel pays.
library;

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

void main() {
  const lat = -4.44; // Kinshasa
  const lon = 15.27;

  final date = DateTime(2026, 3, 20); // jour civil de référence
  final coucher = SolarEngine.calculer(date, lat, lon).coucher!;

  BiblicalCalendarAdapter adapter() =>
      BiblicalCalendarAdapter(latitude: lat, longitude: lon);

  group('Le jour biblique bascule AU COUCHER DU SOLEIL (§2.3)', () {
    test('avant le coucher : jour biblique = date civile du jour', () {
      final avant = coucher.subtract(const Duration(hours: 1));
      final jour = adapter().jourBibliqueActuel(avant);
      expect(jour, isNotNull);
      expect(jour!.dateGregorienne.year, date.year);
      expect(jour.dateGregorienne.month, date.month);
      expect(jour.dateGregorienne.day, date.day);
    });

    test('JUSTE APRÈS le coucher (même soir civil ≈ 18 h) : déjà DEMAIN', () {
      final apres = coucher.add(const Duration(minutes: 10));
      // Toujours le MÊME soir civil (vers 18 h) — jamais minuit :
      expect(apres.day, date.day);
      final jour = adapter().jourBibliqueActuel(apres);
      expect(jour!.dateGregorienne.day, date.day + 1);
    });

    test('après minuit civil : le MÊME jour biblique continue', () {
      // 00 h 30 le lendemain civil : le jour biblique entamé au coucher
      // de ce soir est encore le même — il court jusqu'au prochain coucher.
      final minuit = DateTime(date.year, date.month, date.day)
          .add(const Duration(days: 1, minutes: 30));
      final jour = adapter().jourBibliqueActuel(minuit);
      expect(jour!.dateGregorienne.day, date.day + 1);
    });

    test('le jour biblique continue après le lever, jusqu\'au coucher suivant',
        () {
      final matin = DateTime(date.year, date.month, date.day)
          .add(const Duration(days: 1, hours: 10)); // 10 h le lendemain
      final jour = adapter().jourBibliqueActuel(matin);
      expect(jour!.dateGregorienne.day, date.day + 1);
    });
  });

  group('Transition §14 — due au coucher, protégée par clé anti-double', () {
    test('aucune transition due AVANT le coucher', () {
      final avant = coucher.subtract(const Duration(hours: 2));
      expect(
          adapter().evaluerTransition(maintenant: avant).transitionDue, isFalse);
    });

    test('transition due JUSTE APRÈS le coucher → nouveau jour = demain', () {
      final apres = coucher.add(const Duration(minutes: 1));
      final evaluation = adapter().evaluerTransition(maintenant: apres);
      expect(evaluation.transitionDue, isTrue);
      expect(evaluation.coucherDeclencheur, coucher);
      expect(evaluation.nouveauJour!.dateGregorienne.day, date.day + 1);
    });

    test('la même transition n\'est JAMAIS traitée deux fois', () {
      final apres = coucher.add(const Duration(minutes: 1));
      final evaluation = adapter().evaluerTransition(maintenant: apres);
      final reprise = adapter().evaluerTransition(
          maintenant: apres.add(const Duration(minutes: 5)),
          cleTraitee: evaluation.cleTransition);
      expect(reprise.transitionDue, isFalse);
    });
  });

  group('Comptes à rebours J-x comptés depuis le jour BIBLIQUE', () {
    test('soir après coucher : la fête du lendemain est J-0 (elle a commencé)',
        () {
      final annee = BiblicalCalendarEngine.construireAnnee(2026);
      final fete = annee.fetes.first;
      final veille = DateTime(fete.dateGregorienne.year,
              fete.dateGregorienne.month, fete.dateGregorienne.day)
          .subtract(const Duration(days: 1));
      final coucherVeille =
          SolarEngine.calculer(veille, lat, lon).coucher!;
      final apresCoucher = coucherVeille.add(const Duration(minutes: 15));

      // Le jour biblique en cours est DÉJÀ celui de la fête : J-0.
      final jourBiblique = adapter().jourBibliqueActuel(apresCoucher);
      expect(jourBiblique!.dateGregorienne.day, fete.dateGregorienne.day);
      expect(
          BiblicalCalendarEngine.joursRestants(fete,
              maintenant: jourBiblique.dateGregorienne),
          0);

      // Contraste (ancien comportement minuit civil) : J-1 — corrigé par
      // l'app qui passe désormais la date du jour biblique en cours.
      expect(
          BiblicalCalendarEngine.joursRestants(fete, maintenant: veille), 1);
    });
  });

  group('Alarmes et notifications au coucher réel — jamais 18 h 00 fixes',
      () {
    test('RHEMA du soir sonne au coucher du soleil RÉEL du jour', () {
      final midi = DateTime(2026, 3, 20, 12, 0);
      final plan = AlarmPlanner.planifier(
        adapter: adapter(),
        alarmes: [
          const AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: 'Le soleil se couche.'),
        ],
        maintenant: midi,
      );
      expect(plan, isNotEmpty);
      expect(plan.first.instant, coucher);
    });

    test('entrée du Shabbat = coucher réel de la veille du jour de Shabbat',
        () {
      final annee = BiblicalCalendarEngine.construireAnnee(2026);
      final evenements = BiblicalCalendarEngine.construireEvenements(
          annee, (jour) => SolarEngine.calculer(jour, lat, lon).coucher!);
      final shabbat =
          evenements.firstWhere((e) => e.type == 'shabbat');
      expect(
          shabbat.entree,
          SolarEngine.calculer(
                  shabbat.dateGregorienne.subtract(const Duration(days: 1)),
                  lat,
                  lon)
              .coucher);
      expect(shabbat.sortie,
          SolarEngine.calculer(shabbat.dateGregorienne, lat, lon).coucher);
    });

    test('les fêtes entrent au coucher réel de leur veille (jalons J-7/3/24h)',
        () {
      final annee = BiblicalCalendarEngine.construireAnnee(2026);
      final evenements = BiblicalCalendarEngine.construireEvenements(
          annee, (jour) => SolarEngine.calculer(jour, lat, lon).coucher!);
      final fete = evenements.firstWhere((e) => e.type == 'fete');
      expect(
          fete.entree,
          SolarEngine.calculer(
                  fete.dateGregorienne.subtract(const Duration(days: 1)),
                  lat,
                  lon)
              .coucher);
      // Les jalons d'approche tombent eux-mêmes aux couchers décalés.
      expect(fete.jalons.map((j) => j.cle).toSet(),
          {'j7', 'j3', 'j24h'});
    });
  });
}
