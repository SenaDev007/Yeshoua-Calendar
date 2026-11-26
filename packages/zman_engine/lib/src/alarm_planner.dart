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

enum TypeAlarme { rhemaMatin, preparationSoir, rhemaSoir }

/// Définition utilisateur d'une alarme.
class AlarmeSpirituelle {
  final TypeAlarme type;
  final String nom;
  final String message;
  final bool activee;
  final bool vibration;
  final String son;

  const AlarmeSpirituelle({
    required this.type,
    required this.nom,
    required this.message,
    this.activee = true,
    this.vibration = true,
    this.son = 'shofar',
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

class AlarmPlanner {
  AlarmPlanner._();

  /// Identifiants stables des notifications (flutter_local_notifications).
  static const int idRhemaMatin = 11;
  static const int idPreparationSoir = 12;
  static const int idRhemaSoir = 13;

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
  static List<AlarmePlanifiee> planifier({
    required BiblicalCalendarAdapter adapter,
    required List<AlarmeSpirituelle> alarmes,
    required DateTime maintenant,
    int minutesAvantPreparation = 5,
  }) {
    final resultats = <AlarmePlanifiee>[];

    for (final alarme in alarmes) {
      if (!alarme.activee) continue;
      switch (alarme.type) {
        case TypeAlarme.rhemaMatin:
          resultats.add(AlarmePlanifiee(
            type: alarme.type,
            nom: alarme.nom,
            instant: prochainRhemaMatin(maintenant),
            message: alarme.message,
            vibration: alarme.vibration,
            son: alarme.son,
            id: idsNotification[alarme.type]!,
          ));
          break;
        case TypeAlarme.preparationSoir:
          final coucher = adapter.prochainCoucher(maintenant);
          if (coucher != null) {
            final instant =
                coucher.subtract(Duration(minutes: minutesAvantPreparation));
            if (instant.isAfter(maintenant)) {
              resultats.add(AlarmePlanifiee(
                type: alarme.type,
                nom: alarme.nom,
                instant: instant,
                message: alarme.message,
                vibration: alarme.vibration,
                son: alarme.son,
                id: idsNotification[alarme.type]!,
              ));
            }
          }
          break;
        case TypeAlarme.rhemaSoir:
          final coucher = adapter.prochainCoucher(maintenant);
          if (coucher != null && coucher.isAfter(maintenant)) {
            resultats.add(AlarmePlanifiee(
              type: alarme.type,
              nom: alarme.nom,
              instant: coucher,
              message: alarme.message,
              vibration: alarme.vibration,
              son: alarme.son,
              id: idsNotification[alarme.type]!,
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
}
