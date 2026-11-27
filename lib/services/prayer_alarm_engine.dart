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
        nom: 'RHEMA du matin — 05 h 00',
        message: prefs.matin.message.isEmpty
            ? AlarmPlanner.messageMatinDefaut
            : prefs.matin.message,
        activee: prefs.matin.activee,
        vibration: prefs.matin.vibration,
        son: prefs.matin.son,
      ),
      AlarmeSpirituelle(
        type: TypeAlarme.preparationSoir,
        nom: 'Préparation du soir — 5 min avant le coucher',
        message: prefs.preparation.message.isEmpty
            ? AlarmPlanner.messagePreparationDefaut
            : prefs.preparation.message,
        activee: prefs.preparation.activee,
        vibration: prefs.preparation.vibration,
        son: prefs.preparation.son,
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
