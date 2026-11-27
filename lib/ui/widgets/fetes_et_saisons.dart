/// ⭐ MODAL « FÊTES & SAISONS » — transposition fidèle du composant web
/// `FestivalsSection.tsx` : les fêtes de l'Éternel regroupées par saison
/// biblique (trimestres) avec leurs descriptions complètes issues du moteur
/// `horloge_celeste_engine`, présenté dans un panneau coulissant arrondi
/// (miroir du modal web) habillé de l'image de chaque saison.
library;

import 'package:flutter/material.dart';

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import 'carte_saisonniere.dart';

/// Ouvre le panneau « Fêtes & saisons » de l'année biblique donnée.
void ouvrirFetesEtSaisons(BuildContext context, AnneeBiblique annee) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.ivoire,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child:
            _ContenuFetesEtSaisons(annee: annee, scrollController: controller),
      ),
    ),
  );
}

/// Descriptions rédigées des quatre saisons bibliques (trimestres de 91
/// jours) — partagées par le modal « Fêtes & saisons » et la vue Trimestre
/// de l'écran calendrier.
const Map<int, String> descriptionsSaisons = {
  1: 'Le Printemps (Aviv) ouvre l\u2019année biblique à l\u2019équinoxe de mars : '
      'c\u2019est la saison de la sortie d\u2019Égypte, de la Pâque et des Pains '
      'sans levain, puis des Prémices et de Shavouot pendant le comptage du Omer.',
  2: 'L\u2019Été (Kayits) porte la récolte du blé et des fruits ; aucun jour de '
      'convocation n\u2019y figure — c\u2019est la saison du silence et de la '
      'croissance, entre Shavouot et Yom Teroua.',
  3: 'L\u2019Automne (Stav) concentre les solennités majeures : Yom Teroua, '
      'Yom Kippour, Souccot et Shemini Atzeret — le renouvellement de '
      'l\u2019année civile et le retour de la présence.',
  4: 'L\u2019Hiver (Horef) est la saison des pluies et du repos de la terre ; '
      'les shabbats hebdomadaires y rythment seuls le temps de l\u2019alliance, '
      'dans l\u2019attente du retour du printemps.',
};

class _ContenuFetesEtSaisons extends StatelessWidget {
  const _ContenuFetesEtSaisons({
    required this.annee,
    required this.scrollController,
  });

  final AnneeBiblique annee;
  final ScrollController scrollController;

  static const _descriptionsSaisons = descriptionsSaisons;

  @override
  Widget build(BuildContext context) {
    // Une fête peut s'étendre sur plusieurs jours : on groupe par son
    // jour d'ouverture puis on affiche sa durée réelle.
    final fetesOuvertures = <FeteBiblique>[];
    final idsVus = <String>{};
    for (final f in annee.fetes) {
      final idBase = f.id.replaceFirst(RegExp(r'-\d+$'), '');
      if (idsVus.add(idBase)) fetesOuvertures.add(f);
    }
    // Tri calendaire (par jour de l'année biblique).
    fetesOuvertures.sort((a, b) {
      final ja = annee.jourPourDate(a.dateGregorienne);
      final jb = annee.jourPourDate(b.dateGregorienne);
      return (ja?.jourDeAnnee ?? 0).compareTo(jb?.jourDeAnnee ?? 0);
    });

    return Column(
      children: [
        // Poignée de glissement.
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.grisSecondaire.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              Row(
                children: [
                  const Icon(Icons.celebration_outlined,
                      size: 20, color: AppColors.orSolaire),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Fêtes de l\u2019Éternel & saisons',
                      style: TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.grisSecondaire),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                '${annee.libelle} — ${fetesOuvertures.length} solennités et '
                '52 shabbats, au rythme des quatre saisons de l\u2019année de 364 jours.',
                style: const TextStyle(
                  color: AppColors.grisSecondaire,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              for (final trimestre in [1, 2, 3, 4])
                _sectionSaison(trimestre, fetesOuvertures),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionSaison(int trimestre, List<FeteBiblique> fetes) {
    final saison = SaisonBiblique.values[trimestre - 1];
    final nom = ImageSaison.noms[saison]!;
    final fetesSaison = fetes
        .where((f) =>
            annee.jourPourDate(f.dateGregorienne)?.trimestre == trimestre)
        .toList();
    final shabbatsSaison = annee.jours
        .where((j) => j.trimestre == trimestre && j.estShabbat)
        .length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frise de saison — même embellissement que les vues du calendrier.
          FriseSaisonnier(
            saison: saison,
            titre: 'Saison $trimestre · $nom',
            sousTitre: '$shabbatsSaison shabbats · ${fetesSaison.length} '
                'solennité${fetesSaison.length > 1 ? 's' : ''} · 3 mois bibliques',
            hauteur: 96,
          ),
          const SizedBox(height: 10),
          // Description de la saison — rédigée d'après la structure du
          // calendrier (trimestres de 91 jours, convocations de Lévitique 23).
          Text(
            _descriptionsSaisons[trimestre]!,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          if (fetesSaison.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blanc.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.ardoisePastel.withValues(alpha: 0.7)),
              ),
              child: const Text(
                'Aucune convocation sainte cette saison — les shabbats '
                'hebdomadaires rythment seuls le temps.',
                style: TextStyle(color: AppColors.grisSecondaire, fontSize: 12),
              ),
            )
          else
            for (final fete in fetesSaison) _carteFete(fete),
        ],
      ),
    );
  }

  Widget _carteFete(FeteBiblique fete) {
    final couleur = AppColors.depuisHex(fete.couleur);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: couleur, width: 4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ardoise.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fete.nomFr,
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (fete.nomHebrew != null && fete.nomHebrew!.isNotEmpty)
                Text(
                  fete.nomHebrew!,
                  style: TextStyle(color: couleur, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fete.description,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              _puce(
                  '${fete.dateBiblique} · ${dateLongueFrancais(fete.dateGregorienne)}'),
              if (fete.dureeJours > 1)
                _puce('Durée : ${fete.dureeJours} jours'),
              if (fete.travailInterdit) _puce('Travail interdit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _puce(String texte) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.orSolaire.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.orSolaire.withValues(alpha: 0.4)),
        ),
        child: Text(
          texte,
          style: const TextStyle(
            color: AppColors.orFonce,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
