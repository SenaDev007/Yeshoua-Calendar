/// ⭐ CADRAN SOLAIRE (§4.4) — vue circulaire des douze heures
/// saisonnières regroupées en quatre parties du jour, avec le soleil
/// qui traverse le ciel ; l'heure en cours est mise en évidence.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:zman_engine/zman_engine.dart';

import '../../core/theme/app_colors.dart';

class CadranSolaire extends StatelessWidget {
  const CadranSolaire({
    super.key,
    required this.heures,
    required this.parties,
    required this.taille,
  });

  final List<HeureSaisonniereModel> heures;
  final List<PartieJourModel> parties;
  final double taille;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(taille),
        painter: _PeintureCadranSolaire(heures: heures, parties: parties),
      );
}

class _PeintureCadranSolaire extends CustomPainter {
  _PeintureCadranSolaire({required this.heures, required this.parties});

  final List<HeureSaisonniereModel> heures;
  final List<PartieJourModel> parties;

  static const _couleursParties = [
    Color(0xFFF6C453), // matin — or clair du matin
    Color(0xFF3B82F6), // approche du midi — bleu céleste
    Color(0xFF2563EB), // après-midi — bleu profond
    Color(0xFFCFA63A), // fin du jour — or solaire du couchant
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final rayon = size.width / 2 - 6;

    canvas.drawCircle(
        centre, rayon, Paint()..color = AppColors.bleuCielNuit);
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = AppColors.bleuCiel.withValues(alpha: 0.5),
    );

    // 4 secteurs de parties (chaque partie = un quadrant = 3 heures).
    for (var i = 0; i < parties.length && i < 4; i++) {
      final p = parties[i];
      final enCours = p.statut == StatutPeriode.enCours;
      final terminee = p.statut == StatutPeriode.terminee;
      final debut = (i / 4.0) * 2 * math.pi - math.pi / 2;
      final sweep = (1 / 4.0) * 2 * math.pi;

      final pinceau = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = enCours ? rayon * 0.26 : rayon * 0.20
        ..color = _couleursParties[i]
            .withValues(alpha: terminee ? 0.32 : (enCours ? 1.0 : 0.6));
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: rayon * 0.80),
        debut + 0.012,
        sweep - 0.024,
        false,
        pinceau,
      );
    }

    // 12 subdivisions (graduations internes).
    final tpNumero = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < 12 && i < heures.length; i++) {
      final h = heures[i];
      final angle = (i / 12.0) * 2 * math.pi - math.pi / 2;
      final enCours = h.statut == StatutPeriode.enCours;

      final p1 = centre +
          Offset(math.cos(angle) * rayon * 0.66, math.sin(angle) * rayon * 0.66);
      final p2 = centre +
          Offset(math.cos(angle) * rayon * 0.72, math.sin(angle) * rayon * 0.72);
      canvas.drawLine(
          p1, p2,
          Paint()
            ..strokeWidth = enCours ? 3.0 : 1.3
            ..color = enCours
                ? AppColors.ardoise
                : AppColors.grisSecondaire.withValues(alpha: 0.65));

      // Numéro de l'heure saisonnière.
      tpNumero.text = TextSpan(
        text: '${h.numero}',
        style: TextStyle(
          color: enCours ? AppColors.bleuCielFonce : AppColors.ardoise.withValues(alpha: 0.75),
          fontSize: rayon * 0.105,
          fontWeight: enCours ? FontWeight.w800 : FontWeight.w600,
        ),
      );
      tpNumero.layout();
      final r = rayon * 0.585;
      tpNumero.paint(
        canvas,
        centre +
            Offset(math.cos(angle) * r, math.sin(angle) * r) -
            Offset(tpNumero.width / 2, tpNumero.height / 2),
      );
    }

    // Soleil : position sur le cadran selon la progression du jour.
    final enCours =
        heures.where((h) => h.statut == StatutPeriode.enCours).toList();
    double progressionJour = 0;
    if (enCours.isNotEmpty) {
      final h = enCours.first;
      progressionJour = (h.numero - 1 + h.progression) / 12.0;
    } else if (heures.isNotEmpty) {
      if (heures.first.statut == StatutPeriode.aVenir) {
        progressionJour = 0;
      } else {
        progressionJour = 1;
      }
    }
    final angleSoleil = progressionJour * 2 * math.pi - math.pi / 2;
    final positionSoleil = centre +
        Offset(math.cos(angleSoleil) * rayon * 0.80,
            math.sin(angleSoleil) * rayon * 0.80);

    // Halo puis disque doré.
    canvas.drawCircle(positionSoleil, rayon * 0.115,
        Paint()..color = AppColors.orSolaire.withValues(alpha: 0.30));
    canvas.drawCircle(
        positionSoleil, rayon * 0.075, Paint()..color = AppColors.orSolaire);
    canvas.drawCircle(positionSoleil, rayon * 0.032,
        Paint()..color = AppColors.orVif);

    // Moyeu : heure en cours.
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    tp.text = TextSpan(
      text: enCours.isEmpty
          ? 'Nuit'
          : 'Heure\n${enCours.first.numero}',
      style: TextStyle(
        color: AppColors.ardoise,
        fontSize: rayon * 0.115,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
      children: enCours.isEmpty
          ? []
          : [
              TextSpan(
                text: '  (${(enCours.first.progression * 100).round()} %)',
                style: TextStyle(
                  color: AppColors.bleuCiel,
                  fontSize: rayon * 0.085,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
    );
    tp.layout(maxWidth: rayon * 0.62);
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_PeintureCadranSolaire ancien) =>
      ancien.heures != heures || ancien.parties != parties;
}
