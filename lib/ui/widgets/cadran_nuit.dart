/// ⭐ CADRAN DE LA NUIT (§3.5) — représentation circulaire des trois
/// veilles. Chaque arc = une veille (tiers réel de la nuit) ; la veille
/// en cours est mise en évidence, avec progression.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';

class CadranNuit extends StatelessWidget {
  const CadranNuit({
    super.key,
    required this.veilles,
    required this.taille,
  });

  final List<VeilleModel> veilles;
  final double taille;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(taille),
        painter: _PeintureCadranNuit(veilles: veilles),
      );
}

class _PeintureCadranNuit extends CustomPainter {
  _PeintureCadranNuit({required this.veilles});

  final List<VeilleModel> veilles;

  static const _couleursVeille = [
    Color(0xFF7C5CBF), // première veille — violet doux
    Color(0xFF3B82F6), // deuxième veille — bleu céleste
    Color(0xFFCFA63A), // troisième veille — or de l'aube
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final rayon = size.width / 2 - 6;

    // Disque de fond (ardoise clair → nuit).
    canvas.drawCircle(
        centre, rayon, Paint()..color = AppColors.ardoisePastel);

    // Trois arcs — départ : coucher du soleil (en haut du cercle, à 18 h
    // symbolique ? Non : chaque veille occupe un TIERS réel).
    for (var i = 0; i < veilles.length && i < 3; i++) {
      final v = veilles[i];
      final enCours = v.statut == StatutPeriode.enCours;
      final terminee = v.statut == StatutPeriode.terminee;
      final debut = (i / 3.0) * 2 * math.pi - math.pi / 2;
      final sweep = (1 / 3.0) * 2 * math.pi;

      final pinceau = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = enCours ? rayon * 0.30 : rayon * 0.24
        ..strokeCap = StrokeCap.butt
        ..color = _couleursVeille[i].withValues(
            alpha: terminee ? 0.35 : (enCours ? 1.0 : 0.65));

      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: rayon * 0.82),
        debut + 0.015,
        sweep - 0.03,
        false,
        pinceau,
      );

      // Progression de la veille en cours : sur-arc doré.
      if (enCours && v.progression > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: rayon * 0.82),
          debut + 0.015,
          sweep * v.progression - 0.03,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = rayon * 0.30
            ..color = AppColors.orVif.withValues(alpha: 0.9),
        );
      }
    }

    // Moyeu central : lune ou étoiles.
    canvas.drawCircle(
        centre, rayon * 0.34, Paint()..color = AppColors.ardoise);
    canvas.drawCircle(
      centre,
      rayon * 0.34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.orSolaire.withValues(alpha: 0.8),
    );

    final veilleEnCours = veilles
        .where((v) => v.statut == StatutPeriode.enCours)
        .toList();
    final tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);
    tp.text = TextSpan(
      text: veilleEnCours.isEmpty
          ? 'Nuit\nterminée'
          : '${_numero(veilleEnCours.first.indice)} veille\n',
      style: TextStyle(
        color: AppColors.blanc,
        fontSize: rayon * 0.14,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
      children: [
        TextSpan(
          text: veilleEnCours.isEmpty
              ? '—'
              : '${(veilleEnCours.first.progression * 100).round()} %',
          style: TextStyle(
            color: AppColors.orVif,
            fontSize: rayon * 0.16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    tp.layout(maxWidth: rayon * 0.6);
    tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
  }

  String _numero(IndiceVeille i) =>
      const ['1ʳᵉ', '2ᵉ', '3ᵉ'][i.index];

  @override
  bool shouldRepaint(_PeintureCadranNuit ancien) =>
      ancien.veilles != veilles;
}
