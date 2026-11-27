/// ⭐ STORE DE PARAMÈTRES — §13 (gestion des données et fiabilité).
///
/// Conservation locale (shared_preferences) :
///   • préférences d'affichage (horloge numérique/analogique) ;
///   • paramètres de localisation + fuseau horaire ;
///   • préférences d'alarme (les 3 RHEMA) ;
///   • derniers horaires solaires calculés + dernière date biblique
///     synchronisée + dernière transition traitée (anti-doublon §14).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';

/// Configuration de position de l'utilisateur.
class PositionUtilisateur {
  final double latitude;
  final double longitude;
  final String libelle; // « Cotonou, Bénin » ou « Position manuelle »
  final String fuseau; // IANA
  final bool automatique; // obtenu par GPS ?

  const PositionUtilisateur({
    required this.latitude,
    required this.longitude,
    required this.libelle,
    required this.fuseau,
    this.automatique = false,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        'libelle': libelle,
        'fuseau': fuseau,
        'auto': automatique,
      };

  static PositionUtilisateur fromJson(Map<String, dynamic> json) =>
      PositionUtilisateur(
        latitude: (json['lat'] as num?)?.toDouble() ?? AppConfig.latitudeDefaut,
        longitude: (json['lon'] as num?)?.toDouble() ?? AppConfig.longitudeDefaut,
        libelle: json['libelle'] as String? ?? AppConfig.villeDefaut,
        fuseau: json['fuseau'] as String? ?? AppConfig.fuseauDefaut,
        automatique: json['auto'] as bool? ?? false,
      );

  static const defaut = PositionUtilisateur(
    latitude: AppConfig.latitudeDefaut,
    longitude: AppConfig.longitudeDefaut,
    libelle: AppConfig.villeDefaut,
    fuseau: AppConfig.fuseauDefaut,
  );
}

/// Préférences d'une alarme spirituelle (§8) — horaires réglables.
class AlarmePrefs {
  final bool activee;
  final bool vibration;
  final String son;
  final String message;

  /// RHEMA du matin : heure locale choisie (défaut 05 h 00).
  final int heure;
  final int minute;

  /// Préparation du soir : minutes avant le coucher réel (défaut 5).
  final int minutesAvant;

  const AlarmePrefs({
    this.activee = true,
    this.vibration = true,
    this.son = 'shofar',
    required this.message,
    this.heure = 5,
    this.minute = 0,
    this.minutesAvant = 5,
  });

  AlarmePrefs copyWith({
    bool? activee,
    bool? vibration,
    String? son,
    String? message,
    int? heure,
    int? minute,
    int? minutesAvant,
  }) =>
      AlarmePrefs(
        activee: activee ?? this.activee,
        vibration: vibration ?? this.vibration,
        son: son ?? this.son,
        message: message ?? this.message,
        heure: heure ?? this.heure,
        minute: minute ?? this.minute,
        minutesAvant: minutesAvant ?? this.minutesAvant,
      );

  Map<String, dynamic> toJson() => {
        'activee': activee,
        'vibration': vibration,
        'son': son,
        'message': message,
        'heure': heure,
        'minute': minute,
        'minutesAvant': minutesAvant,
      };

  static AlarmePrefs fromJson(Map<String, dynamic> json) => AlarmePrefs(
        activee: json['activee'] as bool? ?? true,
        vibration: json['vibration'] as bool? ?? true,
        son: json['son'] as String? ?? 'shofar',
        message: json['message'] as String? ?? '',
        heure: json['heure'] as int? ?? 5,
        minute: json['minute'] as int? ?? 0,
        minutesAvant: json['minutesAvant'] as int? ?? 5,
      );
}

class SettingsStore {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  SharedPreferences? _prefs;

  Future<void> initialiser() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs => _prefs!;

  // ── Clés canoniques ──
  static const clePosition = 'hc_position';
  static const cleHorlogeAnalogique = 'hc_horloge_analogique';
  static const cleAlarmeMatin = 'hc_alarme_matin';
  static const cleAlarmePreparation = 'hc_alarme_preparation';
  static const cleAlarmeSoir = 'hc_alarme_soir';
  static const cleDerniereTransition = 'hc_derniere_transition';
  static const cleEtatTemporel = 'hc_etat_temporel';
  static const cleHistoriqueNotifications = 'hc_historique_notifications';
  static const clePremierLancement = 'hc_premier_lancement';

  // ── Position (§9) ──

  PositionUtilisateur position() {
    final brut = prefs.getString(clePosition);
    if (brut == null) return PositionUtilisateur.defaut;
    try {
      return PositionUtilisateur.fromJson(
          Map<String, dynamic>.from(jsonDecode(brut) as Map));
    } catch (_) {
      return PositionUtilisateur.defaut;
    }
  }

  Future<void> sauvegarderPosition(PositionUtilisateur p) =>
      prefs.setString(clePosition, jsonEncode(p.toJson()));

  // ── Préférences d'affichage ──

  bool horlogeAnalogique() => prefs.getBool(cleHorlogeAnalogique) ?? false;

  Future<void> sauvegarderHorlogeAnalogique(bool v) =>
      prefs.setBool(cleHorlogeAnalogique, v);

  // ── Alarmes (§8.4) ──

  AlarmePrefs alarme(String cle, String messageDefaut) {
    final brut = prefs.getString(cle);
    if (brut == null) return AlarmePrefs(message: messageDefaut);
    try {
      final json = Map<String, dynamic>.from(jsonDecode(brut) as Map);
      return AlarmePrefs.fromJson(json).copyWith(
        message: (json['message'] as String?)?.isEmpty ?? true
            ? messageDefaut
            : json['message'] as String,
      );
    } catch (_) {
      return AlarmePrefs(message: messageDefaut);
    }
  }

  Future<void> sauvegarderAlarme(String cle, AlarmePrefs a) =>
      prefs.setString(cle, jsonEncode(a.toJson()));

  // ── État temporel persisté (§13 / §14) ──

  String? derniereTransition() => prefs.getString(cleDerniereTransition);

  Future<void> sauvegarderDerniereTransition(String cle) =>
      prefs.setString(cleDerniereTransition, cle);

  String? etatTemporelJson() => prefs.getString(cleEtatTemporel);

  Future<void> sauvegarderEtatTemporel(String json) =>
      prefs.setString(cleEtatTemporel, json);

  // ── Historique des notifications (§8.4) ──

  List<Map<String, dynamic>> historiqueNotifications() {
    final brut = prefs.getString(cleHistoriqueNotifications);
    if (brut == null) return const [];
    try {
      final liste = jsonDecode(brut) as List;
      return liste.cast<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> ajouterHistorique(String titre, String corps, DateTime instant) {
    final liste = historiqueNotifications()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    liste.insert(0, {
      'titre': titre,
      'corps': corps,
      'instant': instant.toIso8601String(),
    });
    if (liste.length > 30) liste.removeRange(30, liste.length);
    return prefs.setString(
        cleHistoriqueNotifications, jsonEncode(liste));
  }

  bool premierLancementFait() => prefs.getBool(clePremierLancement) ?? false;

  Future<void> marquerPremierLancement() =>
      prefs.setBool(clePremierLancement, true);
}
