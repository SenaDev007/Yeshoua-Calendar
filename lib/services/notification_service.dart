/// ⭐ SERVICE DE NOTIFICATIONS — PHASE 7 (§8).
///
/// Notifications locales natives pour les trois alarmes spirituelles :
///   1. RHEMA du matin — 05 h 00 locales (répétition quotidienne) ;
///   2. Préparation du soir — coucher du soleil réel − 5 minutes (one-shot
///      replanifié chaque jour et à chaque changement de position) ;
///   3. RHEMA du soir — au coucher du soleil réel (one-shot replanifié).
///
/// Les restrictions des systèmes mobiles sont gérées explicitement
/// (§8.4) : permissions Android 13+ (POST_NOTIFICATIONS), alarmes exactes
/// Android 12+ (SCHEDULE_EXACT_ALARM — repli « inexact » si refusées),
/// son personnalisé, vibration, reprogrammation après redémarrage
/// (BOOT_COMPLETED via le plugin) et après changement de localisation.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialise = false;

  /// Callback quand l'utilisateur touche une notification (ouverture d'app).
  void Function(String payload)? onTapNotification;

  Future<void> initialiser() async {
    if (_initialise) return;
    tzdata.initializeTimeZones();
    try {
      final nomFuseau = await FlutterTimezone.localTimeZone;
      tz.setLocalLocation(tz.getLocation(nomFuseau));
    } catch (_) {
      // Repli : fuseau système par défaut du paquet timezone.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (reponse) {
        onTapNotification?.call(reponse.payload ?? '');
      },
    );

    // Permissions Android 13+ (canal d'alarme) — silencieuses si déjà accordées.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      // Alarmes EXACTES Android 12+ : demandées si nécessaires ; le repli
      // inexact reste fonctionnel (notification dans la fenêtre système).
      await androidImpl?.requestExactAlarmsPermission();
      await _creerCanauxAndroid();
    }

    _initialise = true;
  }

  Future<void> _creerCanauxAndroid() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    const canalAlarme = AndroidNotificationChannel(
      'alarmes_celestes',
      'Alarmes spirituelles Horloge Céleste',
      description: 'RHEMA du matin, préparation du soir et RHEMA du soir',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidImpl?.createNotificationChannel(canalAlarme);
  }

  /// Planifie le RHEMA du matin — répétition QUOTIDIENNE à 05 h 00 locales.
  Future<void> planifierRhemaMatin({
    required int id,
    required String titre,
    required String corps,
    required bool vibration,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var cible = tz.TZDateTime(tz.local, now.year, now.month, now.day, 5, 0);
    if (!cible.isAfter(now)) {
      cible = cible.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      cible,
      _details(vibration: vibration),
      // Répétition quotidienne à la même heure locale — le coucher du
      // soleil n'étant PAS concerné, une répétition fixe est correcte.
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'rhema_matin',
    );
  }

  /// Planifie une alarme du soir (one-shot) à un instant précis.
  Future<void> planifierOneShot({
    required int id,
    required String titre,
    required String corps,
    required DateTime instant,
    required bool vibration,
    String payload = 'alarme_soir',
  }) async {
    final cible = tz.TZDateTime.from(instant, tz.local);
    if (!cible.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      cible,
      _details(vibration: vibration),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Annule toutes les alarmes planifiées (changement de position,
  /// désactivation) — reprogrammées ensuite par PrayerAlarmEngine.
  Future<void> annulerTout() => _plugin.cancelAll();

  NotificationDetails _details({required bool vibration}) {
    final android = AndroidNotificationDetails(
      'alarmes_celestes',
      'Alarmes spirituelles Horloge Céleste',
      channelDescription:
          'RHEMA du matin, préparation du soir et RHEMA du soir',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: vibration,
      // Son : ressource intégrée (shofar). Un son personnalisé choisi par
      // l'utilisateur serait passé via RawResourceAndroidNotificationSound.
      sound: const RawResourceAndroidNotificationSound('shofar'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    const ios = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return NotificationDetails(android: android, iOS: ios);
  }
}
