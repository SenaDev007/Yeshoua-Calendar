/// Configuration ZMAN + villes intégrées pour la localisation manuelle
/// (§9.2 — choisir son pays et sa ville SANS connexion).
library;

class AppConfig {
  AppConfig._();

  /// Nom et signature de l'application.
  static const String nomApp = 'Zman';
  static const String hebreuApp = 'זְמַן';
  static const String signature = 'Le temps selon les Écritures';

  /// Position par défaut : Cotonou, Bénin (Africa/Porto-Novo) — premier
  /// lancement, avant que l'utilisateur choisisse sa position.
  static const double latitudeDefaut = 6.37;
  static const double longitudeDefaut = 2.42;
  static const String villeDefaut = 'Cotonou, Bénin';

  /// Fuseau IANA par défaut (exemple du cahier des charges).
  static const String fuseauDefaut = 'Africa/Porto-Novo';

  /// Bornes d'années du calendrier (identiques au calendrier existant).
  static const int anneeMin = 1900;
  static const int anneeMax = 2100;
}

/// Une ville intégrée (pays, ville, latitude, longitude, fuseau IANA).
class VilleIntegree {
  final String pays;
  final String ville;
  final double latitude;
  final double longitude;
  final String fuseau;

  const VilleIntegree(this.pays, this.ville, this.latitude, this.longitude, this.fuseau);
}

/// Villes proposées hors connexion (§9.2) — échantillon Afrique de l'Ouest,
/// France, Israël et grandes capitales. La liste est volontairement
/// locale : aucune API de géocodage n'est requise.
const List<VilleIntegree> villesIntegreees = [
  // Bénin
  VilleIntegree('Bénin', 'Cotonou', 6.37, 2.42, 'Africa/Porto-Novo'),
  VilleIntegree('Bénin', 'Porto-Novo', 6.49, 2.60, 'Africa/Porto-Novo'),
  VilleIntegree('Bénin', 'Parakou', 9.34, 2.62, 'Africa/Porto-Novo'),
  VilleIntegree('Bénin', 'Bohicon', 7.18, 2.09, 'Africa/Porto-Novo'),
  VilleIntegree('Bénin', 'Natitingou', 10.31, 1.38, 'Africa/Porto-Novo'),
  // Afrique de l'Ouest
  VilleIntegree('Nigeria', 'Lagos', 6.52, 3.38, 'Africa/Lagos'),
  VilleIntegree('Nigeria', 'Abuja', 9.06, 7.49, 'Africa/Lagos'),
  VilleIntegree('Ghana', 'Accra', 5.56, -0.19, 'Africa/Accra'),
  VilleIntegree('Côte d\u2019Ivoire', 'Abidjan', 5.36, -4.01, 'Africa/Abidjan'),
  VilleIntegree('Sénégal', 'Dakar', 14.69, -17.44, 'Africa/Dakar'),
  VilleIntegree('Togo', 'Lomé', 6.13, 1.22, 'Africa/Lome'),
  VilleIntegree('Burkina Faso', 'Ouagadougou', 12.37, -1.53, 'Africa/Ouagadougou'),
  VilleIntegree('Niger', 'Niamey', 13.51, 2.11, 'Africa/Niamey'),
  VilleIntegree('Cameroun', 'Douala', 4.05, 9.70, 'Africa/Douala'),
  VilleIntegree('Cameroun', 'Yaoundé', 3.87, 11.52, 'Africa/Douala'),
  VilleIntegree('RD Congo', 'Kinshasa', -4.44, 15.27, 'Africa/Kinshasa'),
  VilleIntegree('Gabon', 'Libreville', 0.39, 9.45, 'Africa/Libreville'),
  // Afrique du Nord / Israël
  VilleIntegree('Israël', 'Jérusalem', 31.7683, 35.2137, 'Asia/Jerusalem'),
  VilleIntegree('Israël', 'Tel Aviv', 32.0853, 34.7818, 'Asia/Jerusalem'),
  VilleIntegree('Égypte', 'Le Caire', 30.04, 31.24, 'Africa/Cairo'),
  VilleIntegree('Maroc', 'Casablanca', 33.57, -7.59, 'Africa/Casablanca'),
  // Europe
  VilleIntegree('France', 'Paris', 48.8566, 2.3522, 'Europe/Paris'),
  VilleIntegree('France', 'Marseille', 43.2965, 5.3698, 'Europe/Paris'),
  VilleIntegree('France', 'Lyon', 45.7640, 4.8357, 'Europe/Paris'),
  VilleIntegree('Belgique', 'Bruxelles', 50.8503, 4.3517, 'Europe/Brussels'),
  VilleIntegree('Suisse', 'Genève', 46.2044, 6.1432, 'Europe/Zurich'),
  VilleIntegree('Suisse', 'Lausanne', 46.5197, 6.6323, 'Europe/Zurich'),
  VilleIntegree('Canada', 'Montréal', 45.5017, -73.5673, 'America/Toronto'),
  VilleIntegree('Haïti', 'Port-au-Prince', 18.5944, -72.3074, 'America/Port-au-Prince'),
  // Divers
  VilleIntegree('États-Unis', 'New York', 40.7128, -74.0060, 'America/New_York'),
  VilleIntegree('Brésil', 'São Paulo', -23.5505, -46.6333, 'America/Sao_Paulo'),
  VilleIntegree('Réunion', 'Saint-Denis', -20.8789, 55.4481, 'Indian/Reunion'),
  VilleIntegree('Polynésie française', 'Papeete', -17.5516, -149.5570, 'Pacific/Tahiti'),
];
