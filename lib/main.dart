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
import 'services/notification_service.dart';
import 'services/prayer_alarm_engine.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistance d'abord : position, préférences, état temporel (§13).
  await SettingsStore.instance.initialiser();

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
