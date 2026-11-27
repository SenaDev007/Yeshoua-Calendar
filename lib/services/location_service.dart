/// ⭐ SERVICE DE LOCALISATION — §9 (moteur astronomique et géolocalisation).
///
///   • localisation PONCTUELLE (§9.1) : demande d'autorisation à la
///     première utilisation, jamais en permanence ;
///   • localisation MANUELLE (§9.2) : pays/ville intégrés hors connexion ;
///   • recalcul des horaires après modification de la position.
library;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/config/app_config.dart';
import 'settings_store.dart';

enum StatutLocalisation { ok, permissionRefusee, serviceDesactive, echec }

class ResultatLocalisation {
  final StatutLocalisation statut;
  final PositionUtilisateur? position;
  final String message;

  const ResultatLocalisation(this.statut, {this.position, this.message = ''});
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Position GPS PONCTUELLE (§9.1) — une seule prise, pas de suivi.
  Future<ResultatLocalisation> positionPonctuelle() async {
    // 1. Autorisation (permission_handler, même dépendance que le projet
    //    existant yeshua-connect-mobile).
    final statut = await Permission.locationWhenInUse.request();
    if (statut.isDenied || statut.isPermanentlyDenied) {
      return const ResultatLocalisation(
        StatutLocalisation.permissionRefusee,
        message: 'Autorisation de localisation refusée — choisissez votre '
            'ville dans la liste ou saisissez une position manuelle.',
      );
    }

    // 2. Service de localisation actif ?
    final serviceActif = await Geolocator.isLocationServiceEnabled();
    if (!serviceActif) {
      return const ResultatLocalisation(
        StatutLocalisation.serviceDesactive,
        message: 'Le service de localisation est désactivé sur ce téléphone.',
      );
    }

    // 3. Prise ponctuelle avec garde-fou de précision et de délai.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final pos = PositionUtilisateur(
        latitude: position.latitude,
        longitude: position.longitude,
        libelle: 'Position actuelle (±${position.accuracy.round()} m)',
        fuseau: SettingsStore.instance.position().fuseau,
        automatique: true,
      );
      return ResultatLocalisation(StatutLocalisation.ok, position: pos);
    } catch (e) {
      return ResultatLocalisation(
        StatutLocalisation.echec,
        message: 'Localisation impossible ($e) — utilisez la liste des villes.',
      );
    }
  }

  /// Position manuelle depuis la liste des villes intégrées (§9.2).
  PositionUtilisateur positionDepuisVille(VilleIntegree ville) =>
      PositionUtilisateur(
        latitude: ville.latitude,
        longitude: ville.longitude,
        libelle: '${ville.ville}, ${ville.pays}',
        fuseau: ville.fuseau,
      );
}
