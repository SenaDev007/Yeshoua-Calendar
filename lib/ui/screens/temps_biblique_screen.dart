/// ⭐ ÉCRAN TEMPS BIBLIQUE (§3, §4, §11) — les trois veilles de la nuit
/// (vue circulaire + chronologie), les quatre parties du jour, les douze
/// heures saisonnières (cadran solaire + chronologie). La période en
/// cours est toujours mise en évidence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import '../../state/horloge_controller.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';
import '../widgets/cadran_nuit.dart';
import '../widgets/cadran_solaire.dart';
import '../widgets/cartes.dart';
import '../widgets/chronologies.dart';

class TempsBibliqueScreen extends ConsumerWidget {
  const TempsBibliqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(horlogeProvider);
    final periode = etat.periode;

    if (periode is PeriodeIndisponible) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CarteCeleste(
            bordure: AppColors.orSolaire.withValues(alpha: 0.5),
            enfant: Column(
              children: [
                const Icon(Icons.wb_cloudy_outlined,
                    size: 40, color: AppColors.orSolaire),
                const SizedBox(height: 10),
                Text(
                  (periode).motif,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ardoise, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final enNuit = periode is NuitEnCours;

    // ── Données des deux hémicycles ──
    List<VeilleModel> veillesAffichees = [];
    List<HeureSaisonniereModel> heuresAffichees = [];
    List<PartieJourModel> partiesAffichees = [];

    if (periode is NuitEnCours) {
      veillesAffichees = (periode).veilles;
    } else if (periode is JourEnCours) {
      heuresAffichees = (periode).heures;
      partiesAffichees = (periode).parties;
    }

    // Quand on est le jour, les veilles affichées sont celles de la nuit
    // à venir (coucher → lever suivant) ; quand on est la nuit, les
    // heures affichées sont celles du jour précédent/diurne correspondant.
    if (enNuit && etat.solarJour != null && etat.solarSuivant != null &&
        etat.solarJour!.calculable && etat.solarSuivant!.calculable) {
      heuresAffichees = BiblicalTimeEngine.heuresSaisonniere(
        lever: etat.solarJour!.lever!,
        coucher: etat.solarJour!.coucher!,
        maintenant: etat.maintenant,
      );
      partiesAffichees = BiblicalTimeEngine.partiesDuJour(
        lever: etat.solarJour!.lever!,
        coucher: etat.solarJour!.coucher!,
        maintenant: etat.maintenant,
      );
    }
    if (!enNuit && etat.solarJour != null && etat.solarSuivant != null &&
        etat.solarJour!.calculable && etat.solarSuivant!.calculable) {
      veillesAffichees = BiblicalTimeEngine.veillesDeLaNuit(
        coucher: etat.solarJour!.coucher!,
        lever: etat.solarSuivant!.lever!,
        maintenant: etat.maintenant,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Résumé de position dans le cycle (§11) ──
        CarteCeleste(
          enfant: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    enNuit
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_outlined,
                    size: 16,
                    color: AppColors.periodeActive(enNuit),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    enNuit
                        ? 'VOUS ÊTES DANS LA NUIT BIBLIQUE'
                        : 'VOUS ÊTES DANS LE JOUR BIBLIQUE',
                    style: TextStyle(
                      color: AppColors.periodeActive(enNuit),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                enNuit
                    ? 'La nuit commence au coucher du soleil et se divise en trois veilles '
                        '(Exode 14:24, Juges 7:19). Le nouveau jour biblique a déjà commencé.'
                    : 'Le jour commence au lever du soleil et compte douze heures saisonnières '
                        '(Jean 11:9) — leur durée s\u2019adapte à la longueur réelle du jour.',
                style: const TextStyle(
                  color: AppColors.grisSecondaire,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── LES TROIS VEILLES (§3) ──
        TitreSection(
          'Les trois veilles de la nuit',
          icone: Icons.nightlight_outlined,
        ),
        if (veillesAffichees.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CadranNuit(veilles: veillesAffichees, taille: 148),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final v in veillesAffichees)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: v.statut == StatutPeriode.enCours
                                    ? AppColors.orSolaire
                                    : v.statut == StatutPeriode.terminee
                                        ? AppColors.grisSecondaire
                                            .withValues(alpha: 0.5)
                                        : AppColors.bleuCiel
                                            .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${v.sousTitre}\n${heureCivilFormat(v.debut)} → ${heureCivilFormat(v.fin)}',
                                style: TextStyle(
                                  color: v.statut == StatutPeriode.enCours
                                      ? AppColors.ardoise
                                      : AppColors.grisSecondaire,
                                  fontSize: 11.5,
                                  height: 1.3,
                                  fontWeight: v.statut == StatutPeriode.enCours
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        for (final v in veillesAffichees) LigneVeille(veille: v),

        // ── LES PARTIES DU JOUR (§4.3) ──
        TitreSection(
          'Les quatre parties du jour',
          icone: Icons.wb_sunny_outlined,
        ),
        if (partiesAffichees.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CadranSolaire(
                heures: heuresAffichees,
                parties: partiesAffichees,
                taille: 148,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in partiesAffichees)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${p.designation}\nHeures ${p.de} à ${p.a}',
                          style: TextStyle(
                            color: p.statut == StatutPeriode.enCours
                                ? AppColors.ardoise
                                : AppColors.grisSecondaire,
                            fontSize: 11.5,
                            height: 1.3,
                            fontWeight: p.statut == StatutPeriode.enCours
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        for (final p in partiesAffichees) LignePartieJour(partie: p),

        // ── LES DOUZE HEURES SAISONNIÈRES (§4) ──
        TitreSection(
          'Les douze heures saisonnières',
          icone: Icons.schedule,
        ),
        Text(
          'Durée d\u2019une heure = durée du jour ÷ 12 — pas des heures civiles '
          'de 60 minutes : elles s\u2019allongent et se raccourcissent avec les saisons.',
          style: TextStyle(
            color: AppColors.grisSecondaire.withValues(alpha: 0.95),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        for (final h in heuresAffichees) TuileHeureSaisonniere(heure: h),

        // ── CYCLE COMPLET (§5) ──
        TitreSection(
          'Le cycle complet de la journée biblique',
          icone: Icons.all_inclusive,
        ),
        if (etat.solarJour != null &&
            etat.solarSuivant != null &&
            etat.solarJour!.calculable &&
            etat.solarSuivant!.calculable)
          CarteCeleste(
            enfant: _cycleComplet(
              coucher: etat.solarJour!.coucher!,
              lever: etat.solarSuivant!.lever!,
              coucherSuivant: etat.solarSuivant!.coucher!,
              maintenant: etat.maintenant,
            ),
          ),
      ],
    );
  }

  /// Chronologie des 10 jalons du cycle (§5) avec jalon actif en or.
  Widget _cycleComplet({
    required DateTime coucher,
    required DateTime lever,
    required DateTime coucherSuivant,
    required DateTime maintenant,
  }) {
    final cycle = BiblicalTimeEngine.cycleComplet(
      coucher: coucher,
      lever: lever,
      coucherSuivant: coucherSuivant,
    );
    return Column(
      children: [
        for (var i = 0; i < cycle.length; i++)
          _jalonCycle(
            cycle[i],
            actif: maintenant.isAfter(cycle[i].debut) &&
                (i == cycle.length - 1 ||
                    maintenant.isBefore(cycle[i + 1].debut)),
            premier: i == 0,
            dernier: i == cycle.length - 1,
          ),
      ],
    );
  }

  Widget _jalonCycle(JalonCycle jalon,
      {required bool actif, required bool premier, required bool dernier}) {
    final accent = actif ? AppColors.orSolaire : AppColors.grisSecondaire;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: actif ? AppColors.orSolaire : Colors.transparent,
                  border: Border.all(color: accent, width: 2),
                ),
              ),
              if (!dernier)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.ardoisePastel,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: dernier ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        jalon.nom,
                        style: TextStyle(
                          color: actif ? AppColors.ardoise : AppColors.grisSecondaire,
                          fontWeight: actif ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        heureCivilFormat(jalon.debut),
                        style: TextStyle(
                          color: actif ? AppColors.orFonce : AppColors.grisSecondaire,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    jalon.sousTitre,
                    style: const TextStyle(
                      color: AppColors.grisSecondaire,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
