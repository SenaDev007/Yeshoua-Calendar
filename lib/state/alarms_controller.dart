/// ⭐ ALARMS CONTROLLER — état des alarmes spirituelles (§8).
///
/// Expose : les 3 alarmes et leurs préférences, les prochains instants
/// planifiés (calculés par AlarmPlanner), l'historique des notifications,
/// et déclenche la reprogrammation native à chaque changement.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../services/prayer_alarm_engine.dart';
import '../services/settings_store.dart';
import 'horloge_controller.dart';

/// Une alarme telle qu'affichée dans l'écran Alarmes.
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

class AlarmsState {
  final List<AlarmeAffichee> alarmes;
  final List<Map<String, dynamic>> historique;
  final String? message;

  const AlarmsState({
    required this.alarmes,
    required this.historique,
    this.message,
  });

  AlarmsState copyWith({String? message}) =>
      AlarmsState(alarmes: alarmes, historique: historique, message: message);
}

class AlarmsController extends Notifier<AlarmsState> {
  @override
  AlarmsState build() {
    final store = SettingsStore.instance;
    final etatHorloge = ref.watch(horlogeProvider);
    final adapter = _adapterDepuis(etatHorloge);

    final prefsMatin = store.alarme(
        SettingsStore.cleAlarmeMatin, AlarmPlanner.messageMatinDefaut);
    final prefsPreparation = store.alarme(SettingsStore.cleAlarmePreparation,
        AlarmPlanner.messagePreparationDefaut);
    final prefsSoir =
        store.alarme(SettingsStore.cleAlarmeSoir, AlarmPlanner.messageSoirDefaut);

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

    // Reprogrammation native si nécessaire (démarrage / changement).
    PrayerAlarmEngine.instance.reprogrammer(adapter: adapter);

    return AlarmsState(
      alarmes: alarmes,
      historique: store.historiqueNotifications(),
    );
  }

  BiblicalCalendarAdapter _adapterDepuis(HorlogeState etat) =>
      BiblicalCalendarAdapter(
        latitude: etat.position.latitude,
        longitude: etat.position.longitude,
      );

  /// Active / désactive une alarme puis reprogramme nativement (§8.4).
  Future<void> basculer(AlarmeAffichee alarme, bool valeur) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(activee: valeur));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuis(ref.read(horlogeProvider)), forcer: true);
  }

  /// Change le message personnalisé d'une alarme (§8.4), puis reprogramme
  /// pour que le nouveau message s'applique dès la prochaine sonnerie.
  Future<void> changerMessage(AlarmeAffichee alarme, String message) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(message: message));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuis(ref.read(horlogeProvider)), forcer: true);
  }

  /// Change l'HEURE d'une alarme à heure fixe (RHEMA du matin — §8.4),
  /// puis reprogramme immédiatement.
  Future<void> changerHeure(AlarmeAffichee alarme, int heure, int minute) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(heure: heure, minute: minute));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuis(ref.read(horlogeProvider)), forcer: true);
  }

  /// Change le décalage en minutes avant le coucher réel (Préparation du
  /// soir — §8.4), puis reprogramme immédiatement.
  Future<void> changerMinutesAvant(AlarmeAffichee alarme, int minutes) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(minutesAvant: minutes));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuis(ref.read(horlogeProvider)), forcer: true);
  }

  /// Change la vibration / le son d'une alarme (§8.4).
  Future<void> changerPreferences(AlarmeAffichee alarme,
      {bool? vibration, String? son}) async {
    final store = SettingsStore.instance;
    final prefs = store.alarme(alarme.cle, alarme.prefs.message);
    await store.sauvegarderAlarme(
        alarme.cle, prefs.copyWith(vibration: vibration, son: son));
    await PrayerAlarmEngine.instance.reprogrammer(
        adapter: _adapterDepuis(ref.read(horlogeProvider)), forcer: true);
  }

  /// Enregistre une notification reçue dans l'historique (§8.4).
  Future<void> notifierRecue(String titre, String corps) async {
    await PrayerAlarmEngine.instance.enregistrerNotificationRecue(titre, corps);
  }
}

/// Provider des alarmes.
final alarmsProvider =
    NotifierProvider<AlarmsController, AlarmsState>(AlarmsController.new);
