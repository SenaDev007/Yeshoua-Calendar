/// ⭐ FORMATTEURS PARTAGÉS — heures, durées, dates bibliques en français.
library;

/// Format d'heure civile « HH:MM ».
String heureCivilFormat(DateTime d) =>
    '${_2(d.hour)}:${_2(d.minute)}';

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

/// Date longue en français avec les noms du calendrier biblique :
/// « mercredi 18 mars 2026 ». Les noms viennent du moteur (testé) ; aucune
/// dépendance intl n'est nécessaire.
String dateLongueFrancais(DateTime d) {
  const mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  const jours = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche',
  ];
  // Dart weekday : 1 = lundi … 7 = dimanche
  final nomJour = jours[d.weekday - 1];
  return '$nomJour ${d.day} ${mois[d.month - 1]} ${d.year}';
}

String _2(int n) => n.toString().padLeft(2, '0');
