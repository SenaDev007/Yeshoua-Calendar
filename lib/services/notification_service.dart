/// ⭐ SERVICE DE NOTIFICATIONS — PHASE 7 (§8).
///
/// Notifications locales natives pour les trois alarmes spirituelles :
///   1. RHEMA du matin — heure locale choisie par l'utilisateur (05 h 00
///      par défaut ; répétition quotidienne) ;
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
      final nomFuseau = await FlutterTimezone.getLocalTimezone();
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
    // UN CANAL PAR SONNERIE (§8.4) : sur Android 8+, le son est figé dans le
    // canal au moment de sa création — pour que le shofar (ou la cloche, ou
    // la harpe) retentisse même quand l'application est fermée, chaque mode
    // de sonnerie dispose de son propre canal, créé AVEC son son embarqué
    // (res/raw/<nom>.mp3). 'silence' : vibration seule, sans son.
    const canaux = [
      AndroidNotificationChannel(
        'alarmes_shofar',
        'Alarmes — Shofar',
        description: 'Alarmes spirituelles sonnées au shofar',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('shofar'),
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'alarmes_cloche',
        'Alarmes — Cloche',
        description: 'Alarmes spirituelles sonnées à la cloche',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('cloche'),
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'alarmes_harpe',
        'Alarmes — Harpe',
        description: 'Alarmes spirituelles sonnées à la harpe',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('harpe'),
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'alarmes_silence',
        'Alarmes — Silence',
        description: 'Alarmes silencieuses (vibration seule)',
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
      ),
    ];
    for (final canal in canaux) {
      await androidImpl?.createNotificationChannel(canal);
    }
  }

  /// Planifie le RHEMA du matin — répétition QUOTIDIENNE à l'heure locale
  /// choisie par l'utilisateur (05 h 00 par défaut, réglable §8.4).
  Future<void> planifierRhemaMatin({
    required int id,
    required String titre,
    required String corps,
    required bool vibration,
    required String son,
    required int heure,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var cible =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, heure, minute);
    if (!cible.isAfter(now)) {
      cible = cible.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      cible,
      _details(vibration: vibration, son: son),
      // Répétition quotidienne à la même heure locale — le coucher du
      // soleil n'étant PAS concerné, une répétition fixe est correcte.
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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
    required String son,
    String payload = 'alarme_soir',
  }) async {
    final cible = tz.TZDateTime.from(instant, tz.local);
    if (!cible.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      cible,
      _details(vibration: vibration, son: son),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Annule toutes les alarmes planifiées (changement de position,
  /// désactivation) — reprogrammées ensuite par PrayerAlarmEngine.
  Future<void> annulerTout() => _plugin.cancelAll();

  /// [son] : mode choisi par l'utilisateur pour CETTE alarme — 'shofar',
  /// 'cloche' ou 'harpe' (ressource native res/raw/<nom>.mp3) ou 'silence'
  /// (vibration seule : playSound désactivé). Chaque mode a SON CANAL
  /// (créé avec le son embarqué — voir _creerCanauxAndroid), garantissant
  /// la sonnerie même lorsque l'application est fermée.
  NotificationDetails _details({required bool vibration, required String son}) {
    const modesConnus = ['shofar', 'cloche', 'harpe'];
    final sonActif = modesConnus.contains(son);
    final canal = sonActif ? 'alarmes_$son' : 'alarmes_silence';
    final android = AndroidNotificationDetails(
      canal,
      'Alarmes spirituelles Horloge Céleste',
      channelDescription:
          'RHEMA du matin, préparation du soir et RHEMA du soir',
      importance: Importance.max,
      priority: Priority.max,
      playSound: sonActif,
      enableVibration: vibration,
      sound: sonActif ? RawResourceAndroidNotificationSound(son) : null,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    // iOS : le son personnalisé exige les fichiers embarqués nativement
    // dans le bundle (Xcode) ; sans eux, le son par défaut est utilisé.
    final ios = DarwinNotificationDetails(
      presentSound: sonActif,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return NotificationDetails(android: android, iOS: ios);
  }
}
