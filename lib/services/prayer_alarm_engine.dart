/// ⭐ PRAYER ALARM ENGINE — PHASE 7 (§8.4).
///
/// Orchestration des trois alarmes : planification via [AlarmPlanner]
/// (moteur testé), envoi vers les notifications natives, historique et
/// reprogrammation. Reprogrammation déclenchée :
///   • une fois par jour (après le RHEMA du soir, au prochain tick) ;
///   • après un changement de localisation ;
///   • au démarrage de l'application (redémarrage du téléphone) ;
///   • à chaque reprise après plusieurs heures (rupture temporelle §13).
library;

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import 'notification_service.dart';
import 'settings_store.dart';

class PrayerAlarmEngine {
  PrayerAlarmEngine._();
  static final PrayerAlarmEngine instance = PrayerAlarmEngine._();

  DateTime? _derniereProgrammation;
  String? _dernierePositionUtilisee;

  /// Reprogramme les alarmes ACTIVÉES à partir de la position et du moteur.
  ///
  /// [forcer] : ignore les conditions de fraîcheur (changement de position,
  /// démarrage, rupture temporelle).
  Future<void> reprogrammer({
    required BiblicalCalendarAdapter adapter,
    bool forcer = false,
  }) async {
    final store = SettingsStore.instance;
    final position = store.position();
    final maintenant = DateTime.now();

    // Fraîcheur : ne replanifie pas plus d'une fois par heure sauf demande
    // explicite (économise les API de notifications, §18 performances).
    if (!forcer &&
        _derniereProgrammation != null &&
        maintenant.difference(_derniereProgrammation!) <
            const Duration(hours: 1) &&
        _dernierePositionUtilisee == position.libelle) {
      return;
    }

    final prefs = _prefsDepuisStore(store);

    final alarmes = [
      AlarmeSpirituelle(
        type: TypeAlarme.rhemaMatin,
        nom: prefs.matin.heure == 5 && prefs.matin.minute == 0
            ? 'RHEMA du matin — 05 h 00'
            : 'RHEMA du matin — '
                '${prefs.matin.heure.toString().padLeft(2, '0')} h '
                '${prefs.matin.minute.toString().padLeft(2, '0')}',
        message: prefs.matin.message.isEmpty
            ? AlarmPlanner.messageMatinDefaut
            : prefs.matin.message,
        activee: prefs.matin.activee,
        vibration: prefs.matin.vibration,
        son: prefs.matin.son,
        heure: prefs.matin.heure,
        minute: prefs.matin.minute,
        minutesAvant: prefs.matin.minutesAvant,
      ),
      AlarmeSpirituelle(
        type: TypeAlarme.preparationSoir,
        nom: 'Préparation du soir — ${prefs.preparation.minutesAvant} min avant le coucher',
        message: prefs.preparation.message.isEmpty
            ? AlarmPlanner.messagePreparationDefaut
            : prefs.preparation.message,
        activee: prefs.preparation.activee,
        vibration: prefs.preparation.vibration,
        son: prefs.preparation.son,
        heure: prefs.preparation.heure,
        minute: prefs.preparation.minute,
        minutesAvant: prefs.preparation.minutesAvant,
      ),
      AlarmeSpirituelle(
        type: TypeAlarme.rhemaSoir,
        nom: 'RHEMA du soir — au coucher du soleil',
        message: prefs.soir.message.isEmpty
            ? AlarmPlanner.messageSoirDefaut
            : prefs.soir.message,
        activee: prefs.soir.activee,
        vibration: prefs.soir.vibration,
        son: prefs.soir.son,
        heure: prefs.soir.heure,
        minute: prefs.soir.minute,
        minutesAvant: prefs.soir.minutesAvant,
      ),
    ];

    final plan = AlarmPlanner.planifier(
      adapter: adapter,
      alarmes: alarmes,
      maintenant: maintenant,
    );

    // Reprise propre puis reprogrammation complète (évite les doublons).
    await NotificationService.instance.annulerTout();
    for (final a in plan) {
      if (a.type == TypeAlarme.rhemaMatin) {
        await NotificationService.instance.planifierRhemaMatin(
          id: a.id,
          titre: a.nom,
          corps: a.message,
          vibration: a.vibration,
          son: a.son,
          heure: prefs.matin.heure,
          minute: prefs.matin.minute,
        );
      } else {
        await NotificationService.instance.planifierOneShot(
          id: a.id,
          titre: a.nom,
          corps: a.message,
          instant: a.instant,
          vibration: a.vibration,
          son: a.son,
          payload: a.type == TypeAlarme.rhemaSoir ? 'rhema_soir' : 'preparation_soir',
        );
      }
    }

    // ── Shofar : entrée du Shabbat et des fêtes de l'Éternel, au coucher
    // du soleil réel + rappels J-7 / J-3 / J-24 h (jalons du moteur).
    // Toujours sonné au shofar (§18) — un confort de plus : en cas
    // d'imprévu (année indisponible), les RHEMA restent planifiés.
    try {
      final evenements = adapter.prochainsEvenementsShofar(maintenant);
      final shofars = AlarmPlanner.planifierShofar(
        evenements: evenements,
        maintenant: maintenant,
        son: 'shofar',
      );
      for (final s in shofars) {
        await NotificationService.instance.planifierOneShot(
          id: s.id,
          titre: s.titre,
          corps: s.corps,
          instant: s.instant,
          vibration: s.vibration,
          son: s.son,
          payload: s.payload,
        );
      }
    } catch (_) {
      // La planification des shofars ne doit jamais bloquer les RHEMA.
    }

    _derniereProgrammation = maintenant;
    _dernierePositionUtilisee = position.libelle;
  }

  /// Historique (§8.4) : l'app enregistre chaque notification reçue.
  Future<void> enregistrerNotificationRecue(String titre, String corps) =>
      SettingsStore.instance
          .ajouterHistorique(titre, corps, DateTime.now());

  _AlarmesPrefs _prefsDepuisStore(SettingsStore store) => _AlarmesPrefs(
        matin: store.alarme(
            SettingsStore.cleAlarmeMatin, AlarmPlanner.messageMatinDefaut),
        preparation: store.alarme(SettingsStore.cleAlarmePreparation,
            AlarmPlanner.messagePreparationDefaut),
        soir: store.alarme(
            SettingsStore.cleAlarmeSoir, AlarmPlanner.messageSoirDefaut),
      );
}

class _AlarmesPrefs {
  final AlarmePrefs matin;
  final AlarmePrefs preparation;
  final AlarmePrefs soir;

  const _AlarmesPrefs({
    required this.matin,
    required this.preparation,
    required this.soir,
  });
}
