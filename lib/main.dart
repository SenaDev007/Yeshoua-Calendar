/// Point d'entrée de ZMAN — Le temps selon les Écritures (Yeshua Calendar).
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
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Persistance d'abord : position, préférences, état temporel (§13).
  await SettingsStore.instance.initialiser();

  // Observer racine du cycle de vie — reprise = recalcul complet.
  AppCycleLiaison.instance.attacher();

  // Notifications natives des 3 alarmes (silencieux si refusées).
  await NotificationService.instance.initialiser();
  NotificationService.instance.onTapNotification = (payload) {
    // L'ouverture depuis une notification RHEMA atterrit sur l'accueil ;
    // l'historique est rempli par le récepteur de notifications.
  };

  runApp(const ProviderScope(child: ZmanApp()));
}
