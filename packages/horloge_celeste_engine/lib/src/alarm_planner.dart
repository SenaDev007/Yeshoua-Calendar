/// ⭐ ALARM PLANNER — PHASE 7 du cahier des charges (§8).
///
/// Planification des TROIS ALARMES SPIRITUELLES (logique pure, testable) :
///   1. RHEMA du matin — 05 h 00 locales, rendez-vous de prière ;
///   2. Préparation du soir — 5 minutes avant le coucher du soleil réel ;
///   3. RHEMA du soir — au coucher du soleil réel (commencement du
///      nouveau jour biblique).
///
/// Les horaires du soir sont recalculés CHAQUE JOUR à partir du
/// SolarEngine : jamais programmés à une heure fixe (§18). La
/// reprogrammation après redémarrage / changement de localisation est
/// orchestrée par `PrayerAlarmEngine` côté app (flutter_local_notifications).
library;

import 'biblical_calendar_adapter.dart';
import 'models.dart';

enum TypeAlarme { rhemaMatin, preparationSoir, rhemaSoir }

/// Définition utilisateur d'une alarme.
class AlarmeSpirituelle {
  final TypeAlarme type;
  final String nom;
  final String message;
  final bool activee;
  final bool vibration;
  final String son;

  /// RHEMA DU MATIN uniquement — heure locale choisie par l'utilisateur
  /// (défaut biblique 05 h 00 ; réglable, jamais figée §8.4).
  final int heure;
  final int minute;

  /// PRÉPARATION DU SOIR uniquement — minutes avant le coucher réel
  /// (défaut 5 ; réglable §8.4).
  final int minutesAvant;

  const AlarmeSpirituelle({
    required this.type,
    required this.nom,
    required this.message,
    this.activee = true,
    this.vibration = true,
    this.son = 'shofar',
    this.heure = 5,
    this.minute = 0,
    this.minutesAvant = 5,
  });
}

/// Une alarme planifiée pour un instant précis.
class AlarmePlanifiee {
  final TypeAlarme type;
  final String nom;
  final DateTime instant;
  final String message;
  final bool vibration;
  final String son;
  final int id;

  const AlarmePlanifiee({
    required this.type,
    required this.nom,
    required this.instant,
    required this.message,
    required this.vibration,
    required this.son,
    required this.id,
  });
}

/// Une notification SHOFAR planifiée — entrée du Shabbat ou d'une fête
/// de l'Éternel au coucher du soleil réel, ou rappel d'approche
/// (J-7 / J-3 / J-24 h). Miroir des `EvenementShofar` du backend.
class ShofarPlanifie {
  final int id;
  final DateTime instant;
  final String titre;
  final String corps;
  final String payload;
  final String son;
  final bool vibration;

  const ShofarPlanifie({
    required this.id,
    required this.instant,
    required this.titre,
    required this.corps,
    required this.payload,
    this.son = 'shofar',
    this.vibration = true,
  });
}

class AlarmPlanner {
  AlarmPlanner._();

  /// Identifiants stables des notifications (flutter_local_notifications).
  static const int idRhemaMatin = 11;
  static const int idPreparationSoir = 12;
  static const int idRhemaSoir = 13;

  /// Plage des identifiants SHOFAR : entrées de Shabbats/fêtes à partir de
  /// 100, rappels de fêtes à partir de 400 — hors des identifiants RHEMA.
  static const int idShofarBase = 100;
  static const int idRappelsBase = 400;

  /// Alarmes du soir ÉTENDUES aux jours suivants (30 = préparation,
  /// 50 = RHEMA du soir) : le coucher du soleil variant chaque jour, une
  /// notification séparée par jour garantit la sonnerie même si
  /// l'application reste fermée plusieurs jours.
  static const int idPreparationSoirJoursBase = 30;
  static const int idRhemaSoirJoursBase = 50;

  static const Map<TypeAlarme, int> idsNotification = {
    TypeAlarme.rhemaMatin: idRhemaMatin,
    TypeAlarme.preparationSoir: idPreparationSoir,
    TypeAlarme.rhemaSoir: idRhemaSoir,
  };

  /// Messages par défaut (§8).
  static const String messageMatinDefaut =
      'RHEMA du matin — votre rendez-vous de prière et de communion avec le Père vous attend.';
  static const String messagePreparationDefaut =
      'Dans 5 minutes, le soleil se couche : préparez-vous à entrer dans le nouveau jour biblique.';
  static const String messageSoirDefaut =
      'RHEMA du soir — le soleil se couche, le nouveau jour biblique commence. Shalom !';

  /// Prochaine occurrence du RHEMA du matin (05 h 00 local).
  ///
  /// Si 05 h 00 est déjà passé aujourd'hui, planifie demain.
  static DateTime prochainRhemaMatin(DateTime maintenant, {int heure = 5, int minute = 0}) {
    var cible =
        DateTime(maintenant.year, maintenant.month, maintenant.day, heure, minute);
    if (!cible.isAfter(maintenant)) {
      cible = cible.add(const Duration(days: 1));
    }
    return cible;
  }

  /// Prochain instant du coucher du soleil (via l'adapter).
  static DateTime? prochainCoucher(BiblicalCalendarAdapter adapter, DateTime maintenant) =>
      adapter.prochainCoucher(maintenant);

  /// Planifie les trois alarmes pour le cycle courant.
  ///
  /// Retourne uniquement les alarmes ACTIVÉES. Les deux alarmes du soir
  /// sont ancrées sur le coucher du soleil RÉEL (adapté à la position) ;
  /// si le calcul solaire est impossible (région polaire), elles sont
  /// simplement omises — JAMAIS remplacées par une heure fictive (§9.4).
  ///
  /// [horizonJours] : nombre de JOURS couverts pour les alarmes du soir
  /// (1 par défaut — compatibilité exacte du comportement historique).
  /// Avec 7, chaque coucher des 7 prochains jours reçoit SA notification
  /// (identifiants distincts) : les sonneries restent armées même si
  /// l'application n'est pas rouverte entre-temps.
  static List<AlarmePlanifiee> planifier({
    required BiblicalCalendarAdapter adapter,
    required List<AlarmeSpirituelle> alarmes,
    required DateTime maintenant,
    int horizonJours = 1,
  }) {
    final resultats = <AlarmePlanifiee>[];

    // Coucher du soleil du [jour]ème jour à venir (0 = prochain après
    // maintenant) — dédoublonné par jour civil pour ne jamais sonner deux
    // fois le même coucher.
    DateTime? coucherDuJour(int jour, Set<DateTime> dejaVus) {
      final coucher = jour == 0
          ? adapter.prochainCoucher(maintenant)
          : adapter.prochainCoucher(DateTime(maintenant.year,
              maintenant.month, maintenant.day).add(Duration(days: jour)));
      if (coucher == null) return null;
      final cle = DateTime(coucher.year, coucher.month, coucher.day);
      if (dejaVus.contains(cle)) return null;
      dejaVus.add(cle);
      return coucher;
    }

    for (final alarme in alarmes) {
      if (!alarme.activee) continue;
      switch (alarme.type) {
        case TypeAlarme.rhemaMatin:
          resultats.add(AlarmePlanifiee(
            type: alarme.type,
            nom: alarme.nom,
            // Heure choisie par l'utilisateur (05 h 00 par défaut).
            instant: prochainRhemaMatin(maintenant,
                heure: alarme.heure, minute: alarme.minute),
            message: alarme.message,
            vibration: alarme.vibration,
            son: alarme.son,
            id: idsNotification[alarme.type]!,
          ));
          break;
        case TypeAlarme.preparationSoir:
          final dejaVus = <DateTime>{};
          for (var jour = 0; jour < horizonJours; jour++) {
            final coucher = coucherDuJour(jour, dejaVus);
            if (coucher == null) continue;
            final instant =
                coucher.subtract(Duration(minutes: alarme.minutesAvant));
            if (!instant.isAfter(maintenant)) continue;
            resultats.add(AlarmePlanifiee(
              type: alarme.type,
              nom: alarme.nom,
              instant: instant,
              message: alarme.message,
              vibration: alarme.vibration,
              son: alarme.son,
              id: jour == 0
                  ? idPreparationSoir
                  : idPreparationSoirJoursBase + jour,
            ));
          }
          break;
        case TypeAlarme.rhemaSoir:
          final dejaVus = <DateTime>{};
          for (var jour = 0; jour < horizonJours; jour++) {
            final coucher = coucherDuJour(jour, dejaVus);
            if (coucher == null || !coucher.isAfter(maintenant)) continue;
            resultats.add(AlarmePlanifiee(
              type: alarme.type,
              nom: alarme.nom,
              instant: coucher,
              message: alarme.message,
              vibration: alarme.vibration,
              son: alarme.son,
              id: jour == 0 ? idRhemaSoir : idRhemaSoirJoursBase + jour,
            ));
          }
          break;
      }
    }

    resultats.sort((a, b) => a.instant.compareTo(b.instant));
    return resultats;
  }

  /// Historique des dernières notifications (§8.4 — l'app persiste).
  static String cleHistorique(DateTime instant, TypeAlarme type) =>
      'alarme-${type.name}-${instant.toIso8601String()}';

  /// ── SHOFAR : entrée du Shabbat et des fêtes + rappels d'approche ────
  ///
  /// À l'entrée de chaque Shabbat (coucher du soleil du vendredi) et de
  /// chaque fête de l'Éternel (coucher du soleil de la veille du jour
  /// biblique), le shofar retentit. Pour chaque FÊTE, des rappels sont
  /// émis à J-7, J-3 et J-24 h — instants qui tombent eux-mêmes au
  /// coucher du soleil (l'entrée étant un coucher, les jalons sont des
  /// couchers décalés). Les jalons déjà passés sont omis.
  static List<ShofarPlanifie> planifierShofar({
    required List<EvenementShofar> evenements,
    required DateTime maintenant,
    bool vibration = true,
    String son = 'shofar',
  }) {
    final resultats = <ShofarPlanifie>[];
    var idxEntree = 0;
    var idxRappel = 0;

    final tries = [...evenements]
      ..sort((a, b) => a.entree.compareTo(b.entree));

    for (final e in tries) {
      if (e.entree.isAfter(maintenant)) {
        final estShabbat = e.type == 'shabbat';
        resultats.add(ShofarPlanifie(
          id: idShofarBase + idxEntree++,
          instant: e.entree,
          titre: estShabbat
              ? 'Shofar — entrée du Shabbat'
              : 'Shofar — entrée de ${e.titre}',
          corps: estShabbat
              ? "Le soleil se couche : le Shabbat commence. Sainte convocation, repos et joie (Lévitique 23:3). Shalom !"
              : "${e.titre} commence maintenant, au coucher du soleil. "
                  "Le shofar retentit pour la sainte convocation. Shalom !",
          payload: estShabbat ? 'shofar_shabbat' : 'shofar_fete',
          son: son,
          vibration: vibration,
        ));
      }

      if (e.type != 'fete') continue;
      for (final jalon in e.jalons) {
        if (!jalon.date.isAfter(maintenant)) continue;
        resultats.add(ShofarPlanifie(
          id: idRappelsBase + idxRappel++,
          instant: jalon.date,
          titre: 'Rappel — ${e.titre} dans ${jalon.label}',
          corps: jalon.cle == 'j24h'
              ? "${e.titre} commence dans 24 heures : le shofar retentira "
                  "au coucher du soleil marquant son entrée."
              : "${e.titre} approche : dans ${jalon.label}, le shofar "
                  "retentira au coucher du soleil marquant son entrée.",
          payload: 'rappel_${jalon.cle}',
          son: son,
          vibration: vibration,
        ));
      }
    }

    resultats.sort((a, b) => a.instant.compareTo(b.instant));
    return resultats;
  }
}
