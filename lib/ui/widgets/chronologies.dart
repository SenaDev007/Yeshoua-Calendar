/// ⭐ CHRONOLOGIES LINÉAIRES (§3.5, §4.4) — vue « chronologie » des veilles
/// et des heures saisonnières avec états visuels distincts :
/// terminée (atténuée), en cours (accent + progression), à venir (neutre).
library;

import 'package:flutter/material.dart';

import 'package:zman_engine/zman_engine.dart';

import '../../core/theme/app_colors.dart';
import 'cartes.dart';

/// Ligne de veille de la nuit (§3.5).
class LigneVeille extends StatelessWidget {
  const LigneVeille({super.key, required this.veille});

  final VeilleModel veille;

  static const _accents = [Color(0xFF7C5CBF), AppColors.bleuCiel, AppColors.orSolaire];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[veille.indice.index];
    final enCours = veille.statut == StatutPeriode.enCours;
    final terminee = veille.statut == StatutPeriode.terminee;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enCours ? accent.withValues(alpha: 0.08) : AppColors.blanc,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enCours ? accent.withValues(alpha: 0.55) : AppColors.ardoisePastel,
          width: enCours ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: enCours ? 1.0 : 0.12),
                ),
                child: Center(
                  child: Text(
                    '${veille.indice.index + 1}',
                    style: TextStyle(
                      color: enCours ? AppColors.blanc : accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      veille.nom,
                      style: TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      veille.sousTitre,
                      style: TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              _badgeStatut(veille.statut, accent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _horloge('Commencement', heureCivilFormat(veille.debut)),
              ),
              Container(width: 1, height: 26, color: AppColors.ardoisePastel),
              Expanded(
                child: _horloge('Fin', heureCivilFormat(veille.fin)),
              ),
              Container(width: 1, height: 26, color: AppColors.ardoisePastel),
              Expanded(
                child: _horloge('Durée', dureeLisible(veille.duree)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: veille.progression,
              minHeight: 5,
              backgroundColor: AppColors.ardoisePastel.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horloge(String label, String valeur) => Column(
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
              fontSize: 13,
            ),
          ),
        ],
      );

  Widget _badgeStatut(StatutPeriode statut, Color accent) {
    final (label, couleur) = switch (statut) {
      StatutPeriode.enCours => ('EN COURS', accent),
      StatutPeriode.terminee => ('TERMINÉE', AppColors.grisSecondaire),
      StatutPeriode.aVenir => ('À VENIR', AppColors.grisSecondaire),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: couleur,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Tuile d'une heure saisonnière (§4.2).
class TuileHeureSaisonniere extends StatelessWidget {
  const TuileHeureSaisonniere({super.key, required this.heure});

  final HeureSaisonniereModel heure;

  @override
  Widget build(BuildContext context) {
    final enCours = heure.statut == StatutPeriode.enCours;
    final terminee = heure.statut == StatutPeriode.terminee;
    final accent = enCours ? AppColors.bleuCiel : AppColors.grisSecondaire;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: enCours
            ? AppColors.bleuCiel.withValues(alpha: 0.07)
            : AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enCours ? AppColors.bleuCiel : AppColors.ardoisePastel,
          width: enCours ? 1.7 : 1,
        ),
      ),
      child: Row(
        children: [
          // Numéro avec progression circulaire.
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: heure.progression == 0 ? null : heure.progression,
                  strokeWidth: 3,
                  color: enCours ? AppColors.bleuCiel : AppColors.ardoisePastel,
                  backgroundColor: AppColors.ardoisePastel.withValues(alpha: 0.4),
                ),
                Center(
                  child: Text(
                    '${heure.numero}',
                    style: TextStyle(
                      color: enCours ? AppColors.bleuCielFonce : AppColors.ardoise,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_ordinal(heure.numero)} heure',
                      style: TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        decoration: terminee ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.grisSecondaire,
                      ),
                    ),
                    if (heure.repereScripturaire != null) ...[
                      const SizedBox(width: 7),
                      Icon(Icons.menu_book_outlined,
                          size: 13, color: AppColors.orSolaire),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          heure.repereScripturaire!.split(' — ').first,
                          style: const TextStyle(
                            color: AppColors.orFonce,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${heureCivilFormat(heure.debut)} → ${heureCivilFormat(heure.fin)} · '
                  '${dureeLisible(heure.duree)} · Partie ${heure.partie}',
                  style: const TextStyle(
                    color: AppColors.grisSecondaire,
                    fontSize: 11.5,
                  ),
                ),
                if (heure.repereScripturaire != null &&
                    heure.repereScripturaire!.contains(' — '))
                  Text(
                    heure.repereScripturaire!.split(' — ').last,
                    style: const TextStyle(
                      color: AppColors.orFonce.withValues(alpha: 0.8),
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (enCours)
            const Icon(Icons.play_arrow_rounded, color: AppColors.bleuCiel)
          else if (terminee)
            const Icon(Icons.check_rounded,
                color: AppColors.grisSecondaire, size: 19)
          else
            Icon(Icons.schedule, color: AppColors.grisSecondaire.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }

  String _ordinal(int n) =>
      const ['', 'Première', 'Deuxième', 'Troisième', 'Quatrième', 'Cinquième',
        'Sixième', 'Septième', 'Huitième', 'Neuvième', 'Dixième',
        'Onzième', 'Douzième'][n];
}

/// Ligne d'une partie du jour (§4.3).
class LignePartieJour extends StatelessWidget {
  const LignePartieJour({super.key, required this.partie});

  final PartieJourModel partie;

  static const _accents = [
    Color(0xFFF6C453),
    AppColors.bleuCiel,
    Color(0xFF2563EB),
    AppColors.orSolaire,
  ];
  static const _icones = [
    Icons.wb_sunny_outlined,
    Icons.light_mode_outlined,
    Icons.wb_cloudy_outlined,
    Icons.wb_twilight_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accents[partie.indice.index];
    final enCours = partie.statut == StatutPeriode.enCours;
    final terminee = partie.statut == StatutPeriode.terminee;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: enCours ? accent.withValues(alpha: 0.08) : AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enCours ? accent.withValues(alpha: 0.55) : AppColors.ardoisePastel,
          width: enCours ? 1.7 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_icones[partie.indice.index],
              size: 20, color: terminee ? accent.withValues(alpha: 0.45) : accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_nomPartie(partie.indice)} partie du jour',
                  style: TextStyle(
                    color: AppColors.ardoise,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    decoration: terminee ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.grisSecondaire,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${partie.designation} · heures ${partie.de} à ${partie.a}',
                  style: const TextStyle(
                    color: AppColors.grisSecondaire,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: partie.progression,
                    minHeight: 4,
                    backgroundColor: AppColors.ardoisePastel.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            switch (partie.statut) {
              StatutPeriode.enCours => '${(partie.progression * 100).round()} %',
              StatutPeriode.terminee => 'fait',
              StatutPeriode.aVenir => '—',
            },
            style: TextStyle(
              color: enCours ? accent : AppColors.grisSecondaire,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _nomPartie(IndicePartie i) =>
      const ['Première', 'Deuxième', 'Troisième', 'Quatrième'][i.index];
}
