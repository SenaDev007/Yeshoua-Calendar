/// Configuration Horloge Céleste + villes intégrées pour la localisation manuelle
/// (§9.2 — choisir son pays et sa ville SANS connexion).
library;

class AppConfig {
  AppConfig._();

  /// Nom et signature de l'application.
  static const String nomApp = 'Horloge Céleste';
  static const String signature = 'Le temps de l’alliance de l’Éternel';

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

  const VilleIntegree(
      this.pays, this.ville, this.latitude, this.longitude, this.fuseau);
}

/// VILLES INTÉGRÉES HORS CONNEXION (§9.2) — TOUS LES PAYS DU MONDE :
/// chaque État souverain y figure avec sa capitale (coordonnées précises et
/// fuseau IANA), complété par les grandes villes et les territoires
/// francophones d'outre-mer. Aucune API de géocodage n'est requise :
/// l'utilisateur peut choisir n'importe quel pays de la planète hors ligne,
/// et la localisation GPS automatique reste disponible pour sa position exacte.
const List<VilleIntegree> villesIntegreees = [
  VilleIntegree(
      'Afrique du Sud', 'Pretoria', -25.75, 28.19, 'Africa/Johannesburg'),
  VilleIntegree('Algérie', 'Alger', 36.75, 3.06, 'Africa/Algiers'),
  VilleIntegree('Angola', 'Luanda', -8.84, 13.23, 'Africa/Luanda'),
  VilleIntegree('Bénin', 'Porto-Novo', 6.49, 2.6, 'Africa/Porto-Novo'),
  VilleIntegree('Botswana', 'Gaborone', -24.65, 25.91, 'Africa/Gaborone'),
  VilleIntegree(
      'Burkina Faso', 'Ouagadougou', 12.37, -1.53, 'Africa/Ouagadougou'),
  VilleIntegree('Burundi', 'Gitega', -3.43, 29.93, 'Africa/Bujumbura'),
  VilleIntegree('Cameroun', 'Yaoundé', 3.87, 11.52, 'Africa/Douala'),
  VilleIntegree('Cap-Vert', 'Praia', 14.93, -23.51, 'Atlantic/Cape_Verde'),
  VilleIntegree('Centrafrique', 'Bangui', 4.36, 18.56, 'Africa/Bangui'),
  VilleIntegree('Comores', 'Moroni', -11.7, 43.26, 'Africa/Comoro'),
  VilleIntegree(
      'Congo-Brazzaville', 'Brazzaville', -4.26, 15.28, 'Africa/Brazzaville'),
  VilleIntegree('RD Congo', 'Kinshasa', -4.44, 15.27, 'Africa/Kinshasa'),
  VilleIntegree(
      'Côte d\'Ivoire', 'Yamoussoukro', 6.83, -5.29, 'Africa/Abidjan'),
  VilleIntegree('Djibouti', 'Djibouti', 11.59, 43.15, 'Africa/Djibouti'),
  VilleIntegree('Égypte', 'Le Caire', 30.04, 31.24, 'Africa/Cairo'),
  VilleIntegree('Érythrée', 'Asmara', 15.34, 38.93, 'Africa/Asmara'),
  VilleIntegree('Eswatini', 'Mbabane', -26.31, 31.14, 'Africa/Mbabane'),
  VilleIntegree('Éthiopie', 'Addis-Abeba', 9.01, 38.76, 'Africa/Addis_Ababa'),
  VilleIntegree('Gabon', 'Libreville', 0.39, 9.45, 'Africa/Libreville'),
  VilleIntegree('Gambie', 'Banjul', 13.45, -16.58, 'Africa/Banjul'),
  VilleIntegree('Ghana', 'Accra', 5.56, -0.19, 'Africa/Accra'),
  VilleIntegree('Guinée', 'Conakry', 9.64, -13.58, 'Africa/Conakry'),
  VilleIntegree('Guinée-Bissau', 'Bissau', 11.86, -15.6, 'Africa/Bissau'),
  VilleIntegree('Guinée équatoriale', 'Malabo', 3.75, 8.78, 'Africa/Malabo'),
  VilleIntegree('Kenya', 'Nairobi', -1.29, 36.82, 'Africa/Nairobi'),
  VilleIntegree('Lesotho', 'Maseru', -29.31, 27.48, 'Africa/Maseru'),
  VilleIntegree('Liberia', 'Monrovia', 6.3, -10.8, 'Africa/Monrovia'),
  VilleIntegree('Libye', 'Tripoli', 32.89, 13.19, 'Africa/Tripoli'),
  VilleIntegree(
      'Madagascar', 'Antananarivo', -18.88, 47.51, 'Indian/Antananarivo'),
  VilleIntegree('Malawi', 'Lilongwe', -13.96, 33.79, 'Africa/Blantyre'),
  VilleIntegree('Mali', 'Bamako', 12.65, -8.0, 'Africa/Bamako'),
  VilleIntegree('Maroc', 'Rabat', 34.02, -6.84, 'Africa/Casablanca'),
  VilleIntegree('Maurice', 'Port-Louis', -20.16, 57.5, 'Indian/Mauritius'),
  VilleIntegree('Mauritanie', 'Nouakchott', 18.08, -15.98, 'Africa/Nouakchott'),
  VilleIntegree('Mozambique', 'Maputo', -25.97, 32.57, 'Africa/Maputo'),
  VilleIntegree('Namibie', 'Windhoek', -22.56, 17.08, 'Africa/Windhoek'),
  VilleIntegree('Niger', 'Niamey', 13.51, 2.11, 'Africa/Niamey'),
  VilleIntegree('Nigeria', 'Abuja', 9.06, 7.49, 'Africa/Lagos'),
  VilleIntegree('Ouganda', 'Kampala', 0.35, 32.58, 'Africa/Kampala'),
  VilleIntegree('Rwanda', 'Kigali', -1.94, 30.06, 'Africa/Kigali'),
  VilleIntegree(
      'Sao Tomé-et-Principe', 'São Tomé', 0.34, 6.73, 'Africa/Sao_Tome'),
  VilleIntegree('Sénégal', 'Dakar', 14.69, -17.44, 'Africa/Dakar'),
  VilleIntegree('Seychelles', 'Victoria', -4.62, 55.45, 'Indian/Mahe'),
  VilleIntegree('Sierra Leone', 'Freetown', 8.48, -13.23, 'Africa/Freetown'),
  VilleIntegree('Somalie', 'Mogadiscio', 2.04, 45.34, 'Africa/Mogadishu'),
  VilleIntegree('Soudan', 'Khartoum', 15.5, 32.56, 'Africa/Khartoum'),
  VilleIntegree('Soudan du Sud', 'Djouba', 4.85, 31.58, 'Africa/Juba'),
  VilleIntegree('Tanzanie', 'Dodoma', -6.16, 35.75, 'Africa/Dar_es_Salaam'),
  VilleIntegree('Tchad', 'N\'Djaména', 12.11, 15.04, 'Africa/Ndjamena'),
  VilleIntegree('Togo', 'Lomé', 6.13, 1.22, 'Africa/Lome'),
  VilleIntegree('Tunisie', 'Tunis', 36.81, 10.18, 'Africa/Tunis'),
  VilleIntegree('Zambie', 'Lusaka', -15.39, 28.32, 'Africa/Lusaka'),
  VilleIntegree('Zimbabwe', 'Harare', -17.83, 31.05, 'Africa/Harare'),
  VilleIntegree('Bénin', 'Cotonou', 6.37, 2.42, 'Africa/Porto-Novo'),
  VilleIntegree('Bénin', 'Parakou', 9.34, 2.62, 'Africa/Porto-Novo'),
  VilleIntegree('Nigeria', 'Lagos', 6.52, 3.38, 'Africa/Lagos'),
  VilleIntegree('Côte d\'Ivoire', 'Abidjan', 5.36, -4.01, 'Africa/Abidjan'),
  VilleIntegree('Cameroun', 'Douala', 4.05, 9.7, 'Africa/Douala'),
  VilleIntegree('Maroc', 'Casablanca', 33.57, -7.59, 'Africa/Casablanca'),
  VilleIntegree('RD Congo', 'Lubumbashi', -11.66, 27.48, 'Africa/Lubumbashi'),
  VilleIntegree('Kenya', 'Mombasa', -4.04, 39.67, 'Africa/Nairobi'),
  VilleIntegree(
      'Tanzanie', 'Dar es Salaam', -6.79, 39.21, 'Africa/Dar_es_Salaam'),
  VilleIntegree('Angola', 'Lobito', -12.36, 13.55, 'Africa/Luanda'),
  VilleIntegree('Ghana', 'Kumasi', 6.69, -1.62, 'Africa/Accra'),
  VilleIntegree(
      'Antigua-et-Barbuda', 'Saint John\'s', 17.12, -61.85, 'America/Antigua'),
  VilleIntegree('Argentine', 'Buenos Aires', -34.6, -58.38,
      'America/Argentina/Buenos_Aires'),
  VilleIntegree('Bahamas', 'Nassau', 25.06, -77.35, 'America/Nassau'),
  VilleIntegree('Barbade', 'Bridgetown', 13.1, -59.62, 'America/Barbados'),
  VilleIntegree('Belize', 'Belmopan', 17.25, -88.77, 'America/Belize'),
  VilleIntegree('Bolivie', 'La Paz', -16.5, -68.15, 'America/La_Paz'),
  VilleIntegree('Brésil', 'Brasilia', -15.79, -47.88, 'America/Sao_Paulo'),
  VilleIntegree('Canada', 'Ottawa', 45.42, -75.7, 'America/Toronto'),
  VilleIntegree('Chili', 'Santiago', -33.45, -70.67, 'America/Santiago'),
  VilleIntegree('Colombie', 'Bogota', 4.71, -74.07, 'America/Bogota'),
  VilleIntegree('Costa Rica', 'San José', 9.93, -84.08, 'America/Costa_Rica'),
  VilleIntegree('Cuba', 'La Havane', 23.11, -82.37, 'America/Havana'),
  VilleIntegree('Dominique', 'Roseau', 15.3, -61.39, 'America/Dominica'),
  VilleIntegree('Équateur', 'Quito', -0.18, -78.47, 'America/Guayaquil'),
  VilleIntegree('États-Unis', 'Washington', 38.9, -77.04, 'America/New_York'),
  VilleIntegree('Grenade', 'Saint George\'s', 12.06, -61.75, 'America/Grenada'),
  VilleIntegree('Guatemala', 'Guatemala', 14.63, -90.51, 'America/Guatemala'),
  VilleIntegree('Guyana', 'Georgetown', 6.8, -58.16, 'America/Guyana'),
  VilleIntegree(
      'Haïti', 'Port-au-Prince', 18.59, -72.31, 'America/Port-au-Prince'),
  VilleIntegree(
      'Honduras', 'Tegucigalpa', 14.07, -87.19, 'America/Tegucigalpa'),
  VilleIntegree('Jamaïque', 'Kingston', 17.97, -76.79, 'America/Jamaica'),
  VilleIntegree('Mexique', 'Mexico', 19.43, -99.13, 'America/Mexico_City'),
  VilleIntegree('Nicaragua', 'Managua', 12.11, -86.24, 'America/Managua'),
  VilleIntegree('Panama', 'Panama', 8.98, -79.52, 'America/Panama'),
  VilleIntegree('Paraguay', 'Asunción', -25.28, -57.63, 'America/Asuncion'),
  VilleIntegree('Pérou', 'Lima', -12.05, -77.04, 'America/Lima'),
  VilleIntegree('République dominicaine', 'Santo Domingo', 18.49, -69.93,
      'America/Santo_Domingo'),
  VilleIntegree('Saint-Christophe-et-Niévès', 'Basseterre', 17.3, -62.72,
      'America/St_Kitts'),
  VilleIntegree('Sainte-Lucie', 'Castries', 14.01, -60.99, 'America/St_Lucia'),
  VilleIntegree('Saint-Vincent-et-les-Grenadines', 'Kingstown', 13.16, -61.22,
      'America/St_Vincent'),
  VilleIntegree(
      'Salvador', 'San Salvador', 13.69, -89.19, 'America/El_Salvador'),
  VilleIntegree('Suriname', 'Paramaribo', 5.85, -55.2, 'America/Paramaribo'),
  VilleIntegree('Trinité-et-Tobago', 'Port-d\'Espagne', 10.65, -61.51,
      'America/Port_of_Spain'),
  VilleIntegree('Uruguay', 'Montevideo', -34.9, -56.16, 'America/Montevideo'),
  VilleIntegree('Venezuela', 'Caracas', 10.49, -66.88, 'America/Caracas'),
  VilleIntegree('États-Unis', 'New York', 40.71, -74.01, 'America/New_York'),
  VilleIntegree(
      'États-Unis', 'Los Angeles', 34.05, -118.24, 'America/Los_Angeles'),
  VilleIntegree('États-Unis', 'Chicago', 41.88, -87.63, 'America/Chicago'),
  VilleIntegree('Brésil', 'São Paulo', -23.55, -46.63, 'America/Sao_Paulo'),
  VilleIntegree('Canada', 'Montréal', 45.5, -73.57, 'America/Toronto'),
  VilleIntegree(
      'Argentine', 'Córdoba', -31.42, -64.18, 'America/Argentina/Cordoba'),
  VilleIntegree(
      'Mexique', 'Guadalajara', 20.67, -103.35, 'America/Mexico_City'),
  VilleIntegree('Afghanistan', 'Kaboul', 34.53, 69.17, 'Asia/Kabul'),
  VilleIntegree('Arabie saoudite', 'Riyad', 24.71, 46.68, 'Asia/Riyadh'),
  VilleIntegree('Arménie', 'Erevan', 40.18, 44.51, 'Asia/Yerevan'),
  VilleIntegree('Azerbaïdjan', 'Bakou', 40.41, 49.87, 'Asia/Baku'),
  VilleIntegree('Bahreïn', 'Manama', 26.23, 50.59, 'Asia/Bahrain'),
  VilleIntegree('Bangladesh', 'Dacca', 23.81, 90.41, 'Asia/Dhaka'),
  VilleIntegree('Bhoutan', 'Thimphou', 27.47, 89.64, 'Asia/Thimphu'),
  VilleIntegree('Birmanie', 'Naypyidaw', 19.75, 96.1, 'Asia/Yangon'),
  VilleIntegree('Brunei', 'Bandar Seri Begawan', 4.9, 114.94, 'Asia/Brunei'),
  VilleIntegree('Cambodge', 'Phnom Penh', 11.56, 104.92, 'Asia/Phnom_Penh'),
  VilleIntegree('Chine', 'Pékin', 39.9, 116.41, 'Asia/Shanghai'),
  VilleIntegree('Corée du Nord', 'Pyongyang', 39.03, 125.75, 'Asia/Pyongyang'),
  VilleIntegree('Corée du Sud', 'Séoul', 37.57, 126.98, 'Asia/Seoul'),
  VilleIntegree('Émirats arabes unis', 'Abu Dhabi', 24.45, 54.38, 'Asia/Dubai'),
  VilleIntegree('Géorgie', 'Tbilissi', 41.72, 44.79, 'Asia/Tbilisi'),
  VilleIntegree('Inde', 'New Delhi', 28.61, 77.21, 'Asia/Kolkata'),
  VilleIntegree('Indonésie', 'Jakarta', -6.21, 106.85, 'Asia/Jakarta'),
  VilleIntegree('Irak', 'Bagdad', 33.31, 44.36, 'Asia/Baghdad'),
  VilleIntegree('Iran', 'Téhéran', 35.69, 51.39, 'Asia/Tehran'),
  VilleIntegree('Israël', 'Jérusalem', 31.77, 35.21, 'Asia/Jerusalem'),
  VilleIntegree('Japon', 'Tokyo', 35.68, 139.69, 'Asia/Tokyo'),
  VilleIntegree('Jordanie', 'Amman', 31.95, 35.93, 'Asia/Amman'),
  VilleIntegree('Kazakhstan', 'Astana', 51.17, 71.43, 'Asia/Almaty'),
  VilleIntegree('Kirghizistan', 'Bichkek', 42.87, 74.59, 'Asia/Bishkek'),
  VilleIntegree('Koweït', 'Koweït', 29.38, 47.99, 'Asia/Kuwait'),
  VilleIntegree('Laos', 'Vientiane', 17.97, 102.63, 'Asia/Vientiane'),
  VilleIntegree('Liban', 'Beyrouth', 33.89, 35.5, 'Asia/Beirut'),
  VilleIntegree('Malaisie', 'Kuala Lumpur', 3.14, 101.69, 'Asia/Kuala_Lumpur'),
  VilleIntegree('Maldives', 'Malé', 4.17, 73.51, 'Indian/Maldives'),
  VilleIntegree('Mongolie', 'Oulan-Bator', 47.89, 106.91, 'Asia/Ulaanbaatar'),
  VilleIntegree('Népal', 'Katmandou', 27.72, 85.32, 'Asia/Kathmandu'),
  VilleIntegree('Oman', 'Mascate', 23.59, 58.41, 'Asia/Muscat'),
  VilleIntegree('Ouzbékistan', 'Tachkent', 41.3, 69.24, 'Asia/Tashkent'),
  VilleIntegree('Pakistan', 'Islamabad', 33.68, 73.05, 'Asia/Karachi'),
  VilleIntegree('Palestine', 'Ramallah', 31.9, 35.2, 'Asia/Hebron'),
  VilleIntegree('Philippines', 'Manille', 14.6, 120.98, 'Asia/Manila'),
  VilleIntegree('Qatar', 'Doha', 25.29, 51.53, 'Asia/Qatar'),
  VilleIntegree('Singapour', 'Singapour', 1.35, 103.82, 'Asia/Singapore'),
  VilleIntegree('Sri Lanka', 'Colombo', 6.93, 79.86, 'Asia/Colombo'),
  VilleIntegree('Syrie', 'Damas', 33.51, 36.29, 'Asia/Damascus'),
  VilleIntegree('Tadjikistan', 'Douchanbé', 38.56, 68.79, 'Asia/Dushanbe'),
  VilleIntegree('Taïwan', 'Taipei', 25.03, 121.57, 'Asia/Taipei'),
  VilleIntegree('Thaïlande', 'Bangkok', 13.76, 100.5, 'Asia/Bangkok'),
  VilleIntegree('Timor oriental', 'Dili', -8.56, 125.58, 'Asia/Dili'),
  VilleIntegree('Turquie', 'Ankara', 39.93, 32.86, 'Europe/Istanbul'),
  VilleIntegree('Turkménistan', 'Achgabat', 37.95, 58.38, 'Asia/Ashgabat'),
  VilleIntegree('Viêt Nam', 'Hanoï', 21.03, 105.85, 'Asia/Ho_Chi_Minh'),
  VilleIntegree('Yémen', 'Sanaa', 15.37, 44.19, 'Asia/Aden'),
  VilleIntegree('Inde', 'Mumbai', 19.08, 72.88, 'Asia/Kolkata'),
  VilleIntegree('Israël', 'Tel Aviv', 32.09, 34.78, 'Asia/Jerusalem'),
  VilleIntegree('Chine', 'Shanghai', 31.23, 121.47, 'Asia/Shanghai'),
  VilleIntegree('Indonésie', 'Surabaya', -7.25, 112.75, 'Asia/Jakarta'),
  VilleIntegree('Pakistan', 'Karachi', 24.86, 67.01, 'Asia/Karachi'),
  VilleIntegree('Albanie', 'Tirana', 41.33, 19.82, 'Europe/Tirane'),
  VilleIntegree('Allemagne', 'Berlin', 52.52, 13.4, 'Europe/Berlin'),
  VilleIntegree('Andorre', 'Andorra-la-Vieille', 42.51, 1.52, 'Europe/Andorra'),
  VilleIntegree('Autriche', 'Vienne', 48.21, 16.37, 'Europe/Vienna'),
  VilleIntegree('Belgique', 'Bruxelles', 50.85, 4.35, 'Europe/Brussels'),
  VilleIntegree('Biélorussie', 'Minsk', 53.9, 27.57, 'Europe/Minsk'),
  VilleIntegree('Bulgarie', 'Sofia', 42.7, 23.32, 'Europe/Sofia'),
  VilleIntegree('Chypre', 'Nicosie', 35.19, 33.38, 'Asia/Nicosia'),
  VilleIntegree('Croatie', 'Zagreb', 45.81, 15.98, 'Europe/Zagreb'),
  VilleIntegree('Danemark', 'Copenhague', 55.68, 12.57, 'Europe/Copenhagen'),
  VilleIntegree('Espagne', 'Madrid', 40.42, -3.7, 'Europe/Madrid'),
  VilleIntegree('Estonie', 'Tallinn', 59.44, 24.75, 'Europe/Tallinn'),
  VilleIntegree('Finlande', 'Helsinki', 60.17, 24.94, 'Europe/Helsinki'),
  VilleIntegree('France', 'Paris', 48.86, 2.35, 'Europe/Paris'),
  VilleIntegree('Grèce', 'Athènes', 37.98, 23.73, 'Europe/Athens'),
  VilleIntegree('Hongrie', 'Budapest', 47.5, 19.04, 'Europe/Budapest'),
  VilleIntegree('Irlande', 'Dublin', 53.35, -6.26, 'Europe/Dublin'),
  VilleIntegree('Islande', 'Reykjavik', 64.15, -21.94, 'Atlantic/Reykjavik'),
  VilleIntegree('Italie', 'Rome', 41.9, 12.5, 'Europe/Rome'),
  VilleIntegree('Lettonie', 'Riga', 56.95, 24.11, 'Europe/Riga'),
  VilleIntegree('Liechtenstein', 'Vaduz', 47.14, 9.52, 'Europe/Vaduz'),
  VilleIntegree('Lituanie', 'Vilnius', 54.69, 25.28, 'Europe/Vilnius'),
  VilleIntegree('Luxembourg', 'Luxembourg', 49.61, 6.13, 'Europe/Luxembourg'),
  VilleIntegree('Macédoine du Nord', 'Skopje', 41.99, 21.43, 'Europe/Skopje'),
  VilleIntegree('Malte', 'La Valette', 35.9, 14.51, 'Europe/Malta'),
  VilleIntegree('Moldavie', 'Chisinau', 47.01, 28.86, 'Europe/Chisinau'),
  VilleIntegree('Monaco', 'Monaco', 43.74, 7.42, 'Europe/Monaco'),
  VilleIntegree('Monténégro', 'Podgorica', 42.44, 19.26, 'Europe/Podgorica'),
  VilleIntegree('Norvège', 'Oslo', 59.91, 10.75, 'Europe/Oslo'),
  VilleIntegree('Pays-Bas', 'Amsterdam', 52.37, 4.9, 'Europe/Amsterdam'),
  VilleIntegree('Pologne', 'Varsovie', 52.23, 21.01, 'Europe/Warsaw'),
  VilleIntegree('Portugal', 'Lisbonne', 38.72, -9.14, 'Europe/Lisbon'),
  VilleIntegree('Roumanie', 'Bucarest', 44.43, 26.1, 'Europe/Bucharest'),
  VilleIntegree('Royaume-Uni', 'Londres', 51.51, -0.13, 'Europe/London'),
  VilleIntegree('Russie', 'Moscou', 55.76, 37.62, 'Europe/Moscow'),
  VilleIntegree(
      'Saint-Marin', 'Saint-Marin', 43.94, 12.45, 'Europe/San_Marino'),
  VilleIntegree('Serbie', 'Belgrade', 44.79, 20.45, 'Europe/Belgrade'),
  VilleIntegree('Slovaquie', 'Bratislava', 48.15, 17.11, 'Europe/Bratislava'),
  VilleIntegree('Slovénie', 'Ljubljana', 46.06, 14.51, 'Europe/Ljubljana'),
  VilleIntegree('Suède', 'Stockholm', 59.33, 18.07, 'Europe/Stockholm'),
  VilleIntegree('Suisse', 'Berne', 46.95, 7.45, 'Europe/Zurich'),
  VilleIntegree('Tchéquie', 'Prague', 50.08, 14.44, 'Europe/Prague'),
  VilleIntegree('Ukraine', 'Kyiv', 50.45, 30.52, 'Europe/Kyiv'),
  VilleIntegree('Vatican', 'Cité du Vatican', 41.9, 12.45, 'Europe/Rome'),
  VilleIntegree('France', 'Lyon', 45.76, 4.84, 'Europe/Paris'),
  VilleIntegree('France', 'Marseille', 43.3, 5.37, 'Europe/Paris'),
  VilleIntegree('Suisse', 'Genève', 46.2, 6.14, 'Europe/Zurich'),
  VilleIntegree('Suisse', 'Lausanne', 46.52, 6.63, 'Europe/Zurich'),
  VilleIntegree('Belgique', 'Anvers', 51.22, 4.4, 'Europe/Brussels'),
  VilleIntegree('Allemagne', 'Francfort', 50.11, 8.68, 'Europe/Berlin'),
  VilleIntegree('Espagne', 'Barcelone', 41.39, 2.17, 'Europe/Madrid'),
  VilleIntegree('Italie', 'Milan', 45.46, 9.19, 'Europe/Rome'),
  VilleIntegree('Royaume-Uni', 'Manchester', 53.48, -2.24, 'Europe/London'),
  VilleIntegree('Australie', 'Canberra', -35.28, 149.13, 'Australia/Sydney'),
  VilleIntegree('Fidji', 'Suva', -18.14, 178.44, 'Pacific/Fiji'),
  VilleIntegree('Kiribati', 'Tarawa', 1.33, 172.98, 'Pacific/Tarawa'),
  VilleIntegree('Îles Marshall', 'Majuro', 7.09, 171.38, 'Pacific/Majuro'),
  VilleIntegree('Micronésie', 'Palikir', 6.92, 158.16, 'Pacific/Pohnpei'),
  VilleIntegree('Nauru', 'Yaren', -0.55, 166.92, 'Pacific/Nauru'),
  VilleIntegree(
      'Nouvelle-Zélande', 'Wellington', -41.29, 174.78, 'Pacific/Auckland'),
  VilleIntegree('Palaos', 'Ngerulmud', 7.5, 134.62, 'Pacific/Palau'),
  VilleIntegree('Papouasie-Nouvelle-Guinée', 'Port Moresby', -9.44, 147.18,
      'Pacific/Port_Moresby'),
  VilleIntegree('Samoa', 'Apia', -13.83, -171.77, 'Pacific/Apia'),
  VilleIntegree(
      'Îles Salomon', 'Honiara', -9.44, 159.95, 'Pacific/Guadalcanal'),
  VilleIntegree('Tonga', 'Nuku\'alofa', -21.14, -175.2, 'Pacific/Tongatapu'),
  VilleIntegree('Tuvalu', 'Funafuti', -8.52, 179.2, 'Pacific/Funafuti'),
  VilleIntegree('Vanuatu', 'Port-Vila', -17.73, 168.32, 'Pacific/Efate'),
  VilleIntegree(
      'Guadeloupe', 'Basse-Terre', 16.0, -61.73, 'America/Guadeloupe'),
  VilleIntegree(
      'Martinique', 'Fort-de-France', 14.6, -61.08, 'America/Martinique'),
  VilleIntegree('Guyane française', 'Cayenne', 4.94, -52.33, 'America/Cayenne'),
  VilleIntegree('Mayotte', 'Mamoudzou', -12.78, 45.23, 'Indian/Mayotte'),
  VilleIntegree('Réunion', 'Saint-Denis', -20.88, 55.45, 'Indian/Reunion'),
  VilleIntegree(
      'Nouvelle-Calédonie', 'Nouméa', -22.28, 166.46, 'Pacific/Noumea'),
  VilleIntegree(
      'Polynésie française', 'Papeete', -17.55, -149.56, 'Pacific/Tahiti'),
  VilleIntegree('Corse', 'Ajaccio', 41.92, 8.74, 'Europe/Paris'),
];
