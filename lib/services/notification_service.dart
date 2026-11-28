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
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialise = false;

  /// Alarmes EXACTES autorisées par le système (Android 12+). Si false,
  /// les alarmes sont planifiées en mode INEXACT (elles sonnent quand
  /// même, dans une fenêtre système) — JAMAIS d'exception avalée qui
  /// laisse l'alarme muette (défaut majeur corrigé §8.4).
  bool _exactAutorisees = true;

  bool get exactAlarmsAutorisees => _exactAutorisees;

  /// Callback quand l'utilisateur touche une notification (ouverture d'app).
  /// [titre] et [corps] alimentent l'historique local (§8.4).
  void Function(String payload, String? titre, String? corps)?
      onTapNotification;

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
        // NotificationResponse (v17) n'expose pas titre/corps : un libellé
        // stable est déduit du payload pour l'historique local (§8.4).
        final cle = reponse.payload ?? '';
        const libelles = {
          'rhema_matin': 'RHEMA du matin',
          'preparation_soir': 'Préparation du soir',
          'rhema_soir': 'RHEMA du soir',
          'alarme_custom': 'Alarme personnalisée',
          'shofar_shabbat': 'Shofar — entrée du Shabbat',
          'shofar_fete': 'Shofar — entrée de fête',
          'rappel_shabbat_j24h': 'Rappel — Shabbat dans 24 heures',
          'rappel_j7': 'Rappel de fête — J-7',
          'rappel_j3': 'Rappel de fête — J-3',
          'rappel_j24h': 'Rappel de fête — 24 h',
        };
        onTapNotification?.call(
            cle, libelles[cle] ?? (cle.isEmpty ? null : cle), null);
      },
    );

    // Permissions Android 13+ (canal d'alarme) — silencieuses si déjà accordées.
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      // Alarmes EXACTES Android 12+ : demandées si nécessaires ; le repli
      // inexact reste fonctionnel (notification dans la fenêtre système).
      await androidImpl?.requestExactAlarmsPermission();
      // EXEMPTION D'OPTIMISATION DE BATTERIE : les constructeurs (Xiaomi,
      // Oppo, Samsung…) tuent ou diffèrent les alarmes des apps mises en
      // veille — c'est LA cause n°1 des alarmes qui ne sonnent pas. La
      // demande est légitime pour une horloge-réveil ; le dialogue
      // système ne s'affiche que si l'app n'est pas encore exemptée.
      try {
        final batterie = await Permission.ignoreBatteryOptimizations.status;
        if (!batterie.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (_) {
        // Appareil sans gestion d'optimisation (rare) : ignorer.
      }
      // Mémorise la décision système (Permission.scheduleExactAlarm —
      // permission_handler) : zonedSchedule lèverait une exception en mode
      // exact sans permission — ce qui LAISSAIT LES ALARMES MUETTES.
      // Désormais : repli inexact automatique (voir _planifierRobuste).
      _exactAutorisees = await _verifierAlarmesExactes();
      await _creerCanauxAndroid();
    }

    _initialise = true;
  }

  /// Statut réel des alarmes exactes (Android 12+). Sur les versions
  /// antérieures (ou toute erreur), on considère les alarmes exactes
  /// autorisées — elles ne demandaient jamais de permission avant Android 12.
  Future<bool> _verifierAlarmesExactes() async {
    try {
      final statut = await Permission.scheduleExactAlarm.status;
      return statut.isGranted || statut.isLimited || statut.isProvisional;
    } catch (_) {
      return true;
    }
  }

  /// Planification ROBUSTE : tente le mode EXACT, et si le système le
  /// refuse (permission absente, OEM restrictif), replie automatiquement
  /// sur le mode INEXACT — l'alarme sonne DANS TOUS LES CAS (l'ancien code
  /// laissait l'exception avalée par les catch du moteur : alarmes jamais
  /// déclenchées — défaut majeur corrigé).
  Future<void> _planifierRobuste({
    required int id,
    required String titre,
    required String corps,
    required tz.TZDateTime cible,
    required NotificationDetails details,
    required String payload,
    bool repetitionQuotidienne = false,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        titre,
        corps,
        cible,
        details,
        matchDateTimeComponents:
            repetitionQuotidienne ? DateTimeComponents.time : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      // Repli : inexact (l'alarme sonne dans une fenêtre système large).
      try {
        await _plugin.zonedSchedule(
          id,
          titre,
          corps,
          cible,
          details,
          matchDateTimeComponents:
              repetitionQuotidienne ? DateTimeComponents.time : null,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (_) {
        // Double échec (fuseau, système) : l'appelant journalise au besoin.
        rethrow;
      }
    }
  }

  /// Ouvre l'écran système des alarmes exactes (Android 12+) via
  /// permission_handler — la demande montre directement les réglages.
  Future<void> ouvrirParametresAlarmesExactes() async {
    try {
      await Permission.scheduleExactAlarm.request();
      _exactAutorisees = await _verifierAlarmesExactes();
    } catch (_) {
      try {
        await openAppSettings();
      } catch (_) {
        // Plateforme sans réglage dédié : rien à faire.
      }
    }
  }

  Future<void> _creerCanauxAndroid() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // UN CANAL PAR SONNERIE (§8.4) : sur Android 8+, le son est figé dans le
    // canal au moment de sa création — pour que le shofar (ou la cloche, ou
    // la harpe) retentisse même quand l'application est fermée, chaque mode
    // de sonnerie dispose de son propre canal, créé AVEC son son embarqué
    // (res/raw/<nom>.mp3). 'silence' : vibration seule, sans son.
    // SON SUR LE FLUX ALARM (audioAttributesUsage — défaut corrigé) : par
    // défaut le plugin joue le son sur le flux NOTIFICATION — si le volume
    // des notifications est baissé ou muet (typiquement la nuit), le
    // téléphone ne sonne PAS même si la notification arrive. Avec
    // USAGE_ALARM, le son suit le volume du RÉVEIL, comme un vrai
    // réveil-matin — c'était la cause n°2 des « alarmes muettes ».
    const canaux = [
      AndroidNotificationChannel(
        'alarmes_shofar_v2',
        'Alarmes — Shofar',
        description: 'Alarmes spirituelles sonnées au shofar',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('shofar'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      AndroidNotificationChannel(
        'alarmes_cloche_v2',
        'Alarmes — Cloche',
        description: 'Alarmes spirituelles sonnées à la cloche',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('cloche'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      AndroidNotificationChannel(
        'alarmes_harpe_v2',
        'Alarmes — Harpe',
        description: 'Alarmes spirituelles sonnées à la harpe',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('harpe'),
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      AndroidNotificationChannel(
        'alarmes_silence_v2',
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
    // Les canaux SANS suffixe _v2 existent déjà sur les téléphones mis à
    // jour : Android fige un canal à sa création (le nouveau flux ALARM et
    // les sons n'y seraient JAMAIS appliqués) — ils sont supprimés, les
    // nouvelles alarmes utilisent les canaux _v2 ci-dessus.
    for (final ancien in const [
      'alarmes_celestes',
      'alarmes_shofar',
      'alarmes_cloche',
      'alarmes_harpe',
      'alarmes_silence',
    ]) {
      try {
        await androidImpl?.deleteNotificationChannel(ancien);
      } catch (_) {
        // Canal déjà absent : rien à faire.
      }
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
    // Répétition quotidienne à la même heure locale — le coucher du
    // soleil n'étant PAS concerné, une répétition fixe est correcte.
    // Planification robuste : exact, puis inexact si le système refuse.
    await _planifierRobuste(
      id: id,
      titre: titre,
      corps: corps,
      cible: cible,
      details: _details(vibration: vibration, son: son),
      payload: 'rhema_matin',
      repetitionQuotidienne: true,
    );
  }

  /// Planifie une ALARME PERSONNALISÉE (§8.5) — répétition quotidienne à
  /// l'heure choisie, sonnerie au choix, plein écran, exacte si permise.
  Future<void> planifierPersonnalisee({
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
    await _planifierRobuste(
      id: id,
      titre: titre,
      corps: corps,
      cible: cible,
      details: _details(vibration: vibration, son: son),
      payload: 'alarme_custom',
      repetitionQuotidienne: true,
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
    await _planifierRobuste(
      id: id,
      titre: titre,
      corps: corps,
      cible: cible,
      details: _details(vibration: vibration, son: son),
      payload: payload,
    );
  }

  /// TEST DE SONNERIE (§8.4) — déclenche IMMÉDIATEMENT une notification
  /// réelle dans le canal du son choisi : l'utilisateur entend exactement
  /// ce que l'alarme produira (même son, même vibration), app ouverte ou
  /// fermée, téléphone en silencieux inclus (vibration du canal).
  Future<void> testerSonnerie({
    required String son,
    required bool vibration,
    String titre = 'Test de sonnerie',
    String corps = 'C\u2019est exactement le son de votre alarme. Shalom !',
  }) async {
    try {
      await _plugin.show(
        999999,
        titre,
        corps,
        _details(vibration: vibration, son: son),
        payload: 'test_sonnerie',
      );
    } catch (_) {
      // Le test ne doit jamais bloquer l'interface.
    }
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
    final canal = sonActif ? 'alarmes_${son}_v2' : 'alarmes_silence_v2';
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
      // Son sur le FLUX ALARM (volume du réveil) — jamais muet parce que
      // le volume des notifications serait baissé (défaut corrigé).
      audioAttributesUsage: AudioAttributesUsage.alarm,
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
