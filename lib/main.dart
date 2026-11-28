/// Point d'entrée de Horloge Céleste — Le temps de l’alliance de l’Éternel (Yeshua Calendar).
///
/// Initialisation :
///   1. persistance (shared_preferences) avant tout calcul ;
///   2. observer du cycle de vie (reprise §13) ;
///   3. notifications natives (alarmes spirituelles §8) ;
///   4. application Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/app/cycle_app.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_alarm_engine.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistance d'abord : position, préférences, état temporel (§13).
  await SettingsStore.instance.initialiser();

  // PREMIER LANCEMENT — détection automatique du PAYS via le fuseau IANA
  // du téléphone (§9.1) : le coucher du soleil — donc la BASCULE DE LA
  // DATE BIBLIQUE au coucher — est correct pour le pays de l'utilisateur
  // dès la toute première ouverture, avant même le choix d'une ville.
  // Aucun écrasement d'une position déjà choisie : uniquement si aucune
  // position n'a jamais été enregistrée.
  if (!SettingsStore.instance.positionEstConfiguree()) {
    try {
      final detectee = await LocationService.instance.positionDepuisFuseau();
      if (detectee != null) {
        await SettingsStore.instance.sauvegarderPosition(detectee);
      }
    } catch (_) {
      // Détection impossible : la position par défaut reste en place —
      // l'utilisateur choisira son pays dans Réglages.
    }
  }
  SettingsStore.instance.marquerPremierLancement();

  // Observer racine du cycle de vie — reprise = recalcul complet.
  AppCycleLiaison.instance.attacher();

  // Notifications natives des 3 alarmes (silencieux si refusées).
  await NotificationService.instance.initialiser();
  NotificationService.instance.onTapNotification = (payload, titre, corps) {
    // L'ouverture depuis une sonnerie atterrit sur l'app ; l'historique
    // local garde la trace de chaque alarme touchée (§8.4).
    PrayerAlarmEngine.instance
        .enregistrerNotificationRecue(titre ?? payload, corps ?? '');
  };

  runApp(const ProviderScope(child: HorlogeCelesteApp()));
}
