/// 🎨 Charte graphique Horloge Céleste — palette officielle du cahier des charges
/// (§10.1). AUCUN bleu nuit profond : l'identité est lumineuse, spirituelle
/// et premium — bleu céleste dominant, or solaire signature, ivoire/blanc
/// pour la luminosité, ardoise pour les textes.
///
///   • Bleu céleste  #3B82F6 : couleur principale (navigation, boutons,
///     éléments actifs) ;
///   • Or solaire    #CFA63A : signature visuelle (cadran, aiguilles,
///     repères du nouveau jour) ;
///   • Ivoire        #F5F0E6 : fond principal, clair et reposant ;
///   • Blanc         #FFFFFF : cartes et surfaces de contenu ;
///   • Ardoise       #1E293B : textes, icônes et contrastes ;
///   • Gris secondaire #64748B : textes atténués.
library;

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Palette officielle ──
  static const Color bleuCiel = Color(0xFF3B82F6);
  static const Color orSolaire = Color(0xFFCFA63A);
  static const Color ivoire = Color(0xFFF5F0E6);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color ardoise = Color(0xFF1E293B);
  static const Color grisSecondaire = Color(0xFF64748B);

  // ── Dérivés utiles ──
  static const Color bleuCielFonce = Color(0xFF2563EB);
  static const Color bleuCielPastel = Color(0xFFDBEAFE);
  static const Color bleuCielNuit = Color(0xFFEFF6FF);
  static const Color orFonce = Color(0xFFA9832C);
  static const Color orPastel = Color(0xFFE7D3A1);
  static const Color orVif = Color(0xFFF0D68A);
  static const Color ivoireFonce = Color(0xFFEAE2D0);
  static const Color ardoiseClair = Color(0xFF334155);
  static const Color ardoisePastel = Color(0xFFE2E8F0);

  // ── États ──
  static const Color succes = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color enCours = bleuCiel;
  static const Color aVenir = grisSecondaire;

  /// Couleur d'une période en cours selon son type.
  static Color periodeActive(bool nuit) =>
      nuit ? orSolaire : bleuCiel;

  /// Conversion d'une couleur hex « #RRGGBB » (données du calendrier).
  static Color depuisHex(String hex) {
    final propre = hex.replaceFirst('#', '');
    if (propre.length != 6) return orSolaire;
    final valeur = int.tryParse('FF$propre', radix: 16);
    return valeur == null ? orSolaire : Color(valeur);
  }
}
