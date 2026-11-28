/// ⭐ PRAYER ALARM ENGINE — PHASE 7 (§8.4).
///
/// Orchestration des trois alarmes : planification via [AlarmPlanner]
/// (moteur testé), envoi vers les notifications natives, historique et
/// reprogrammation. Depuis v1.0.7 : deux RHEMA uniquement (la carte
/// « Préparation du soir » a été retirée à la demande de l'utilisateur).
/// Reprogrammation déclenchée :
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
  Future<void>? _reprogrammationEnCours;

  /// Reprogramme les alarmes ACTIVÉES à partir de la position et du moteur.
  ///
  /// [forcer] : ignore les conditions de fraîcheur (changement de position,
  /// démarrage, rupture temporelle).
  ///
  /// SÉCURISATION : les appels sont sérialisés — l'écoute du contrôleur
  /// d'alarmes pouvant déclencher cette méthode très fréquemment, deux
  /// exécutions simultanées s'annuleraient l'une l'autre en plein vol
  /// (cancelAll pendant les zonedSchedule). Les appels non forcés pendant
  /// une exécution en cours rejoignent simplement celle-ci.
  Future<void> reprogrammer({
    required BiblicalCalendarAdapter adapter,
    bool forcer = false,
  }) async {
    final enCours = _reprogrammationEnCours;
    if (enCours != null) {
      if (!forcer) return enCours;
      await enCours;
    }
    final execution = _reprogrammerInterne(adapter: adapter, forcer: forcer);
    _reprogrammationEnCours = execution;
    try {
      await execution;
    } finally {
      if (identical(_reprogrammationEnCours, execution)) {
        _reprogrammationEnCours = null;
      }
    }
  }

  Future<void> _reprogrammerInterne({
    required BiblicalCalendarAdapter adapter,
    required bool forcer,
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

    // « PRÉPARATION DU SOIR » SUPPRIMÉE (demande utilisateur v1.0.7) :
    // seuls le RHEMA du matin et le RHEMA du soir sont planifiés — plus
    // aucune notification « Préparation du soir » invisible.
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
      // HORIZON 7 JOURS (§8.4) : chaque coucher des 7 prochains jours
      // reçoit SA notification — la sonnerie reste armée même si
      // l'application n'est pas rouverte entre-temps. Le RHEMA du matin,
      // lui, se répète quotidiennement (matchDateTimeComponents).
      horizonJours: 7,
    );

    // Reprise propre puis reprogrammation complète (évite les doublons).
    // annulerTout est PROTÉGÉ : un échec ici ne doit jamais interrompre la
    // reprogrammation (l'ancien code laissait une exception remonter
    // jusqu'aux mutations de l'interface — alarmes non planifiées ET
    // interface figée jusqu'au redémarrage, défaut constaté v1.0.6+7 :
    // alarme de 13 h 14 jamais sonnée).
    try {
      await NotificationService.instance.annulerTout();
    } catch (_) {
      // Les zonedSchedule suivants écraseront de toute façon les mêmes IDs.
    }
    for (final a in plan) {
      try {
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
            payload: a.type == TypeAlarme.rhemaSoir
                ? 'rhema_soir'
                : 'alarme_soir',
          );
        }
      } catch (_) {
        // Une alarme qui échoue ne doit jamais bloquer les autres — la
        // reprogrammation suivante (démarrage, changement de jour,
        // changement de position) retente.
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
        try {
          await NotificationService.instance.planifierOneShot(
            id: s.id,
            titre: s.titre,
            corps: s.corps,
            instant: s.instant,
            vibration: s.vibration,
            son: s.son,
            payload: s.payload,
          );
        } catch (_) {
          // Sonnerie suivante.
        }
      }

      // ── RAPPEL SHABBAT J-24 h (§8.5 — demande utilisateur) : 24 heures
      // avant l'entrée de CHAQUE Shabbat, une notification d'approche —
      // miroir des jalons J-7 / J-3 / J-24 h des fêtes, ajouté ici (couche
      // app) pour préserver les tests du moteur.
      var idxRappelShabbat = 600;
      for (final e in evenements) {
        if (e.type != 'shabbat') continue;
        final jalon = e.entree.subtract(const Duration(hours: 24));
        if (!jalon.isAfter(maintenant)) continue;
        try {
          await NotificationService.instance.planifierOneShot(
            id: idxRappelShabbat++,
            titre: 'Rappel — Shabbat dans 24 heures',
            corps: 'Le Shabbat commence dans 24 heures, au coucher du '
                'soleil : préparez-vous à entrer dans le repos de '
                'l\u2019Éternel. Shalom !',
            instant: jalon,
            vibration: true,
            son: 'shofar',
            payload: 'rappel_shabbat_j24h',
          );
        } catch (_) {
          // Rappel suivant.
        }
      }
    } catch (_) {
      // La planification des shofars ne doit jamais bloquer les RHEMA.
    }

    // ── ALARMES PERSONNALISÉES (§8.5) : répétition quotidienne à l'heure
    // choisie — replanifiées à chaque cycle (annulerTout ci-dessus les a
    // effacées avec le reste).
    for (final p in store.alarmesPersonnalisees()) {
      if (!p.prefs.activee) continue;
      try {
        await NotificationService.instance.planifierPersonnalisee(
          id: p.id,
          titre: p.libelle,
          corps: p.prefs.message.isEmpty
              ? 'Rappel — ${p.libelle}. Shalom !'
              : p.prefs.message,
          vibration: p.prefs.vibration,
          son: p.prefs.son,
          heure: p.prefs.heure,
          minute: p.prefs.minute,
        );
      } catch (_) {
        // Une alarme personnalisée en échec ne bloque pas les autres.
      }
    }

    _derniereProgrammation = maintenant;
    _dernierePositionUtilisee = position.libelle;
  }

  /// Historique (§8.4) : l'app enregistre chaque notification reçue.
  Future<void> enregistrerNotificationRecue(String titre, String corps) =>
      SettingsStore.instance.ajouterHistorique(titre, corps, DateTime.now());

  _AlarmesPrefs _prefsDepuisStore(SettingsStore store) => _AlarmesPrefs(
        matin: store.alarme(
            SettingsStore.cleAlarmeMatin, AlarmPlanner.messageMatinDefaut),
        soir: store.alarme(
            SettingsStore.cleAlarmeSoir, AlarmPlanner.messageSoirDefaut),
      );
}

class _AlarmesPrefs {
  final AlarmePrefs matin;
  final AlarmePrefs soir;

  const _AlarmesPrefs({
    required this.matin,
    required this.soir,
  });
}
