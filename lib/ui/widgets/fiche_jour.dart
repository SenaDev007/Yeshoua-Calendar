/// ⭐ FICHE JOUR DÉTAILLÉE — transposition fidèle du panneau `DateInfo.tsx`
/// du projet web « calendrier de YHWH » : lorsqu'on clique sur une date de
/// la grille, on ouvre la ZONE de détail du jour (en-tête en dégradé radial,
/// encart de fête, mesures du jour X/364 et semaine X/52, saison, équivalent
/// grégorien, badges) suivie de la LÉGENDE (même système que la page web).
///
/// Palette : bleu céleste / or solaire / ivoire / ardoise — jamais de bleu
/// nuit profond. Toutes les descriptions proviennent du moteur
/// `horloge_celeste_engine` (aucune donnée inventée).
library;

import 'package:flutter/material.dart';

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import 'images_fetes.dart';

/// Fiche détaillée d'un jour biblique — miroir du composant web DateInfo.
class FicheJour extends StatelessWidget {
  const FicheJour({
    super.key,
    required this.jour,
    required this.annee,
    this.fetes,
    this.modeHebreu = false,
  });

  final JourBiblique jour;
  final AnneeBiblique annee;

  /// Fêtes couvrant ce jour (jour 1 d'une fête ou jours de durée > 1).
  final List<FeteBiblique>? fetes;

  /// MODE HÉBRAÏQUE (§7) : noms des jours en translittération.
  final bool modeHebreu;

  int get _semaine => ((jour.jourDeAnnee - 1) ~/ 7) + 1; // 364 = 52 × 7

  @override
  Widget build(BuildContext context) {
    final fetesDuJour = fetes ?? const <FeteBiblique>[];
    final fetePrincipale = fetesDuJour.isNotEmpty ? fetesDuJour.first : null;
    final saison = _nomSaison(jour.trimestre);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ardoisePastel, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.ardoise.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zone 1 : en-tête en dégradé radial (miroir du header web) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.9),
                radius: 1.7,
                colors: [
                  AppColors.bleuCiel,
                  AppColors.bleuCielFonce,
                  AppColors.ardoiseClair,
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.orVif),
                const SizedBox(width: 8),
                const Text(
                  'Informations détaillées',
                  style: TextStyle(
                    color: AppColors.blanc,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const Spacer(),
                Text(
                  dateCourteFrancais(jour.dateGregorienne),
                  style: const TextStyle(
                    color: AppColors.orVif,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Zone 2 : titre du jour biblique ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.bleuCiel, AppColors.bleuCielFonce],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.orSolaire.withValues(alpha: 0.55),
                            width: 1.4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${jour.jourDuMois}',
                            style: const TextStyle(
                              color: AppColors.blanc,
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            jour.nomMois,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.orVif,
                              fontWeight: FontWeight.w700,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            jour.estShabbat
                                ? 'Shabbat — '
                                    '${nomJourAffiche(jour.nomJourSemaine, modeHebreu)}'
                                : nomJourAffiche(
                                    jour.nomJourSemaine, modeHebreu),
                            style: const TextStyle(
                              color: AppColors.ardoise,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mois ${jour.mois} · ${jour.nomMois} · Saison de $saison',
                            style: const TextStyle(
                              color: AppColors.grisSecondaire,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Zone 3 : encart fête (miroir de l'encart ambre web) ──
                if (fetePrincipale != null) ...[
                  const SizedBox(height: 14),
                  for (final fete in fetesDuJour) _encartFete(fete),
                ],

                // ── Zone 4 : mesures du jour (grille 2 colonnes du web) ──
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _mesure(
                            Icons.event_available_outlined,
                            'Jour de l\u2019année',
                            '${jour.jourDeAnnee} / 364')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _mesure(Icons.all_inclusive_rounded, 'Semaine',
                            '$_semaine / 52')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child:
                            _mesure(Icons.wb_sunny_outlined, 'Saison', saison)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _mesure(Icons.menu_book_outlined, 'Trimestre',
                            'T${jour.trimestre} · Mois ${jour.mois}/12')),
                  ],
                ),
                const SizedBox(height: 10),
                _mesureLarge(
                    Icons.calendar_month_outlined,
                    'Équivalent grégorien',
                    dateCourteFrancais(jour.dateGregorienne),
                    complement:
                        'Jour civil commençant à minuit — le jour biblique, '
                        'lui, commence au coucher du soleil'),

                // ── Zone 5 : badges d'état ──
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (jour.estShabbat) _badge('Shabbat', AppColors.orSolaire),
                    for (final fete in fetesDuJour)
                      _badge(_libelleCategorie(fete.categorie),
                          AppColors.depuisHex(fete.couleur),
                          icone: Icons.star_rounded),
                    _badge('Entrée du jour : coucher du soleil',
                        AppColors.bleuCiel,
                        icone: Icons.wb_twilight_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Encart de fête — description réelle du moteur (jamais inventée) ──
  // Avec l'IMAGE SYMBOLIQUE de la fête (agneau de Pessah, matzot, shofar,
  // cabane de Souccot…) — §7.
  Widget _encartFete(FeteBiblique fete) {
    final couleur = AppColors.depuisHex(fete.couleur);
    final asset = imagePourFete(fete);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: couleur, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (asset.isNotEmpty) ...[
                MedaillonFete(asset: asset, taille: 46),
                const SizedBox(width: 10),
              ],
              Icon(Icons.celebration_outlined, size: 16, color: couleur),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  fete.nomFr,
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (fete.nomHebrew != null && fete.nomHebrew!.isNotEmpty)
                Text(
                  fete.nomHebrew!,
                  style: TextStyle(color: couleur, fontSize: 13.5),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fete.description,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _puce(fete.dateBiblique),
              _puce(dateCourteFrancais(fete.dateGregorienne)),
              if (fete.dureeJours > 1)
                _puce('Durée : ${fete.dureeJours} jours'),
              if (fete.travailInterdit) _puce('Travail interdit'),
              _puce(fete.referenceEcritures),
            ],
          ),
        ],
      ),
    );
  }

  Widget _puce(String texte) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.blanc,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ardoisePastel),
        ),
        child: Text(
          texte,
          style: const TextStyle(
            color: AppColors.ardoise,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _mesure(IconData icone, String label, String valeur) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bleuCielNuit,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.bleuCiel.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 16, color: AppColors.bleuCiel),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.grisSecondaire,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valeur,
                    style: const TextStyle(
                      color: AppColors.ardoise,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _mesureLarge(IconData icone, String label, String valeur,
          {String? complement}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.orSolaire.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orSolaire.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 16, color: AppColors.orFonce),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.grisSecondaire,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valeur,
                    style: const TextStyle(
                      color: AppColors.ardoise,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (complement != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      complement,
                      style: TextStyle(
                        color: AppColors.grisSecondaire.withValues(alpha: 0.85),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _badge(String texte, Color couleur, {IconData? icone}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleur.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, size: 12, color: couleur),
              const SizedBox(width: 4),
            ],
            Text(
              texte,
              style: TextStyle(
                color: couleur,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

  String _libelleCategorie(String categorie) => switch (categorie) {
        'nouvelle_annee' => 'Nouvelle année',
        'convocation_sainte' => 'Convocation sainte',
        'jeune' => 'Jeûne',
        _ => 'Fête de l\u2019Éternel',
      };

  String _nomSaison(int trimestre) => switch (trimestre) {
        1 => 'Printemps',
        2 => 'Été',
        3 => 'Automne',
        _ => 'Hiver',
      };
}

/// ⭐ LÉGENDE — miroir du composant `Legend.tsx` web : les pastilles des
/// couleurs du calendrier, affichée APRÈS la grille / la fiche détaillée.
class LegendeCalendrier extends StatelessWidget {
  const LegendeCalendrier({super.key, this.fetesCategories = true});

  final bool fetesCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blanc.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ardoisePastel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.legend_toggle_rounded,
                  size: 15, color: AppColors.bleuCiel),
              SizedBox(width: 6),
              Text(
                'LÉGENDE',
                style: TextStyle(
                  color: AppColors.ardoise,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _item(AppColors.orSolaire, 'Shabbat (J7)'),
              if (fetesCategories) ...[
                _item(AppColors.bleuCiel, 'Convocation sainte'),
                _item(AppColors.danger, 'Jeûne'),
                _item(AppColors.succes, 'Nouvelle année'),
              ],
              _item(AppColors.ardoise, 'Aujourd\u2019hui', anneau: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(Color couleur, String label, {bool anneau = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: anneau ? AppColors.blanc : couleur,
              shape: BoxShape.circle,
              border: Border.all(color: couleur, width: anneau ? 3 : 1.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}
