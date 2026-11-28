/// ⭐ ÉCRAN DE VERROUILLAGE (§9.5) — pont Flutter ⇄ service natif Kotlin.
///
/// PRINCIPE (Android moderne) : aucun remplacement d'écran de verrouillage
/// n'est possible (SystemUI + règles Play). La voie officielle est le FOND
/// D'ÉCRAN ANIMÉ (Live Wallpaper) : depuis Android 13 l'utilisateur peut
/// l'affecter UNIQUEMENT à l'écran de verrouillage (sélecteur système) —
/// exactement l'effet voulu : l'Horloge Céleste s'affiche quand le
/// téléphone se verrouille.
///
/// RÔLES DE CE SERVICE :
///   • ouvrir le sélecteur de fonds d'écran animés pré-sélectionné sur
///     notre service (`ACTION_CHANGE_LIVE_WALLPAPER`) — un seul appui ;
///   • interroger l'état (notre wallpaper est-il actif ?) ;
///   • écrire l'INSTANTANÉ partagé (position + alarmes + trotteuse) que le
///     service natif lit pour peindre le cadran et la prochaine alarme.
///     Écrit à chaque changement pertinent (position, alarme, préférence) —
///     le wallpaper écoute la clé et se redessine instantanément.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import 'settings_store.dart';

class WallpaperService {
  WallpaperService._();

  static const MethodChannel _canal = MethodChannel('horloge_celeste/wallpaper');

  /// Ouvre le sélecteur système de fonds d'écran animés, PRÉ-SÉLECTIONNÉ
  /// sur l'Horloge Céleste (un appui de plus et c'est actif). Sur Android
  /// 13+ l'utilisateur peut y choisir « Écran de verrouillage » uniquement.
  static Future<void> ouvrirChoix() async {
    try {
      await _canal.invokeMethod<void>('ouvrirChoixWallpaper');
    } catch (_) {
      // Appareil sans sélecteur de wallpapers animés (très rare) : rien.
    }
  }

  /// Notre wallpaper animé est-il le fond d'écran actuel ?
  static Future<bool> estActif() async {
    try {
      final r = await _canal.invokeMethod<bool>('estWallpaperActif');
      return r ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Écrit l'instantané partagé (JSON) : position, alarmes actives, mode
  /// de trotteuse. Appelé au démarrage de l'app, après chaque changement
  /// de position, d'alarme ou de préférence — le service natif écoute la
  /// clé et se redessine aussitôt.
  static Future<void> actualiserSnapshot() async {
    try {
      final store = SettingsStore.instance;
      final pos = store.position();

      final alarmes = <Map<String, dynamic>>[];

      // RHEMA du matin — heure fixe réglable.
      final matin = store.alarme(SettingsStore.cleAlarmeMatin, '');
      alarmes.add({
        'libelle': 'RHEMA du matin',
        'type': 'fixe',
        'heure': matin.heure,
        'minute': matin.minute,
        'activee': matin.activee,
      });

      // Préparation du soir — coucher réel − N minutes (le wallpaper
      // recalcule le coucher avec le même algorithme NOAA).
      final preparation =
          store.alarme(SettingsStore.cleAlarmePreparation, '');
      alarmes.add({
        'libelle': 'Préparation du soir',
        'type': 'preparation',
        'minutesAvant': preparation.minutesAvant,
        'activee': preparation.activee,
      });

      // RHEMA du soir — au coucher du soleil réel.
      final soir = store.alarme(SettingsStore.cleAlarmeSoir, '');
      alarmes.add({
        'libelle': 'RHEMA du soir',
        'type': 'coucher',
        'activee': soir.activee,
      });

      // Alarmes personnalisées — heure fixe et tâche libre (§8.5).
      for (final p in store.alarmesPersonnalisees()) {
        alarmes.add({
          'libelle': p.libelle,
          'type': 'fixe',
          'heure': p.prefs.heure,
          'minute': p.prefs.minute,
          'activee': p.prefs.activee,
        });
      }

      final snapshot = jsonEncode({
        'lat': pos.latitude,
        'lon': pos.longitude,
        'trotteuseFluide': store.trotteuseFluide(),
        'alarmes': alarmes,
      });

      await store.sauvegarderSnapshotWallpaper(snapshot);
    } catch (_) {
      // Jamais de crash d'interface pour un simple écran de verrouillage.
    }
  }
}
