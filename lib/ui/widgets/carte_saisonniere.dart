/// ⭐ EMBELLISSEMENT SAISONNIER — même principe que la page web
/// « calendrier biblique » du Mouvement Christ Libère : les trois vues du
/// calendrier sont habillées d'une IMAGE DE SAISON sous un voile dégradé.
///
/// DEUX VERSIONS d'image par saison (versions 1 et 2 du dossier public) :
/// l'affichage BASCULE automatiquement entre les deux toutes les deux
/// heures au fil de la journée (§11 — visuel vivant, jamais figé).
///
/// Les quatre images proviennent du dépôt web mouvement-Christ-Libere
/// (mêmes paysages Unsplash que la page /calendrier-biblique) ; les voiles
/// sont adaptés à la palette Horloge Céleste (ardoise / bleu céleste / or)
/// au lieu du pourpre de l'ancienne charte.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Les quatre saisons bibliques (trimestres de l'année de 364 jours).
enum SaisonBiblique { printemps, ete, automne, hiver }

class ImageSaison {
  ImageSaison._();

  /// Asset de l'image de saison — mêmes visuels que la page web.
  static const Map<SaisonBiblique, String> assets = {
    SaisonBiblique.printemps: 'assets/images/saison-printemps.jpg',
    SaisonBiblique.ete: 'assets/images/saison-ete.jpg',
    SaisonBiblique.automne: 'assets/images/saison-automne.jpg',
    SaisonBiblique.hiver: 'assets/images/saison-hiver.jpg',
  };

  /// SECONDE VERSION de chaque image de saison (dossier public/images :
  /// autumn / summer / winter / spring) — alternée avec la première.
  static const Map<SaisonBiblique, String> assets2 = {
    SaisonBiblique.printemps: 'assets/images/saison-printemps-2.jpg',
    SaisonBiblique.ete: 'assets/images/saison-ete-2.jpg',
    SaisonBiblique.automne: 'assets/images/saison-automne-2.jpg',
    SaisonBiblique.hiver: 'assets/images/saison-hiver-2.jpg',
  };

  /// Durée d'une variante d'image : l'affichage bascule v1 ⇄ v2 toutes
  /// les deux heures (§11 — « chaque 2 heures ou chaque 1 heure »).
  static const int dureeAlternanceHeures = 2;

  /// Asset de saison à afficher à [maintenant] : bascule entre les deux
  /// versions toutes les [dureeAlternanceHeures] heures, toute la journée.
  static String assetPour(SaisonBiblique saison, DateTime maintenant) {
    final creneau = maintenant.hour ~/ dureeAlternanceHeures;
    return (creneau.isOdd ? assets2 : assets)[saison]!;
  }

  static const Map<SaisonBiblique, String> noms = {
    SaisonBiblique.printemps: 'Printemps',
    SaisonBiblique.ete: 'Été',
    SaisonBiblique.automne: 'Automne',
    SaisonBiblique.hiver: 'Hiver',
  };

  /// Saison correspondant à un trimestre biblique (1-4).
  static SaisonBiblique depuisTrimestre(int trimestre) =>
      SaisonBiblique.values[(trimestre - 1).clamp(0, 3)];

  /// Saison du trimestre contenant [date] (approximation civile :
  /// 1ᵉʳ Aviv ≈ équinoxe de mars → mars-mai Printemps, etc.).
  static SaisonBiblique approx(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return SaisonBiblique.printemps;
    if (m >= 6 && m <= 8) return SaisonBiblique.ete;
    if (m >= 9 && m <= 11) return SaisonBiblique.automne;
    return SaisonBiblique.hiver;
  }

  /// Voile dégradé de la saison — dérivés des overlays du web, exprimés
  /// dans la palette Horloge Céleste (ardoise #1E293B, bleu #3B82F6, or).
  static Gradient voile(SaisonBiblique saison) {
    const ardoise = Color(0xFF1E293B);
    const bleu = Color(0xFF3B82F6);
    const or = Color(0xFFCFA63A);
    return switch (saison) {
      SaisonBiblique.printemps => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ardoise.withValues(alpha: 0.90),
            bleu.withValues(alpha: 0.55),
            or.withValues(alpha: 0.30)
          ],
        ),
      SaisonBiblique.ete => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bleu.withValues(alpha: 0.85),
            or.withValues(alpha: 0.42),
            ardoise.withValues(alpha: 0.72)
          ],
        ),
      SaisonBiblique.automne => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ardoise.withValues(alpha: 0.88),
            or.withValues(alpha: 0.45),
            or.withValues(alpha: 0.32)
          ],
        ),
      SaisonBiblique.hiver => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ardoise.withValues(alpha: 0.92),
            bleu.withValues(alpha: 0.35),
            ardoise.withValues(alpha: 0.80)
          ],
        ),
    };
  }
}

/// Carte habillée d'une image de saison sous voile dégradé — miroir des
/// cartes « jour en cours » de la page web /calendrier-biblique.
class BandeauSaisonnier extends StatelessWidget {
  const BandeauSaisonnier({
    super.key,
    required this.saison,
    required this.enfant,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.maintenant,
  });

  final SaisonBiblique saison;
  final Widget enfant;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// Instant courant — pilote l'alternance des deux images de saison.
  /// Absent : DateTime.now() (alternance fonctionnelle aussi hors provider).
  final DateTime? maintenant;

  @override
  Widget build(BuildContext context) {
    final asset = ImageSaison.assetPour(saison, maintenant ?? DateTime.now());
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // Image de saison (version 1 ou 2 selon le créneau horaire).
          Positioned.fill(
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Voile dégradé pour la lisibilité (palette Horloge Céleste).
          Positioned.fill(
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: ImageSaison.voile(saison)))),
          // Liseré doré signature.
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                      color: AppColors.orSolaire.withValues(alpha: 0.45)),
                ),
              ),
            ),
          ),
          // Contenu au-dessus du voile.
          Padding(padding: padding, child: enfant),
        ],
      ),
    );
  }
}

/// Bandeau compact de saison (grille mensuelle / vue annuelle) : une
/// frise d'image sous voile avec le nom de la saison et un sous-titre.
class FriseSaisonnier extends StatelessWidget {
  const FriseSaisonnier({
    super.key,
    required this.saison,
    required this.titre,
    required this.sousTitre,
    this.hauteur = 92,
    this.maintenant,
  });

  final SaisonBiblique saison;
  final String titre;
  final String sousTitre;
  final double hauteur;

  /// Instant courant — pilote l'alternance des deux images de saison.
  final DateTime? maintenant;

  @override
  Widget build(BuildContext context) {
    final asset = ImageSaison.assetPour(saison, maintenant ?? DateTime.now());
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: hauteur,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: ImageSaison.voile(saison))),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.orVif,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sousTitre,
                        style: const TextStyle(
                          color: AppColors.blanc,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
