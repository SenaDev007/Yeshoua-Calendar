/// ⭐ WIDGETS PARTAGÉS — cartes, en-têtes de section, compte à rebours.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';

export '../../data/models/formatters.dart'
    show heureCivilFormat, dureeLisible, dureeFormat, heureSecondeFormat;

/// Titre de section (petites capitales or/ardoise).
class TitreSection extends StatelessWidget {
  const TitreSection(this.texte, {super.key, this.icone, this.couleur});

  final String texte;
  final IconData? icone;
  final Color? couleur;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Row(
          children: [
            if (icone != null) ...[
              Icon(icone, size: 15, color: couleur ?? AppColors.bleuCiel),
              const SizedBox(width: 6),
            ],
            Text(
              texte.toUpperCase(),
              style: TextStyle(
                color: couleur ?? AppColors.grisSecondaire,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      );
}

/// Carte blanche standard.
class CarteCeleste extends StatelessWidget {
  const CarteCeleste({super.key, required this.enfant, this.padding, this.bordure});

  final Widget enfant;
  final EdgeInsetsGeometry? padding;
  final Color? bordure;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blanc,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: bordure ?? AppColors.ardoisePastel.withValues(alpha: 0.6)),
        ),
        child: enfant,
      );
}

/// Grande carte héro de la période en cours (veille ou heure saisonnière).
class CartePeriodeActive extends StatelessWidget {
  const CartePeriodeActive({
    super.key,
    required this.nuit,
    required this.nom,
    required this.sousTitre,
    required this.horodatageCourant,
    required this.progression,
    required this.complement,
  });

  final bool nuit;
  final String nom;
  final String sousTitre;
  final DateTime horodatageCourant;
  final double progression;
  final String complement;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.periodeActive(nuit);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: nuit
              ? [AppColors.ardoise, AppColors.ardoiseClair]
              : [AppColors.bleuCiel, AppColors.bleuCielFonce],
        ),
        border: Border.all(color: AppColors.orSolaire.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                nuit ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                size: 16,
                color: AppColors.orSolaire,
              ),
              const SizedBox(width: 7),
              Text(
                nuit ? 'NUIT — VEILLE EN COURS' : 'JOUR — HEURE SAISONNIÈRE',
                style: const TextStyle(
                  color: AppColors.orVif,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nom,
            style: const TextStyle(
              color: AppColors.blanc,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sousTitre,
            style: TextStyle(
              color: AppColors.blanc.withValues(alpha: 0.78),
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progression,
              minHeight: 7,
              backgroundColor: AppColors.blanc.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.orSolaire),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                complement,
                style: TextStyle(
                  color: AppColors.blanc.withValues(alpha: 0.85),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progression * 100).round()} %',
                style: const TextStyle(
                  color: AppColors.orVif,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Boîte de compte à rebours (heures / minutes / secondes).
class BoitesCompteARebours extends StatelessWidget {
  const BoitesCompteARebours({
    super.key,
    required this.duree,
    this.accent = AppColors.bleuCiel,
  });

  final Duration duree;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    String deux(int n) => n.toString().padLeft(2, '0');
    return Row(
      children: [
        _boite(deux(duree.inHours), 'heures'),
        const SizedBox(width: 8),
        _boite(deux(duree.inMinutes % 60), 'min'),
        const SizedBox(width: 8),
        _boite(deux(duree.inSeconds % 60), 'sec'),
      ],
    );
  }

  Widget _boite(String valeur, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bleuCielNuit,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Column(
            children: [
              Text(
                valeur,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.grisSecondaire,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Carte horaires solaires (lever / coucher / durées, §11).
class CarteSoleil extends StatelessWidget {
  const CarteSoleil({
    super.key,
    required this.lever,
    required this.coucher,
    required this.dureeJour,
    required this.dureeNuit,
    this.disponible = true,
  });

  final DateTime? lever;
  final DateTime? coucher;
  final String dureeJour;
  final String dureeNuit;
  final bool disponible;

  @override
  Widget build(BuildContext context) => CarteCeleste(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_twilight_outlined,
                    size: 17, color: AppColors.orSolaire),
                const SizedBox(width: 8),
                const Text(
                  'Soleil',
                  style: TextStyle(
                    color: AppColors.ardoise,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'le jour biblique commence au coucher',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.9),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            disponible
                ? Row(
                    children: [
                      Expanded(
                        child: _ligne(Icons.wb_sunny_outlined, 'Lever',
                            heureCivilFormat(lever!)),
                      ),
                      Container(width: 1, height: 34, color: AppColors.ardoisePastel),
                      Expanded(
                        child: _ligne(Icons.nightlight_outlined, 'Coucher',
                            heureCivilFormat(coucher!)),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Calcul solaire impossible à cette latitude (région polaire) '
                      '— configurez manuellement vos horaires dans les paramètres.',
                      style: TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _pastille('Durée du jour', dureeJour, AppColors.bleuCiel),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _pastille('Durée de la nuit', dureeNuit, AppColors.orSolaire),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _ligne(IconData icone, String label, String valeur) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 15, color: AppColors.grisSecondaire),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.grisSecondaire, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            valeur,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ],
      );

  Widget _pastille(String label, String valeur, Color accent) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.grisSecondaire, fontSize: 11)),
            const SizedBox(width: 6),
            Text(valeur,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5)),
          ],
        ),
      );
}
