/// ⭐ ALARMS CONTROLLER — état des alarmes spirituelles (§8, §8.5).
///
/// Expose : les RHEMA du matin et du soir, les ALARMES PERSONNALISÉES
/// (heure et tâche libres — §8.5), les prochains instants planifiés
/// (calculés par AlarmPlanner), l'historique des notifications.
///
/// « PRÉPARATION DU SOIR » SUPPRIMÉE (demande utilisateur v1.0.7) : la
/// carte ne s'affiche plus et n'est plus programmée — il reste le RHEMA du
/// matin, le RHEMA du soir et les alarmes personnalisées.
///
/// RÉACTIVITÉ (§8.4 — défaut « il faut rouvrir l'app » corrigé) : chaque
/// mutation (bascule, heure, son, message, création, suppression) affecte
/// l'état DIRECTEMENT (state = …) IMMÉDIATEMENT après la sauvegarde —
/// même si la replanification native échoue (l'ancienne version appelait
/// ref.invalidateSelf() APRÈS l'attente des appels natifs : une exception
/// silencieuse laissait l'interface figée jusqu'au redémarrage).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../services/prayer_alarm_engine.dart';
import '../services/settings_store.dart';
import '../services/wallpaper_service.dart';
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
    // RECONSTRUCTION CIBLÉE : uniquement au changement de JOUR biblique
    // (coucher réel — le bon moment pour replanifier les couchers suivants)
    // ou de POSITION.
    ref.watch(horlogeProvider
        .select((etat) => (etat.position.libelle, etat.jourBiblique?.jourDeAnnee)));

    // REPROGRAMMATION NATIVE en arrière-plan (démarrage / changement de
    // jour / position) — ne bloque JAMAIS la construction de l'interface.
    unawaited(_replanifierArrierePlan(forcer: false));

    return _construireEtat();
  }

  BiblicalCalendarAdapter _adapter() {
    final position = SettingsStore.instance.position();
    return BiblicalCalendarAdapter(
        latitude: position.latitude, longitude: position.longitude);
  }

  /// CONSTRUCTION COMPLÈTE de l'état depuis le store — pure lecture,
  /// sans effet de bord : appelée par build() ET par chaque mutation.
  AlarmsState _construireEtat() {
    final store = SettingsStore.instance;
    final adapter = _adapter();

    final prefsMatin = store.alarme(
        SettingsStore.cleAlarmeMatin, AlarmPlanner.messageMatinDefaut);
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

    return AlarmsState(
      alarmes: alarmes,
      personnalisees: personnalisees,
      historique: store.historiqueNotifications(),
    );
  }

  /// AFFECTE l'état reconstruit — l'interface se met à jour INSTANTANÉMENT.
  /// Toute erreur est contenue : la mutation ne peut plus laisser l'écran
  /// figé (défaut « rouvrir l'application » corrigé).
  void _rafraichirEtat() {
    try {
      state = _construireEtat();
    } catch (_) {
      // Reconstruction impossible (cas extrême) : l'état actuel reste
      // affiché — jamais de crash d'interface pour un rafraîchissement.
    }
  }

  /// Replanification native en arrière-plan + instantané du verrouillage.
  Future<void> _replanifierArrierePlan({required bool forcer}) async {
    try {
      await PrayerAlarmEngine.instance.reprogrammer(
          adapter: _adapter(), forcer: forcer);
    } catch (_) {
      // L'interface reste à jour même si les appels natifs échouent — la
      // prochaine replanification (démarrage, changement de jour) retente.
    }
    unawaited(WallpaperService.actualiserSnapshot());
  }

  /// Active / désactive une alarme puis replanifie nativement (§8.4).
  Future<void> basculer(AlarmeAffichee alarme, bool valeur) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(alarme.cle, prefs.copyWith(activee: valeur));
    _rafraichirEtat(); // Interrupteur réactif — sans attendre le natif.
    await _replanifierArrierePlan(forcer: true);
  }

  /// Change le message personnalisé d'une alarme (§8.4).
  Future<void> changerMessage(AlarmeAffichee alarme, String message) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(alarme.cle, prefs.copyWith(message: message));
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
  }

  /// Change l'HEURE d'une alarme à heure fixe (RHEMA du matin — §8.4).
  Future<void> changerHeure(
      AlarmeAffichee alarme, int heure, int minute) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(heure: heure, minute: minute));
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
  }

  /// Change la vibration / le son d'une alarme (§8.4) — affichage instantané.
  Future<void> changerPreferences(AlarmeAffichee alarme,
      {bool? vibration, String? son}) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(vibration: vibration, son: son));
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
  }

  // ── Alarmes PERSONNALISÉES (§8.5) ──────────────────────────────────

  /// Crée une alarme personnalisée (heure libre + tâche) : sauvegarde,
  /// AFFICHAGE IMMÉDIAT dans la liste, puis planification native.
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
    _rafraichirEtat(); // La nouvelle alarme apparaît AUSSI TÔT.
    await _replanifierArrierePlan(forcer: true);
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
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
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
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
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
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
  }

  /// Supprime une alarme personnalisée (les notifications natives sont
  /// replanifiées — l'alarme supprimée disparaît de la planification).
  Future<void> supprimerPersonnalisee(int id) async {
    final store = SettingsStore.instance;
    final alarmes =
        store.alarmesPersonnalisees().where((a) => a.id != id).toList();
    await store.sauvegarderAlarmesPersonnalisees(alarmes);
    _rafraichirEtat();
    await _replanifierArrierePlan(forcer: true);
  }

  /// Enregistre une notification reçue dans l'historique (§8.4).
  Future<void> notifierRecue(String titre, String corps) async {
    await PrayerAlarmEngine.instance.enregistrerNotificationRecue(titre, corps);
    _rafraichirEtat();
  }
}

/// Provider des alarmes.
final alarmsProvider =
    NotifierProvider<AlarmsController, AlarmsState>(AlarmsController.new);
