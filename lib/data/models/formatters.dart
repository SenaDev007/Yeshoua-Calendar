/// ⭐ FORMATTEURS PARTAGÉS — heures, durées, dates bibliques en français.
library;

/// Format d'heure civile « HH:MM ».
String heureCivilFormat(DateTime d) => '${_2(d.hour)}:${_2(d.minute)}';

/// Format « HH:MM:SS ».
String heureSecondeFormat(DateTime d) =>
    '${_2(d.hour)}:${_2(d.minute)}:${_2(d.second)}';

/// Compte à rebours « HH:MM:SS » à partir d'une Duration.
String dureeFormat(Duration d) {
  final h = d.inHours;
  final mn = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return '${_2(h)}:${_2(mn)}:${_2(s)}';
}

/// Durée lisible « 3 h 50 » ou « 55 min ».
String dureeLisible(Duration d) {
  final h = d.inHours;
  final mn = d.inMinutes % 60;
  if (h == 0) return '$mn min';
  if (mn == 0) return '$h h';
  return '$h h ${_2(mn)}';
}

// ── Jours et mois : noms complets et ABRÉVIATIONS CONVENTIONNELLES ─────
// Les abréviations évitent les chevauchements (« mercredi », « novembre »)
// dans les vues Jour / Semaine / Mois du calendrier (demande utilisateur).

/// Mois français complets (1 = janvier).
const List<String> moisFrancais = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// Jours français complets (weekday Dart : 1 = lundi … 7 = dimanche).
const List<String> joursFrancais = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// Abréviations conventionnelles des mois (1 = janv.).
const List<String> moisAbreges = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// Abréviations conventionnelles des jours (weekday Dart : 1 = lun.).
const List<String> joursAbreges = [
  'lun.',
  'mar.',
  'mer.',
  'jeu.',
  'ven.',
  'sam.',
  'dim.',
];

/// Translittération HÉBRAÏQUE des sept jours (ordre biblique :
/// jour 1 = Yom Ehad … jour 7 = Yom Shabbat) — indexée comme
/// [joursFrancais] : 1 = lundi → Yom Sheni, 7 = dimanche → Yom Ehad.
const List<String> joursHebreu = [
  'Yom Sheni',
  'Yom Shlishi',
  'Yom Revi\u2019i',
  'Yom Hamishi',
  'Yom Shishi',
  'Yom Shabbat',
  'Yom Ehad',
];

/// Formes COURTES hébraïques (en-têtes de grille et cartes exigues).
const List<String> joursHebreuCourts = [
  'Sheni',
  'Shlishi',
  'Revi\u2019i',
  'Hamishi',
  'Shishi',
  'Shabbat',
  'Ehad',
];

/// Noms de jours du MOTEUR (Dimanche … Samedi) → index 0..6 des listes
/// ci-dessus (Dimanche = 6 en weekday Dart, mais jour 1 biblique).
int _indiceJourMoteur(String nomJourMoteur) {
  const ordre = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
  ];
  final i = ordre.indexOf(nomJourMoteur);
  return i < 0 ? 0 : i;
}

/// Nom du jour AFFICHÉ selon le mode : français du moteur ou
/// translittération hébraïque (mode hébraïque — §7).
String nomJourAffiche(String nomJourMoteur, bool hebreu) =>
    hebreu ? joursHebreu[_indiceJourMoteur(nomJourMoteur)] : nomJourMoteur;

/// Nom du jour abrégé AFFICHÉ : « mer. » / « Shlishi » selon le mode.
String nomJourAfficheCourt(String nomJourMoteur, bool hebreu) {
  final i = _indiceJourMoteur(nomJourMoteur);
  return hebreu ? joursHebreuCourts[i] : joursFrancais[i].substring(0, 3) + '.';
}

/// Abréviation du mois civil : « nov. » (mois 11).
String nomMoisAbrege(int mois) => moisAbreges[(mois - 1).clamp(0, 11)];

/// En-têtes des grilles mensuelles (ordre du moteur : 1 = Dimanche …
/// 7 = Samedi/Shabbat) — abrégés en français, translittérés en hébreu.
List<String> entetesGrille(bool hebreu) => hebreu
    ? const [
        'Ehad',
        'Sheni',
        'Shlishi',
        'Revi\u2019i',
        'Hamishi',
        'Shishi',
        'Shabbat',
      ]
    : const ['Dim.', 'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Shab.'];

/// Date longue en français avec les noms du calendrier biblique :
/// « mercredi 18 mars 2026 ». Les noms viennent du moteur (testé) ; aucune
/// dépendance intl n'est nécessaire.
String dateLongueFrancais(DateTime d) =>
    '${joursFrancais[d.weekday - 1]} ${d.day} ${moisFrancais[d.month - 1]} ${d.year}';

/// Date ABRÉGÉE « mer. 18 nov. 2026 » — pour les espaces exigus du
/// calendrier (vues Semaine / Mois / Cartes — évite tout chevauchement).
String dateCourteFrancais(DateTime d) =>
    '${joursAbreges[d.weekday - 1]} ${d.day} ${moisAbreges[d.month - 1]} ${d.year}';

String _2(int n) => n.toString().padLeft(2, '0');
