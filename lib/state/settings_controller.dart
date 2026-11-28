/// ⭐ SETTINGS CONTROLLER — préférences persistées (position, affichage,
/// écran de verrouillage).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../services/location_service.dart';
import '../services/settings_store.dart';
import '../services/wallpaper_service.dart';
import 'horloge_controller.dart';

/// État des paramètres affichés dans l'écran Paramètres.
class SettingsState {
  final PositionUtilisateur position;
  final bool horlogeAnalogique;
  final bool modeHebreu;
  final bool trotteuseFluide;
  final bool chargement;
  final String? message;

  const SettingsState({
    required this.position,
    required this.horlogeAnalogique,
    this.modeHebreu = false,
    this.trotteuseFluide = true,
    this.chargement = false,
    this.message,
  });

  SettingsState copyWith({
    PositionUtilisateur? position,
    bool? horlogeAnalogique,
    bool? modeHebreu,
    bool? trotteuseFluide,
    bool? chargement,
    String? message,
  }) =>
      SettingsState(
        position: position ?? this.position,
        horlogeAnalogique: horlogeAnalogique ?? this.horlogeAnalogique,
        modeHebreu: modeHebreu ?? this.modeHebreu,
        trotteuseFluide: trotteuseFluide ?? this.trotteuseFluide,
        chargement: chargement ?? this.chargement,
        message: message,
      );
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final store = SettingsStore.instance;
    // L'écran de verrouillage lit cet instantané nativement : on le
    // rafraîchit au démarrage (position + alarmes + préférences).
    unawaited(WallpaperService.actualiserSnapshot());
    return SettingsState(
      position: store.position(),
      horlogeAnalogique: store.horlogeAnalogique(),
      modeHebreu: store.modeHebreu(),
      trotteuseFluide: store.trotteuseFluide(),
    );
  }

  /// Localisation GPS ponctuelle (§9.1) puis recalcul complet.
  Future<void> localiserAutomatiquement() async {
    state = state.copyWith(chargement: true, message: null);
    final resultat = await LocationService.instance.positionPonctuelle();
    if (resultat.statut == StatutLocalisation.ok && resultat.position != null) {
      await _appliquer(resultat.position!);
      state = state.copyWith(
        chargement: false,
        message: 'Position mise à jour — horaires recalculés.',
      );
    } else {
      state = state.copyWith(
        chargement: false,
        message: resultat.message,
      );
    }
  }

  /// Position manuelle depuis la liste des villes (§9.2).
  Future<void> choisirVille(VilleIntegree ville) async {
    await _appliquer(LocationService.instance.positionDepuisVille(ville));
    state = state.copyWith(
      message: 'Ville choisie : ${ville.ville} — horaires recalculés.',
    );
  }

  /// Position manuelle libre (lat/lon saisis).
  Future<void> positionManuelle(double lat, double lon, String libelle) async {
    final fuseauActuel = state.position.fuseau;
    await _appliquer(PositionUtilisateur(
      latitude: lat,
      longitude: lon,
      libelle: libelle,
      fuseau: fuseauActuel,
    ));
    state = state.copyWith(
      message: 'Position manuelle enregistrée — horaires recalculés.',
    );
  }

  Future<void> _appliquer(PositionUtilisateur position) async {
    state = state.copyWith(position: position);
    // Recalcul complet immédiat du moteur de temps (§9.2).
    ref.read(horlogeProvider.notifier).changerPosition(position);
    // L'écran de verrouillage doit suivre la nouvelle position.
    unawaited(WallpaperService.actualiserSnapshot());
  }

  Future<void> basculerHorlogeAnalogique(bool valeur) async {
    await SettingsStore.instance.sauvegarderHorlogeAnalogique(valeur);
    state = state.copyWith(horlogeAnalogique: valeur);
  }

  /// MODE HÉBRAÏQUE (§7) : les jours de la semaine s'affichent en
  /// translittération — Yom Ehad (jour 1) … Yom Shabbat (jour 7).
  Future<void> basculerModeHebreu(bool valeur) async {
    await SettingsStore.instance.sauvegarderModeHebreu(valeur);
    state = state.copyWith(modeHebreu: valeur);
  }

  /// ÉCRAN DE VERROUILLAGE (§9.5) : trotteuse FLUIDE (~30 img/s, plus
  /// raffinée) ou TIC-TAC par seconde (économie de batterie maximale).
  Future<void> basculerTrotteuseFluide(bool valeur) async {
    await SettingsStore.instance.sauvegarderTrotteuseFluide(valeur);
    state = state.copyWith(trotteuseFluide: valeur);
    unawaited(WallpaperService.actualiserSnapshot());
  }
}

/// Provider des paramètres.
final settingsProvider =
    NotifierProvider<SettingsController, SettingsState>(SettingsController.new);
