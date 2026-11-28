/// ⭐ ALARMS CONTROLLER — état des alarmes spirituelles (§8, §8.5).
///
/// Expose : les 3 RHEMA et leurs préférences, les ALARMES PERSONNALISÉES
/// (heure et tâche libres — §8.5), les prochains instants planifiés
/// (calculés par AlarmPlanner), l'historique des notifications.
///
/// RÉACTIVITÉ (§8.4) : chaque mutation (bascule, heure, son, message,
/// création, suppression) reconstruit IMMÉDIATEMENT l'état — l'interface
/// réagit sans quitter ni rouvrir l'application (défaut corrigé).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../services/prayer_alarm_engine.dart';
import '../services/settings_store.dart';
import 'horloge_controller.dart';

/// Une alarme spirituelle (RHEMA) telle qu'affichée dans l'écran Alarmes.
class AlarmeAffichee {
  final TypeAlarme type;
  final String cle;
  final String nom;
  final String sousTitre;
  final AlarmePrefs prefs;
  final DateTime? prochainInstant;
  final String couleurHex;

  const AlarmeAffichee({
    required this.type,
    required this.cle,
    required this.nom,
    required this.sousTitre,
    required this.prefs,
    this.prochainInstant,
    required this.couleurHex,
  });
}

/// Une alarme PERSONNALISÉE telle qu'affichée (§8.5).
class PersonnaliseeAffichee {
  final int id;
  final String libelle;
  final AlarmePrefs prefs;
  final DateTime? prochainInstant;
  final String couleurHex;

  const PersonnaliseeAffichee({
    required this.id,
    required this.libelle,
    required this.prefs,
    this.prochainInstant,
    required this.couleurHex,
  });
}

class AlarmsState {
  final List<AlarmeAffichee> alarmes;
  final List<PersonnaliseeAffichee> personnalisees;
  final List<Map<String, dynamic>> historique;
  final String? message;

  const AlarmsState({
    required this.alarmes,
    this.personnalisees = const [],
    required this.historique,
    this.message,
  });

  AlarmsState copyWith({String? message}) => AlarmsState(
        alarmes: alarmes,
        personnalisees: personnalisees,
        historique: historique,
        message: message,
      );
}

class AlarmsController extends Notifier<AlarmsState> {
  @override
  AlarmsState build() {
    final store = SettingsStore.instance;
    // RECONSTRUCTION CIBLÉE : uniquement au changement de JOUR biblique
    // (coucher réel — le bon moment pour replanifier les couchers suivants)
    // ou de POSITION. Plus de reconstruction à chaque seconde : les appels
    // natifs de planification ne sont plus déclenchés en rafale.
    final (position, _) = ref.watch(horlogeProvider
        .select((etat) => (etat.position, etat.jourBiblique?.jourDeAnnee)));
    final adapter = BiblicalCalendarAdapter(
        latitude: position.latitude, longitude: position.longitude);

    final prefsMatin = store.alarme(
        SettingsStore.cleAlarmeMatin, AlarmPlanner.messageMatinDefaut);
    final prefsPreparation = store.alarme(SettingsStore.cleAlarmePreparation,
        AlarmPlanner.messagePreparationDefaut);
    final prefsSoir = store.alarme(
        SettingsStore.cleAlarmeSoir, AlarmPlanner.messageSoirDefaut);

    final maintenant = DateTime.now();
    final plan = AlarmPlanner.planifier(
      adapter: adapter,
      alarmes: [
        AlarmeSpirituelle(
            type: TypeAlarme.rhemaMatin,
            nom: 'RHEMA du matin',
            message: prefsMatin.message,
            activee: prefsMatin.activee),
        AlarmeSpirituelle(
            type: TypeAlarme.preparationSoir,
            nom: 'Préparation du soir',
            message: prefsPreparation.message,
            activee: prefsPreparation.activee),
        AlarmeSpirituelle(
            type: TypeAlarme.rhemaSoir,
            nom: 'RHEMA du soir',
            message: prefsSoir.message,
            activee: prefsSoir.activee),
      ],
      maintenant: maintenant,
    );
    DateTime? instant(TypeAlarme t) {
      for (final p in plan) {
        if (p.type == t) return p.instant;
      }
      return null;
    }

    final alarmes = [
      AlarmeAffichee(
        type: TypeAlarme.rhemaMatin,
        cle: SettingsStore.cleAlarmeMatin,
        nom: 'RHEMA du matin',
        sousTitre: 'Rendez-vous matinal de prière — '
            '${prefsMatin.heure.toString().padLeft(2, '0')} h '
            '${prefsMatin.minute.toString().padLeft(2, '0')} (réglable)',
        prefs: prefsMatin,
        prochainInstant: instant(TypeAlarme.rhemaMatin),
        couleurHex: '#3B82F6',
      ),
      AlarmeAffichee(
        type: TypeAlarme.preparationSoir,
        cle: SettingsStore.cleAlarmePreparation,
        nom: 'Préparation du soir',
        sousTitre: '${prefsPreparation.minutesAvant} minutes avant le '
            'coucher du soleil réel (réglable)',
        prefs: prefsPreparation,
        prochainInstant: instant(TypeAlarme.preparationSoir),
        couleurHex: '#CFA63A',
      ),
      AlarmeAffichee(
        type: TypeAlarme.rhemaSoir,
        cle: SettingsStore.cleAlarmeSoir,
        nom: 'RHEMA du soir',
        sousTitre: 'Au coucher du soleil — commencement du nouveau jour',
        prefs: prefsSoir,
        prochainInstant: instant(TypeAlarme.rhemaSoir),
        couleurHex: '#1E293B',
      ),
    ];

    // Alarmes PERSONNALISÉES (§8.5) — heure et tâche libres.
    final personnalisees = store
        .alarmesPersonnalisees()
        .map((p) => PersonnaliseeAffichee(
              id: p.id,
              libelle: p.libelle,
              prefs: p.prefs,
              prochainInstant: AlarmPlanner.prochainRhemaMatin(maintenant,
                  heure: p.prefs.heure, minute: p.prefs.minute),
              couleurHex: '#6B4FA1',
            ))
        .toList();

    // Reprogrammation native si nécessaire (démarrage / changement).
    // Sérialisée par PrayerAlarmEngine (voir reprogrammer).
    unawaited(PrayerAlarmEngine.instance.reprogrammer(adapter: adapter));

    return AlarmsState(
      alarmes: alarmes,
      personnalisees: personnalisees,
      historique: store.historiqueNotifications(),
    );
  }

  BiblicalCalendarAdapter _adapterDepuisPosition(
          PositionUtilisateur position) =>
      BiblicalCalendarAdapter(
        latitude: position.latitude,
        longitude: position.longitude,
      );

  /// Active / désactive une alarme puis reprogramme nativement (§8.4).
  /// L'ÉTAT EST RECONSTRUIT IMMÉDIATEMENT : l'interrupteur réagit sans
  /// quitter l'application (défaut corrigé).
  Future<void> basculer(AlarmeAffichee alarme, bool valeur) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(alarme.cle, prefs.copyWith(activee: valeur));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Change le message personnalisé d'une alarme (§8.4), puis reprogramme
  /// pour que le nouveau message s'applique dès la prochaine sonnerie.
  Future<void> changerMessage(AlarmeAffichee alarme, String message) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(alarme.cle, prefs.copyWith(message: message));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Change l'HEURE d'une alarme à heure fixe (RHEMA du matin — §8.4),
  /// puis reprogramme immédiatement — affichage instantané.
  Future<void> changerHeure(
      AlarmeAffichee alarme, int heure, int minute) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(heure: heure, minute: minute));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Change le décalage en minutes avant le coucher réel (Préparation du
  /// soir — §8.4), puis reprogramme immédiatement.
  Future<void> changerMinutesAvant(AlarmeAffichee alarme, int minutes) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(minutesAvant: minutes));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Change la vibration / le son d'une alarme (§8.4) — affichage instantané.
  Future<void> changerPreferences(AlarmeAffichee alarme,
      {bool? vibration, String? son}) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(vibration: vibration, son: son));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  // ── Alarmes PERSONNALISÉES (§8.5) ──────────────────────────────────

  /// Crée une alarme personnalisée (heure libre + tâche) et la planifie
  /// nativement (répétition quotidienne — §8.5).
  Future<void> ajouterPersonnalisee({
    required String libelle,
    required int heure,
    required int minute,
    required String son,
    required bool vibration,
  }) async {
    final store = SettingsStore.instance;
    final alarmes = [...store.alarmesPersonnalisees()];
    alarmes.add(AlarmePersonnalisee(
      id: store.prochainIdPersonnalisee(),
      libelle: libelle.isEmpty ? 'Alarme' : libelle,
      prefs: AlarmePrefs(
        activee: true,
        vibration: vibration,
        son: son,
        message: '',
        heure: heure,
        minute: minute,
      ),
    ));
    await store.sauvegarderAlarmesPersonnalisees(alarmes);
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Active / désactive une alarme personnalisée.
  Future<void> basculerPersonnalisee(int id, bool valeur) async {
    final store = SettingsStore.instance;
    final alarmes = [...store.alarmesPersonnalisees()];
    final i = alarmes.indexWhere((a) => a.id == id);
    if (i < 0) return;
    alarmes[i] = AlarmePersonnalisee(
        id: alarmes[i].id,
        libelle: alarmes[i].libelle,
        prefs: alarmes[i].prefs.copyWith(activee: valeur));
    await store.sauvegarderAlarmesPersonnalisees(alarmes);
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Change l'heure d'une alarme personnalisée.
  Future<void> changerHeurePersonnalisee(int id, int heure, int minute) async {
    final store = SettingsStore.instance;
    final alarmes = [...store.alarmesPersonnalisees()];
    final i = alarmes.indexWhere((a) => a.id == id);
    if (i < 0) return;
    alarmes[i] = AlarmePersonnalisee(
        id: alarmes[i].id,
        libelle: alarmes[i].libelle,
        prefs: alarmes[i].prefs.copyWith(heure: heure, minute: minute));
    await store.sauvegarderAlarmesPersonnalisees(alarmes);
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Change la vibration d'une alarme personnalisée.
  Future<void> changerVibrationPersonnalisee(int id, bool vibration) async {
    final store = SettingsStore.instance;
    final alarmes = [...store.alarmesPersonnalisees()];
    final i = alarmes.indexWhere((a) => a.id == id);
    if (i < 0) return;
    alarmes[i] = AlarmePersonnalisee(
        id: alarmes[i].id,
        libelle: alarmes[i].libelle,
        prefs: alarmes[i].prefs.copyWith(vibration: vibration));
    await store.sauvegarderAlarmesPersonnalisees(alarmes);
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Supprime une alarme personnalisée (les notifications natives sont
  /// replanifiées — l'alarme supprimée disparaît de la planification).
  Future<void> supprimerPersonnalisee(int id) async {
    final store = SettingsStore.instance;
    final alarmes =
        store.alarmesPersonnalisees().where((a) => a.id != id).toList();
    await store.sauvegarderAlarmesPersonnalisees(alarmes);
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuisPosition(ref.read(horlogeProvider).position),
        forcer: true);
    ref.invalidateSelf();
  }

  /// Enregistre une notification reçue dans l'historique (§8.4).
  Future<void> notifierRecue(String titre, String corps) async {
    await PrayerAlarmEngine.instance.enregistrerNotificationRecue(titre, corps);
    ref.invalidateSelf();
  }
}

/// Provider des alarmes.
final alarmsProvider =
    NotifierProvider<AlarmsController, AlarmsState>(AlarmsController.new);
