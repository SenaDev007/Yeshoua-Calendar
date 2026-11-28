/// ⭐ ÉCRAN HORLOGE DIVINE (§6) — bascule numérique ⇄ analogique sans
/// perte d'information : heure civile visible, date biblique, période
/// en cours, compte à rebours vers le prochain changement de jour.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import '../../state/settings_controller.dart';
import '../../state/horloge_controller.dart';
import '../widgets/cartes.dart';
import '../widgets/horloge_analogique.dart';

class HorlogeScreen extends ConsumerWidget {
  const HorlogeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(horlogeProvider);
    final settings = ref.watch(settingsProvider);
    final periode = etat.periode;

    final enNuit = periode is NuitEnCours;

    // Origine du cadran BIBLIQUE 24 h : le DERNIER coucher du soleil réel
    // (heure biblique 01:00, positionnée à gauche du cadran — §6.2).
    DateTime? dernierCoucher;
    if (etat.solarJour?.calculable ?? false) {
      final coucherJour = etat.solarJour!.coucher;
      if (coucherJour != null && !etat.maintenant.isBefore(coucherJour)) {
        dernierCoucher = coucherJour;
      } else {
        dernierCoucher = etat.solarPrecedent?.coucher;
      }
    }

    final labelPeriode = periode is NuitEnCours
        ? _numeroVeille((periode).veille.indice)
        : periode is JourEnCours
            ? 'Heure ${(periode).heure.numero}'
            : 'Indisponible';
    final sousLabel = periode is NuitEnCours
        ? (periode).veille.sousTitre
        : periode is JourEnCours
            ? (periode)
                .parties
                .firstWhere((p) => p.statut == StatutPeriode.enCours,
                    orElse: () => (periode).parties.first)
                .designation
            : '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Bascule numérique / analogique ──
        CarteCeleste(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enfant: Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.dialpad),
                      label: Text('Numérique'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.watch),
                      label: Text('Analogique'),
                    ),
                  ],
                  selected: {settings.horlogeAnalogique},
                  onSelectionChanged: (s) => ref
                      .read(settingsProvider.notifier)
                      .basculerHorlogeAnalogique(s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.bleuCiel,
                    selectedForegroundColor: AppColors.blanc,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Horloge ──
        CarteCeleste(
          padding: const EdgeInsets.all(22),
          enfant: settings.horlogeAnalogique
              ? Column(
                  children: [
                    Center(
                      child: HorlogeAnalogique(
                        maintenant: etat.maintenant,
                        labelPeriode: labelPeriode,
                        sousLabelPeriode: sousLabel,
                        nuit: enNuit,
                        dernierCoucher: dernierCoucher,
                        prochainCoucher: etat.prochainCoucher,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ligneInfos(etat, enNuit),
                  ],
                )
              : Column(
                  children: [
                    // Heure civile géante — l'heure civile reste visible (§6.1).
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppColors.bleuCiel,
                          enNuit
                              ? AppColors.orSolaire
                              : AppColors.bleuCielFonce,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        heureSecondeFormat(etat.maintenant),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: AppColors.blanc,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // DATE BIBLIQUE — bascule au COUCHER DU SOLEIL RÉEL,
                    // jamais à minuit (§7) : à 18 h 00 le jour affiché
                    // devient déjà le jour suivant.
                    Text(
                      etat.jourBiblique != null
                          ? 'Date biblique — '
                              '${etat.jourBiblique!.jourDuMois} ${etat.jourBiblique!.nomMois} '
                              '(${etat.jourBiblique!.nomJourSemaine}) '
                              '— change au coucher du soleil'
                          : dateLongueFrancais(etat.maintenant),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            enNuit ? AppColors.ardoise : AppColors.bleuCielNuit,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.orSolaire.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            enNuit
                                ? '${_numeroVeille((periode as NuitEnCours).veille.indice)} VEILLE'
                                : periode is JourEnCours
                                    ? 'HEURE SAISONNIÈRE ${(periode).heure.numero}'
                                    : '—',
                            style: const TextStyle(
                              color: AppColors.orVif,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            enNuit
                                ? (periode as NuitEnCours).veille.sousTitre
                                : periode is JourEnCours
                                    ? '${sousLabel} · ${(periode).heure.repereScripturaire ?? ''}'
                                    : '—',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: (enNuit
                                      ? AppColors.orVif
                                      : AppColors.bleuCiel)
                                  .withValues(alpha: 0.8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ligneInfos(etat, enNuit),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // ── Date biblique ──
        CarteCeleste(
          enfant: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orSolaire.withValues(alpha: 0.12),
                  border: Border.all(
                      color: AppColors.orSolaire.withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    color: AppColors.orSolaire, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      etat.jourBiblique != null
                          ? '${etat.jourBiblique!.jourDuMois} ${etat.jourBiblique!.nomMois}'
                          : '—',
                      style: const TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      etat.jourBiblique != null
                          ? '${etat.jourBiblique!.nomJourSemaine} · Jour ${etat.jourBiblique!.jourDeAnnee}/364 · '
                              'Année ${etat.anneeBiblique?.libelle ?? ''}'
                          : '—',
                      style: const TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 12,
                      ),
                    ),
                    if (etat.jourBiblique?.estShabbat ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orSolaire.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.orSolaire
                                    .withValues(alpha: 0.45)),
                          ),
                          child: const Text(
                            'Shabbat — du coucher au coucher',
                            style: TextStyle(
                              color: AppColors.orFonce,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Compte à rebours ──
        if (!etat.calculSolaireIndisponible)
          CarteCeleste(
            bordure: AppColors.orSolaire.withValues(alpha: 0.45),
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hourglass_bottom,
                        size: 17, color: AppColors.orSolaire),
                    SizedBox(width: 8),
                    Text(
                      'Compte à rebours du nouveau jour',
                      style: TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Prochain coucher du soleil : ${etat.prochainCoucher != null ? heureCivilFormat(etat.prochainCoucher!) : '—'}',
                  style: const TextStyle(
                    color: AppColors.grisSecondaire,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 12),
                BoitesCompteARebours(
                  duree: etat.compteAReboursCoucher,
                  accent: AppColors.orSolaire,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _ligneInfos(HorlogeState etat, bool enNuit) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _info('Heure civile', heureCivilFormat(etat.maintenant)),
          _info(
            enNuit ? 'Prochain lever' : 'Prochain coucher',
            enNuit
                ? (etat.solarJour?.calculable ?? false
                    ? heureCivilFormat(etat.solarJour!.lever!)
                    : '—')
                : (etat.prochainCoucher != null
                    ? heureCivilFormat(etat.prochainCoucher!)
                    : '—'),
          ),
          _info(
            'Position',
            etat.position.libelle.length > 18
                ? '${etat.position.libelle.substring(0, 18)}…'
                : etat.position.libelle,
          ),
        ],
      );

  Widget _info(String label, String valeur) => Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.grisSecondaire, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            valeur,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      );
}

String _numeroVeille(IndiceVeille indice) =>
    const ['Première', 'Deuxième', 'Troisième'][indice.index];
