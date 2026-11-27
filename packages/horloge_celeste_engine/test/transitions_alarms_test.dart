/// ⭐ TESTS DE TRANSITION TEMPORELLE ET D'ALARMES (§14, §15.4, §15.5).
///
/// Les tests utilisent Cotonou (6.37 N, 2.42 E, UTC+1 — Africa/Porto-Novo)
/// comme position de référence, pour coller au contexte du cahier des
/// charges. Pour la REPRODUCTIBILITÉ, le coucher du soleil de Cotonou le
/// 20/03/2026 est calculé par le moteur et les assertions portent sur la
/// LOGIQUE de transition (indépendante de la minute exacte).
library;

import 'package:test/test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

const latCotonou = 6.37;
const lonCotonou = 2.42;

void main() {
  group('Transition de date biblique au coucher réel (§14, §15.4)', () {
    test('le coucher du 20/03/2026 à Cotonou est calculé et plausible',
        () {
      final solar = SolarEngine.calculer(DateTime(2026, 3, 20), latCotonou, lonCotonou);
      expect(solar.calculable, isTrue);
      // Cotonou, équinoxe : coucher entre 18 h 15 et 19 h 15 locales
      expect(solar.coucher!.hour, inInclusiveRange(18, 19));
      expect(solar.coucher!.minute, inInclusiveRange(0, 59));
    });

    test('à 18 h 11 (avant coucher calculé) : pas de transition', () {
      final solar = SolarEngine.calculer(DateTime(2026, 3, 20), latCotonou, lonCotonou);
      final avantCoucher = solar.coucher!.subtract(const Duration(minutes: 1));
      final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);
      final resultat = adapter.evaluerTransition(
        maintenant: avantCoucher,
        cleTraitee: null,
      );
      expect(resultat.transitionDue, isFalse,
          reason: 'avant le coucher réel, le jour biblique continue');
      // Le jour biblique actuel est celui de la date civile du jour
      final jour = adapter.jourBibliqueActuel(avantCoucher);
      expect(jour!.dateGregorienne.day, avantCoucher.day);
    });

    test('après le coucher réel : la date biblique avance d\u2019un jour', () {
      final solar = SolarEngine.calculer(DateTime(2026, 3, 20), latCotonou, lonCotonou);
      final apresCoucher = solar.coucher!.add(const Duration(minutes: 2));
      final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);

      final jour = adapter.jourBibliqueActuel(apresCoucher);
      expect(jour!.dateGregorienne.day, apresCoucher.add(const Duration(days: 1)).day,
          reason: 'après le coucher, c\u2019est le jour biblique suivant qui est en cours');

      final resultat = adapter.evaluerTransition(maintenant: apresCoucher);
      expect(resultat.transitionDue, isTrue);
      expect(resultat.nouveauJour, isNotNull);
      expect(resultat.coucherDeclencheur, solar.coucher);
      expect(resultat.cleTransition, isNotNull);
    });

    test('PAS de double transition : la même clé traitée est refusée', () {
      final solar = SolarEngine.calculer(DateTime(2026, 3, 20), latCotonou, lonCotonou);
      final apresCoucher = solar.coucher!.add(const Duration(hours: 1));
      final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);
      final premier = adapter.evaluerTransition(maintenant: apresCoucher);
      expect(premier.transitionDue, isTrue);

      final second = adapter.evaluerTransition(
        maintenant: apresCoucher.add(const Duration(minutes: 1)),
        cleTraitee: premier.cleTransition,
      );
      expect(second.transitionDue, isFalse,
          reason: 'protection anti-double incrémentation');
    });

    test('PAS de changement à minuit civil (§15.4)', () {
      final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);
      final minuit = DateTime(2026, 3, 21, 0, 0, 0, 500); // minuit + 0,5 s
      final resultat = adapter.evaluerTransition(maintenant: minuit);
      // À minuit civil, on est en pleine nuit : pas de coucher traversé
      // depuis la dernière évaluation (le coucher a eu lieu ~18 h 50 la
      // veille — c'est la clé de transition du jour biblique déjà en
      // cours, traitée ou non, mais PAS une nouvelle transition à minuit).
      final solar21 =
          SolarEngine.calculer(DateTime(2026, 3, 21), latCotonou, lonCotonou);
      expect(minuit.isBefore(solar21.coucher!), isTrue);
      expect(resultat.transitionDue, isFalse,
          reason: 'minuit civil n\u2019est PAS le déclencheur');
      // Et le jour biblique en cours reste celui commencé au coucher précédent
      final jour = adapter.jourBibliqueActuel(minuit);
      expect(jour!.dateGregorienne.day, 21,
          reason: 'le jour biblique commencé au coucher du 20 se poursuit');
    });

    test('reprise après plusieurs heures : recalcul depuis l\u2019heure réelle',
        () {
      final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);
      // L'app se ferme avant le coucher, se rouvre après.
      final avant = DateTime(2026, 3, 20, 17, 0);
      final apres = DateTime(2026, 3, 20, 20, 30);
      final jourAvant = adapter.jourBibliqueActuel(avant);
      final jourApres = adapter.jourBibliqueActuel(apres);
      expect(jourApres!.jourDeAnnee, jourAvant!.jourDeAnnee + 1,
          reason: 'la transition est retrouvée SANS compteur vivant');
    });

    test('changement de localisation : recalcul des horaires', () {
      final adapterCotonou =
          BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);
      final adapterParis =
          BiblicalCalendarAdapter(latitude: 48.85, longitude: 2.35);
      final maintenant = DateTime(2026, 3, 20, 12, 0);
      final coucherCotonou = adapterCotonou.prochainCoucher(maintenant);
      final coucherParis = adapterParis.prochainCoucher(maintenant);
      expect(coucherCotonou, isNotNull);
      expect(coucherParis, isNotNull);
      expect(coucherParis!.hour, greaterThan(coucherCotonou!.hour - 4),
          reason: 'Paris coucher plus tard en mars (UTC+1 vs UTC+1)');
    });

    test('état persistable (§13) : sérialisation JSON', () {
      final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);
      final etat = adapter.etatTemporel(DateTime(2026, 3, 20, 12, 0),
          fuseau: 'Africa/Porto-Novo');
      final json = etat.toJson();
      final restaure = EtatTemporel.fromJson(json);
      expect(restaure.fuseau, etat.fuseau);
      expect(restaure.anneeBibliqueEnCours, etat.anneeBibliqueEnCours);
      expect(restaure.jourDeAnneeEnCours, etat.jourDeAnneeEnCours);
      expect(restaure.prochainCoucherCalcule, isNotNull);
    });
  });

  group('Alarmes spirituelles (§8, §15.5)', () {
    final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);

    test('RHEMA du matin : programmé à 05 h 00 locales (jamais dans le passé)',
        () {
      final maintenant = DateTime(2026, 3, 20, 6, 30);
      final cible = AlarmPlanner.prochainRhemaMatin(maintenant);
      // 05 h 00 déjà passé → demain 05 h 00
      expect(cible.day, 21);
      expect(cible.hour, 5);
      expect(cible.minute, 0);
      expect(cible.isAfter(maintenant), isTrue);

      final avantLEnCours = DateTime(2026, 3, 20, 4, 30);
      final cible2 = AlarmPlanner.prochainRhemaMatin(avantLEnCours);
      expect(cible2.day, 20, reason: '05 h 00 à venir aujourd\u2019hui');
    });

    test('Préparation du soir = coucher − 5 minutes (§8.2)', () {
      final maintenant = DateTime(2026, 3, 20, 12, 0);
      final coucher = adapter.prochainCoucher(maintenant)!;
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
            type: TypeAlarme.preparationSoir,
            nom: 'Préparation du soir',
            message: AlarmPlanner.messagePreparationDefaut,
          ),
        ],
        maintenant: maintenant,
      );
      expect(plan.length, 1);
      expect(plan.first.instant, coucher.subtract(const Duration(minutes: 5)));
    });

    test('RHEMA du soir = au coucher du soleil EXACT (§8.3)', () {
      final maintenant = DateTime(2026, 3, 20, 12, 0);
      final coucher = adapter.prochainCoucher(maintenant)!;
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
            type: TypeAlarme.rhemaSoir,
            nom: 'RHEMA du soir',
            message: AlarmPlanner.messageSoirDefaut,
          ),
        ],
        maintenant: maintenant,
      );
      expect(plan.length, 1);
      expect(plan.first.instant, coucher,
          reason: 'jamais une heure fixe : le coucher réel fait foi');
    });

    test('les trois alarmes planifiées sont ordonnées et identifiées', () {
      final maintenant = DateTime(2026, 3, 20, 3, 0);
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaMatin,
              nom: 'RHEMA du matin',
              message: AlarmPlanner.messageMatinDefaut),
          AlarmeSpirituelle(
              type: TypeAlarme.preparationSoir,
              nom: 'Préparation du soir',
              message: AlarmPlanner.messagePreparationDefaut),
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: AlarmPlanner.messageSoirDefaut),
        ],
        maintenant: maintenant,
      );
      expect(plan.length, 3);
      // 1ʳᵉ : RHEMA matin (05 h 00) — les suivantes : soir (coucher)
      expect(plan[0].type, TypeAlarme.rhemaMatin);
      expect(plan[0].instant.hour, 5);
      expect(plan[1].type, TypeAlarme.preparationSoir);
      expect(plan[2].type, TypeAlarme.rhemaSoir);
      // La préparation précède le coucher de 5 minutes
      expect(
        plan[2].instant.difference(plan[1].instant),
        const Duration(minutes: 5),
      );
      // Identifiants de notification stables et distincts
      expect(plan[0].id, AlarmPlanner.idRhemaMatin);
      expect(plan[1].id, AlarmPlanner.idPreparationSoir);
      expect(plan[2].id, AlarmPlanner.idRhemaSoir);
    });

    test('une alarme désactivée n\u2019est pas planifiée', () {
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaMatin,
              nom: 'RHEMA du matin',
              message: 'x',
              activee: false),
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: 'y'),
        ],
        maintenant: DateTime(2026, 3, 20, 3, 0),
      );
      expect(plan.length, 1);
      expect(plan.first.type, TypeAlarme.rhemaSoir);
    });

    test('reprogrammation quotidienne : le lendemain, les instants avancent',
        () {
      final lundi = DateTime(2026, 3, 23, 12, 0);
      final mardi = DateTime(2026, 3, 24, 12, 0);
      final coucherLundi = adapter.prochainCoucher(lundi)!;
      final coucherMardi = adapter.prochainCoucher(mardi)!;
      expect(coucherMardi.day, 24);
      expect(coucherLundi.day, 23);
      expect(coucherMardi.isAfter(coucherLundi), isTrue);
    });

    test('région polaire : aucune alarme du soir fictive (§9.4)', () {
      final adapterPolaire =
          BiblicalCalendarAdapter(latitude: 78.22, longitude: 15.65);
      final plan = AlarmPlanner.planifier(
        adapter: adapterPolaire,
        alarmes: const [
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaSoir,
              nom: 'RHEMA du soir',
              message: AlarmPlanner.messageSoirDefaut),
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaMatin,
              nom: 'RHEMA du matin',
              message: AlarmPlanner.messageMatinDefaut),
        ],
        maintenant: DateTime(2026, 12, 21, 12, 0),
      );
      // Le RHEMA du matin (05 h 00, indépendant du soleil) reste planifié ;
      // les alarmes solaires sont omises — JAMAIS remplacées par une heure fictive.
      expect(plan.length, 1);
      expect(plan.first.type, TypeAlarme.rhemaMatin);
    });
  });

  group('Horaires réglables par l\u2019utilisateur (§8.4)', () {
    final adapter = BiblicalCalendarAdapter(latitude: latCotonou, longitude: lonCotonou);

    test('RHEMA du matin à une heure choisie (ex. 21 h 30) : respectée', () {
      final maintenant = DateTime(2026, 3, 20, 6, 30);
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
            type: TypeAlarme.rhemaMatin,
            nom: 'RHEMA du matin',
            message: AlarmPlanner.messageMatinDefaut,
            heure: 21,
            minute: 30,
          ),
        ],
        maintenant: maintenant,
      );
      expect(plan.length, 1);
      // 21 h 30 à venir aujourd'hui → ce soir même.
      expect(plan.first.instant.day, 20);
      expect(plan.first.instant.hour, 21);
      expect(plan.first.instant.minute, 30);
    });

    test('RHEMA du matin : l\u2019heure choisie passée → jour suivant', () {
      final maintenant = DateTime(2026, 3, 20, 22, 0);
      final cible = AlarmPlanner.prochainRhemaMatin(maintenant,
          heure: 5, minute: 15);
      expect(cible.day, 21, reason: '05 h 15 déjà passé ce jour-là');
      expect(cible.hour, 5);
      expect(cible.minute, 15);
    });

    test('défauts historiques conservés : 05 h 00 et préparation − 5 min', () {
      final maintenant = DateTime(2026, 3, 20, 12, 0);
      final coucher = adapter.prochainCoucher(maintenant)!;
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
              type: TypeAlarme.rhemaMatin,
              nom: 'RHEMA du matin',
              message: AlarmPlanner.messageMatinDefaut),
          AlarmeSpirituelle(
              type: TypeAlarme.preparationSoir,
              nom: 'Préparation du soir',
              message: AlarmPlanner.messagePreparationDefaut),
        ],
        maintenant: maintenant,
      );
      final matin = plan.firstWhere((a) => a.type == TypeAlarme.rhemaMatin);
      final prep =
          plan.firstWhere((a) => a.type == TypeAlarme.preparationSoir);
      expect(matin.instant.hour, 5);
      expect(matin.instant.minute, 0);
      expect(prep.instant, coucher.subtract(const Duration(minutes: 5)));
    });

    test('Préparation du soir : décalage réglable (ex. 20 min)', () {
      final maintenant = DateTime(2026, 3, 20, 12, 0);
      final coucher = adapter.prochainCoucher(maintenant)!;
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
            type: TypeAlarme.preparationSoir,
            nom: 'Préparation du soir',
            message: AlarmPlanner.messagePreparationDefaut,
            minutesAvant: 20,
          ),
        ],
        maintenant: maintenant,
      );
      expect(plan.first.instant, coucher.subtract(const Duration(minutes: 20)));
    });

    test('RHEMA du soir : toujours ancré au coucher réel, quels que soient '
        'les réglages (norme biblique)', () {
      final maintenant = DateTime(2026, 3, 20, 12, 0);
      final coucher = adapter.prochainCoucher(maintenant)!;
      final plan = AlarmPlanner.planifier(
        adapter: adapter,
        alarmes: const [
          AlarmeSpirituelle(
            type: TypeAlarme.rhemaSoir,
            nom: 'RHEMA du soir',
            message: AlarmPlanner.messageSoirDefaut,
            heure: 9,
            minute: 9,
            minutesAvant: 42,
          ),
        ],
        maintenant: maintenant,
      );
      expect(plan.first.instant, coucher,
          reason: 'le RHEMA du soir ne peut pas être détaché du coucher');
    });
  });

  group('Détection de ruptures temporelles (§13)', () {
    test('aucune rupture en fonctionnement normal', () {
      final etat = EtatTemporel(
        horodatage: DateTime.now().subtract(const Duration(seconds: 30)),
        fuseau: TimeEngine.fuseauCourant(), // fuseau réel du moteur
        prochainCoucherCalcule: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(TimeEngine.detecterRupture(dernierEtat: etat), isNull);
    });

    test('changement de fuseau détecté', () {
      final etat = EtatTemporel(
        horodatage: DateTime.now().subtract(const Duration(seconds: 30)),
        fuseau: 'Europe/Paris',
      );
      final rupture = TimeEngine.detecterRupture(dernierEtat: etat);
      expect(rupture, isNotNull);
      expect(rupture!.motif, contains('fuseau'));
    });

    test('prochain coucher dépassé → recalcul', () {
      final etat = EtatTemporel(
        horodatage: DateTime.now().subtract(const Duration(hours: 10)),
        fuseau: TimeEngine.fuseauCourant(),
        prochainCoucherCalcule: DateTime.now().subtract(const Duration(hours: 1)),
      );
      final rupture = TimeEngine.detecterRupture(dernierEtat: etat);
      expect(rupture, isNotNull);
      expect(rupture!.motif, contains('recalcul'));
    });

    test('saut temporel détecté (reprise après des heures)', () {
      final etat = EtatTemporel(
        horodatage: DateTime.now().subtract(const Duration(minutes: 90)),
        fuseau: TimeEngine.fuseauCourant(),
      );
      final rupture = TimeEngine.detecterRupture(dernierEtat: etat);
      expect(rupture, isNotNull);
    });

    test('premier lancement : aucun état → aucune rupture à signaler', () {
      expect(TimeEngine.detecterRupture(dernierEtat: null), isNull);
    });
  });
}
