/// ⭐ HORLOGE ANALOGIQUE DIVINE (§6.2) — CustomPainter.
///
/// Cadran circulaire élégant : graduations, aiguilles heures/minutes/
/// secondes en OR SOLAIRE (signature Horloge Céleste), indication de la veille ou
/// de la partie du jour en cours, date biblique en médaillon central.
/// Animation fluide : la trotteuse balaie en continu.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HorlogeAnalogique extends StatefulWidget {
  const HorlogeAnalogique({
    super.key,
    required this.maintenant,
    required this.labelPeriode,
    required this.sousLabelPeriode,
    required this.nuit,
    this.coucherArc,
    this.leverArc,
  });

  final DateTime maintenant;
  final String labelPeriode;
  final String sousLabelPeriode;
  final bool nuit;

  /// Coucher / lever du soleil RÉELS bornant la période en cours (§6.2) :
  /// l'arc extérieur du cadran commence au coucher réel et s'achève au
  /// lever réel (norme biblique — jamais 18 h / 6 h fixes). Si null
  /// (calcul impossible), repli sur 18 h / 6 h.
  final DateTime? coucherArc;
  final DateTime? leverArc;

  @override
  State<HorlogeAnalogique> createState() => _HorlogeAnalogiqueState();
}

class _HorlogeAnalogiqueState extends State<HorlogeAnalogique>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;

  @override
  void initState() {
    super.initState();
    // 60 images/s → trotteuse parfaitement fluide (§6.2).
    _controleur = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controleur,
      builder: (context, _) => CustomPaint(
        size: const Size.square(300),
        painter: _PeintureCadran(
          maintenant: widget.maintenant,
          fractionSeconde:
              widget.maintenant.second / 60.0 + _controleur.value / 60.0,
          labelPeriode: widget.labelPeriode,
          sousLabelPeriode: widget.sousLabelPeriode,
          nuit: widget.nuit,
          coucherArc: widget.coucherArc,
          leverArc: widget.leverArc,
        ),
      ),
    );
  }
}

class _PeintureCadran extends CustomPainter {
  _PeintureCadran({
    required this.maintenant,
    required this.fractionSeconde,
    required this.labelPeriode,
    required this.sousLabelPeriode,
    required this.nuit,
    this.coucherArc,
    this.leverArc,
  });

  final DateTime maintenant;
  final double fractionSeconde;
  final String labelPeriode;
  final String sousLabelPeriode;
  final bool nuit;
  final DateTime? coucherArc;
  final DateTime? leverArc;

  /// Angle du cadran 12 h pour un instant civil donné.
  double _anglePour(DateTime t) =>
      ((t.hour % 12) * 60 + t.minute + t.second / 60.0) /
          720.0 *
          2 *
          math.pi -
      math.pi / 2;

  /// Bornes de l'arc de la période en cours (§6.2 — coucher/lever réels).
  ({double debut, double fin}) _bornesArc() {
    if (coucherArc != null && leverArc != null) {
      final d = nuit ? _anglePour(coucherArc!) : _anglePour(leverArc!);
      final f = nuit ? _anglePour(leverArc!) : _anglePour(coucherArc!);
      // La nuit traverse minuit : si l'extrémité précède l'origine,
      // on repasse par le tour complet du cadran.
      return (debut: d, fin: f <= d ? f + 2 * math.pi : f);
    }
    // Repli si le calcul solaire est indisponible : 18 h → 6 h.
    const d = 18.0 / 24.0 * 2 * math.pi - math.pi / 2;
    return nuit
        ? (debut: d, fin: d + math.pi)
        : (debut: d - math.pi, fin: d);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final rayon = size.width / 2;

    // ── Fond du cadran ──
    canvas.drawCircle(
      centre,
      rayon,
      Paint()..color = AppColors.blanc,
    );
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = nuit ? AppColors.orSolaire : AppColors.bleuCiel,
    );
    // Anneau décoratif doré fin (signature).
    canvas.drawCircle(
      centre,
      rayon - 9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.orSolaire.withValues(alpha: 0.55),
    );

    // ── Graduations (60 min ; 12 heures marquées) ──
    final pinceauGrad = Paint()
      ..strokeCap = StrokeCap.round
      ..color = AppColors.ardoise.withValues(alpha: 0.55);
    for (var i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180 - math.pi / 2;
      final majeure = i % 5 == 0;
      final r1 = rayon - (majeure ? 26 : 16);
      final r2 = rayon - 14;
      pinceauGrad.strokeWidth = majeure ? 2.6 : 1.2;
      pinceauGrad.color = majeure
          ? (nuit ? AppColors.orSolaire : AppColors.bleuCiel)
          : AppColors.grisSecondaire.withValues(alpha: 0.6);
      canvas.drawLine(
        centre + Offset(math.cos(angle) * r1, math.sin(angle) * r1),
        centre + Offset(math.cos(angle) * r2, math.sin(angle) * r2),
        pinceauGrad,
      );
    }

    // ── Chiffres des heures ──
    final tpChiffre = TextPainter(
      textDirection: TextDirection.ltr,
    );
    for (var h = 1; h <= 12; h++) {
      final angle = (h * 30) * math.pi / 180 - math.pi / 2;
      tpChiffre.text = TextSpan(
        text: '$h',
        style: TextStyle(
          color: AppColors.ardoise.withValues(alpha: 0.85),
          fontSize: rayon * 0.105,
          fontWeight: FontWeight.w700,
        ),
      );
      tpChiffre.layout();
      final r = rayon - 44;
      tpChiffre.paint(
        canvas,
        centre +
            Offset(math.cos(angle) * r, math.sin(angle) * r) -
            Offset(tpChiffre.width / 2, tpChiffre.height / 2),
      );
    }

    // ── Arc de la période en cours (extérieur) ──
    // Nuit : du coucher RÉEL au lever RÉEL ; jour : du lever RÉEL au
    // coucher RÉEL (§6.2 — jamais de bornes civiles figées).
    final bornes = _bornesArc();
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon - 5),
      bornes.debut,
      bornes.fin - bornes.debut,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color =
            (nuit ? AppColors.orSolaire : AppColors.bleuCiel).withValues(alpha: 0.35),
    );

    // ── Médaillon central : période en cours ──
    canvas.drawCircle(
      centre,
      rayon * 0.30,
      Paint()..color =
          nuit ? AppColors.ardoise : AppColors.bleuCielNuit,
    );
    canvas.drawCircle(
      centre,
      rayon * 0.30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.orSolaire,
    );
    final tpPeriode = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tpPeriode.text = TextSpan(
      text: '${labelPeriode}\n',
      style: TextStyle(
        color: nuit ? AppColors.orVif : AppColors.bleuCiel,
        fontSize: rayon * 0.085,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      children: [
        TextSpan(
          text: sousLabelPeriode,
          style: TextStyle(
            color: (nuit ? AppColors.orVif : AppColors.bleuCiel)
                .withValues(alpha: 0.75),
            fontSize: rayon * 0.055,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    tpPeriode.layout(maxWidth: rayon * 0.52);
    tpPeriode.paint(
      canvas,
      centre - Offset(tpPeriode.width / 2, tpPeriode.height / 2),
    );

    // ── Aiguilles ──
    final h = maintenant.hour % 12;
    final m = maintenant.minute;
    final s = maintenant.second + (fractionSeconde % 1.0);

    final angleHeure = ((h + m / 60.0) * 30) * math.pi / 180 - math.pi / 2;
    final angleMinute = ((m + s / 60.0) * 6) * math.pi / 180 - math.pi / 2;
    final angleSeconde = ((s % 60) * 6) * math.pi / 180 - math.pi / 2;

    _aiguille(canvas, centre, angleHeure, rayon * 0.42, 6.5,
        nuit ? AppColors.orPastel : AppColors.ardoise);
    _aiguille(canvas, centre, angleMinute, rayon * 0.62, 4.5,
        nuit ? AppColors.orPastel : AppColors.ardoise);
    // Trotteuse : signature or solaire.
    _aiguille(canvas, centre, angleSeconde, rayon * 0.72, 2.0,
        AppColors.orSolaire);
    _contrepoids(canvas, centre, angleSeconde, 18, 2.0, AppColors.orSolaire);

    // Moyeu central doré.
    canvas.drawCircle(centre, 6.5, Paint()..color = AppColors.orSolaire);
    canvas.drawCircle(
      centre,
      2.6,
      Paint()..color = AppColors.blanc,
    );
  }

  void _aiguille(Canvas canvas, Offset centre, double angle, double longueur,
      double largeur, Color couleur) {
    final bout = centre + Offset(math.cos(angle) * longueur, math.sin(angle) * longueur);
    final perpendiculaire = angle + math.pi / 2;
    final demi = largeur / 2;
    final p1 = centre +
        Offset(math.cos(perpendiculaire) * demi, math.sin(perpendiculaire) * demi);
    final p2 = centre -
        Offset(math.cos(perpendiculaire) * demi, math.sin(perpendiculaire) * demi);
    final chemin = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(bout.dx, bout.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(
      chemin,
      Paint()..color = couleur,
    );
  }

  void _contrepoids(Canvas canvas, Offset centre, double angle, double longueur,
      double largeur, Color couleur) {
    final bout = centre - Offset(math.cos(angle) * longueur, math.sin(angle) * longueur);
    canvas.drawLine(
      centre,
      bout,
      Paint()
        ..strokeWidth = largeur
        ..color = couleur,
    );
    canvas.drawCircle(bout, 3.2, Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_PeintureCadran ancien) =>
      ancien.maintenant != maintenant ||
      ancien.fractionSeconde != fractionSeconde ||
      ancien.coucherArc != coucherArc ||
      ancien.leverArc != leverArc;
}
