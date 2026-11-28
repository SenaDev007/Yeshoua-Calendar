/// ⭐ SERVICE DE LOCALISATION — §9 (moteur astronomique et géolocalisation).
///
///   • localisation PONCTUELLE (§9.1) : demande d'autorisation à la
///     première utilisation, jamais en permanence ;
///   • localisation MANUELLE (§9.2) : pays/ville intégrés hors connexion ;
///   • recalcul des horaires après modification de la position.
library;

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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

  /// DÉTECTION AUTOMATIQUE DU PAYS (§9.1) — au premier lancement, avant
  /// toute demande de permission GPS : le fuseau IANA du téléphone est
  /// apparié aux villes intégrées hors connexion. Le coucher du soleil —
  /// donc la BASCULE DE LA DATE BIBLIQUE — est alors correct pour le pays
  /// de l'utilisateur dès la première ouverture (le coucher varie selon le
  /// pays ; jamais de valeur fixe 18 h 00, §18).
  ///
  /// Retourne null si aucun pays de la liste ne correspond au fuseau —
  /// l'utilisateur garde alors la position par défaut et peut choisir
  /// librement sa ville (ou activer le GPS) dans Réglages.
  Future<PositionUtilisateur?> positionDepuisFuseau() async {
    try {
      final fuseau = await FlutterTimezone.getLocalTimezone();
      final nom = fuseau.trim().toLowerCase();

      // 1. Correspondance EXACTE du nom IANA (« Africa/Kinshasa »…).
      for (final ville in villesIntegreees) {
        if (ville.fuseau.toLowerCase() == nom) {
          return positionDepuisVille(ville);
        }
      }

      // 2. Correspondance par BRANCHE avec le MÊME DÉCALAGE HORAIRE RÉEL
      //    (« America/Indiana/Indianapolis » → ville America/… à UTC−5 ou
      //    −4 selon l'heure d'été) — le coucher du soleil doit rester
      //    juste, un mauvais décalage décalerait la bascule de la date
      //    biblique d'autant. Le paquet timezone (déjà embarqué) donne
      //    l'offset exact de chaque ville candidate à l'instant présent.
      tzdata.initializeTimeZones();
      final utc = DateTime.now().toUtc();
      int offsetMinutesDe(String fuseauVille) {
        try {
          final loc = tz.getLocation(fuseauVille);
          return tz.TZDateTime.from(utc, loc).timeZoneOffset.inMinutes;
        } catch (_) {
          return 1 << 30; // fuseau inconnu : jamais retenu
        }
      }

      final branche = nom.split('/').first;
      final cible = offsetMinutesDe(fuseau.trim());
      VilleIntegree? meilleure;
      var meilleurEcart = 1 << 31;
      for (final ville in villesIntegreees) {
        if (!ville.fuseau.toLowerCase().startsWith('$branche/')) continue;
        final ecart =
            (offsetMinutesDe(ville.fuseau) - cible).abs();
        if (ecart < meilleurEcart) {
          meilleurEcart = ecart;
          meilleure = ville;
        }
      }
      return meilleure == null ? null : positionDepuisVille(meilleure);
    } catch (_) {
      // Fuseau indisponible : pas d'invention — repli sur la valeur par défaut.
      return null;
    }
  }
}
