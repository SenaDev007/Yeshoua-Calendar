/// ⭐ IMAGES SYMBOLIQUES DES FÊTES (§7) — une image professionnelle par
/// solennité, générée sur mesure (design plat, palette or céleste) :
///   • Shabbat          → bougies, pain et coupe de vin sous la nuit dorée ;
///   • Pessah           → agneau immolé dans le linteau de la Pâque ;
///   • Pains sans levain → matzot et coupe de vin ;
///   • Reshit Katzir    → gerbe de prémices ;
///   • Shavouot         → deux pains, blé et tables de la Loi ;
///   • Yom Teroua       → shofar et ondes de son ;
///   • Yom Kippour      → tallit et livre de prière ;
///   • Souccot          → cabane de tabernacles sous la lune ;
///   • Tête de l'année  → soleil de l'équinoxe couronné d'or ;
///   • Shemini Atzeret  → flamme unique et pluie de bénédiction.
/// Les images apparaissent sur les cartes des jours de fête (calendrier,
/// grille et mode cartes) et sur la page « Fêtes & saisons ».
library;

import 'package:flutter/material.dart';

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

/// Asset associé à chaque identifiant de fête (base, sans suffixe de jour).
const Map<String, String> imagesFetes = {
  'shabbat': 'assets/images/fetes/shabbat.png',
  'pessah': 'assets/images/fetes/pessah.png',
  'matsot': 'assets/images/fetes/pains-sans-levain.png',
  'reshit_katzir': 'assets/images/fetes/reshit-katzir.png',
  'shavouot': 'assets/images/fetes/shavouot.png',
  'yom_teroua': 'assets/images/fetes/yom-teroua.png',
  'yom_kippour': 'assets/images/fetes/yom-kippour.png',
  'souccot': 'assets/images/fetes/souccot.png',
  'shemini_atzeret': 'assets/images/fetes/shemini-atzeret.png',
  'tete_annee': 'assets/images/fetes/tete-annee.png',
};

/// Image symbolique d'une fête (identifiant de base sans suffixe « -N »)
/// — chaîne vide si aucune image n'est prévue.
String imagePourFete(FeteBiblique fete) {
  final base = fete.id.replaceFirst(RegExp(r'-\d+$'), '');
  // Les événements « fete-… » du moteur portent l'identifiant complet
  // (ex. fete-pessah-2026) : on isole le nom après le préfixe « fete- ».
  final nom = base.startsWith('fete-') ? base.substring(5) : base;
  for (final cle in imagesFetes.keys) {
    if (nom.startsWith(cle)) return imagesFetes[cle]!;
  }
  return '';
}

/// Image du SHABBAT — pour les cartes des jours de repos saint.
const String imageShabbat = 'assets/images/fetes/shabbat.png';

/// Médaillon arrondi de l'image d'une fête (ou du shabbat).
class MedaillonFete extends StatelessWidget {
  const MedaillonFete({
    super.key,
    required this.asset,
    this.taille = 48,
  });

  final String asset;
  final double taille;

  @override
  Widget build(BuildContext context) {
    if (asset.isEmpty) return const SizedBox.shrink();
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(taille * 0.28),
        border: Border.all(
            color: const Color(0xFFCFA63A).withValues(alpha: 0.75), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCFA63A).withValues(alpha: 0.30),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(taille * 0.28),
        child: Image.asset(
          asset,
          width: taille,
          height: taille,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
