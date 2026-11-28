/// ⭐ HORLOGE ANALOGIQUE BIBLIQUE 24 h (§6.2 — version biblique) — CustomPainter.
///
/// PRINCIPE (demande expresse de l'utilisateur) :
///   • cadran de 24 HEURES BIBLIQUES (1 à 24) — jamais une horloge civile 12 h ;
///   • ORIGINE DU CYCLE : le COUCHER DU SOLEIL RÉEL (heure biblique 01:00,
///     positionnée À GAUCHE du cadran) ;
///   • DURÉE DU CYCLE : 24 h — 15° par heure biblique ;
///   • position des aiguilles calculée à partir du TEMPS ÉCOULÉ depuis le
///     dernier coucher du soleil (algorithmes astronomiques de position) ;
///   • fin du cycle au coucher du soleil suivant : le compteur revient à 01:00 ;
///   • MOITIÉ HAUTE (18 h → 6 h civils = heures 1→12) : image de nuit ;
///     MOITIÉ BASSE (6 h → 18 h civils = heures 13→24) : image de jour —
///     les deux moitiés forment un cercle parfait, aiguilles bien visibles.
///
/// Correspondances (coucher réel à 18 h 00 par exemple) :
///   18 h civils = 01:00 biblique (à gauche) · minuit = 07:00 ·
///   lever du soleil = 13:00 (à droite) · midi = 19:00 (en bas).
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class HorlogeAnalogique extends StatefulWidget {
  const HorlogeAnalogique({
    super.key,
    required this.maintenant,
    required this.labelPeriode,
    required this.sousLabelPeriode,
    required this.nuit,
    required this.dernierCoucher,
    required this.prochainCoucher,
  });

  final DateTime maintenant;
  final String labelPeriode;
  final String sousLabelPeriode;
  final bool nuit;

  /// Coucher du soleil RÉEL déclenchant le cycle biblique en cours
  /// (origine des heures — heure biblique 01:00). Null : repli sur 18 h.
  final DateTime? dernierCoucher;

  /// Prochain coucher du soleil RÉEL (fin du cycle — retour à 01:00).
  final DateTime? prochainCoucher;

  @override
  State<HorlogeAnalogique> createState() => _HorlogeAnalogiqueState();
}

class _HorlogeAnalogiqueState extends State<HorlogeAnalogique>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur;
  ui.Image? _fondCadran;

  @override
  void initState() {
    super.initState();
    // Balayage fluide de la trotteuse (§6.2) : un tour de fraction par seconde.
    _controleur = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _chargerFond();
  }

  /// Charge l'image de fond du cadran (moitié nuit / moitié jour formant
  /// un cercle parfait) — conçue professionnellement, sans texte.
  Future<void> _chargerFond() async {
    try {
      final data =
          await rootBundle.load('assets/images/cadran-biblique-fond.png');
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 1000,
      );
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _fondCadran = frame.image);
    } catch (_) {
      // Fond indisponible : dégradés peints en repli (voir _PeintureCadran).
    }
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
          fractionSeconde: _controleur.value,
          labelPeriode: widget.labelPeriode,
          sousLabelPeriode: widget.sousLabelPeriode,
          nuit: widget.nuit,
          dernierCoucher: widget.dernierCoucher,
          prochainCoucher: widget.prochainCoucher,
          fondCadran: _fondCadran,
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
    required this.dernierCoucher,
    required this.prochainCoucher,
    required this.fondCadran,
  });

  final DateTime maintenant;
  final double fractionSeconde;
  final String labelPeriode;
  final String sousLabelPeriode;
  final bool nuit;
  final DateTime? dernierCoucher;
  final DateTime? prochainCoucher;
  final ui.Image? fondCadran;

  // ── Géométrie du cadran biblique ──────────────────────────────────────
  // Les angles sont mesurés en DEGRÉS depuis le HAUT, sens horaire.
  // Heure biblique 1 (coucher du soleil) = 270° = GAUCHE du cadran.
  static const double _angleOrigine = 270.0;
  static const double _degresParHeure = 15.0;

  /// Position d'un point du cadran pour un angle (° depuis le haut, horaire).
  Offset _pos(Offset centre, double degres, double rayon) {
    final a = degres * math.pi / 180.0;
    return centre + Offset(math.sin(a) * rayon, -math.cos(a) * rayon);
  }

  /// Angle (°) du CHIFFRE de l'heure biblique [h] (1..24).
  double _angleChiffre(int h) =>
      (_angleOrigine + (h - 1) * _degresParHeure) % 360.0;

  /// Minutes écoulées DEPUIS LE DERNIER COUCHER DU SOLEIL RÉEL (0→1440).
  /// Origine du cycle = coucher du soleil (§6.2 biblique) ; repli sur
  /// 18 h 00 si le calcul solaire est indisponible (région polaire).
  double _minutesDepuisCoucher() {
    if (dernierCoucher != null) {
      final e = maintenant.difference(dernierCoucher!).inSeconds / 60.0;
      if (e >= 0) return e % 1440.0;
      // Coucher légèrement dans le futur (horloge système) : cycle à zéro.
      return 0.0;
    }
    final h = (maintenant.hour - 18) % 24;
    return h * 60.0 + maintenant.minute + maintenant.second / 60.0;
  }

  /// Heure biblique affichée (1..24) + minutes, pour le médaillon.
  String _heureBibliqueTexte(double minutes) {
    final n = (minutes.floor() ~/ 60) % 24; // 0 → heure 1, 23 → heure 24
    final h = n + 1;
    final m = minutes.floor() % 60;
    return '${h.toString().padLeft(2, '0')} h ${m.toString().padLeft(2, '0')}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final rayon = size.width / 2;
    final rect = Rect.fromCircle(center: centre, radius: rayon);

    // ── Fond du cadran : image nuit/jour (cercle parfait) ou dégradés ──
    if (fondCadran != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      canvas.drawImageRect(
        fondCadran!,
        Rect.fromLTWH(
            0, 0, fondCadran!.width.toDouble(), fondCadran!.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
    } else {
      // Repli : moitié nuit (haut) / moitié jour (bas).
      final pinceauNuit = Paint()
        ..shader = ui.Gradient.radial(
          Offset(centre.dx - rayon * 0.9, centre.dy),
          rayon * 1.6,
          [const Color(0xFF31407E), const Color(0xFF10163A)],
        );
      final pinceauJour = Paint()
        ..shader = ui.Gradient.radial(
          Offset(centre.dx + rayon * 0.9, centre.dy),
          rayon * 1.6,
          [const Color(0xFF96C7F0), const Color(0xFF78B4E2)],
        );
      canvas.drawArc(rect, math.pi, math.pi, true, pinceauNuit);
      canvas.drawArc(rect, 0, math.pi, true, pinceauJour);
    }

    // ── Liseré extérieur or (signature) + anneau fin ──
    canvas.drawCircle(
      centre,
      rayon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.orSolaire,
    );
    canvas.drawCircle(
      centre,
      rayon - 9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.orSolaire.withValues(alpha: 0.55),
    );

    // ── Graduations : 24 heures majeures + quart d'heure mineures ──
    final pinceauGrad = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 96; i++) {
      final angle = i * 3.75; // 96 quarts × 3,75° = 360°
      final majeure = i % 4 == 0;
      final r1 = rayon - (majeure ? 24 : 15);
      final r2 = rayon - 13;
      pinceauGrad.strokeWidth = majeure ? 2.6 : 1.1;
      pinceauGrad.color = majeure
          ? AppColors.orVif.withValues(alpha: 0.85)
          : AppColors.blanc.withValues(alpha: 0.35);
      canvas.drawLine(
          _pos(centre, angle, r1), _pos(centre, angle, r2), pinceauGrad);
    }

    // ── Chiffres des 24 heures bibliques ──
    final tpChiffre = TextPainter(textDirection: TextDirection.ltr);
    for (var h = 1; h <= 24; h++) {
      final angle = _angleChiffre(h);
      final demiNuit = angle >= 262.5 || angle < 97.5; // moitié haute = nuit
      tpChiffre.text = TextSpan(
        text: '$h',
        style: TextStyle(
          color: demiNuit
              ? AppColors.orPastel.withValues(alpha: 0.95)
              : AppColors.ardoise.withValues(alpha: 0.9),
          fontSize: rayon * 0.093,
          fontWeight: FontWeight.w800,
        ),
      );
      tpChiffre.layout();
      final r = rayon - 40;
      tpChiffre.paint(
        canvas,
        _pos(centre, angle, r) -
            Offset(tpChiffre.width / 2, tpChiffre.height / 2),
      );
    }

    // ── Marqueurs solaires : coucher (heure 1, gauche) et lever (heure 13,
    //    droite) — petits soleils dorés sur le pourtour ──
    for (final a in [_angleChiffre(1), _angleChiffre(13)]) {
      final p = _pos(centre, a, rayon - 5.5);
      canvas.drawCircle(p, 5, Paint()..color = AppColors.orSolaire);
      canvas.drawCircle(
          p, 2.2, Paint()..color = AppColors.blanc.withValues(alpha: 0.9));
    }

    // ── Arc du cycle écoulé : du coucher (270°) à l'heure courante ──
    final minutes = _minutesDepuisCoucher();
    final angleCourant = _angleOrigine + minutes / 1440.0 * 360.0;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon - 5),
      (_angleOrigine - 90) * math.pi / 180.0,
      (minutes / 1440.0) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.orSolaire.withValues(alpha: 0.75),
    );

    // ── Médaillon central : heure biblique + période en cours ──
    final rayonMedaillon = rayon * 0.34;
    canvas.drawCircle(centre, rayonMedaillon,
        Paint()..color = nuit ? AppColors.ardoise : AppColors.bleuCielNuit);
    canvas.drawCircle(
      centre,
      rayonMedaillon,
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
      text: 'HEURE BIBLIQUE\n',
      style: TextStyle(
        color: (nuit ? AppColors.orVif : AppColors.bleuCiel)
            .withValues(alpha: 0.85),
        fontSize: rayon * 0.052,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        height: 1.25,
      ),
      children: [
        TextSpan(
          text: _heureBibliqueTexte(minutes),
          style: TextStyle(
            color: AppColors.orVif,
            fontSize: rayon * 0.105,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        TextSpan(
          text: '\n$labelPeriode',
          style: TextStyle(
            color: (nuit ? AppColors.orPastel : AppColors.blanc)
                .withValues(alpha: 0.9),
            fontSize: rayon * 0.058,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        TextSpan(
          text: '\n${sousLabelPeriode}',
          style: TextStyle(
            color: (nuit ? AppColors.orPastel : AppColors.blanc)
                .withValues(alpha: 0.7),
            fontSize: rayon * 0.045,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
      ],
    );
    tpPeriode.layout(maxWidth: rayonMedaillon * 1.7);
    tpPeriode.paint(
      canvas,
      centre - Offset(tpPeriode.width / 2, tpPeriode.height / 2),
    );

    // ── Aiguilles — angles calculés depuis le DERNIER COUCHER RÉEL ──
    final indiceHeure = (minutes.floor() ~/ 60) % 24; // 0 → heure 1
    final angleBaseHeure = _angleOrigine + indiceHeure * _degresParHeure;
    final fractionHeure = (minutes % 60.0) / 60.0;

    // Aiguille des heures : un tour complet = 24 h (1440 min).
    final angleHeures = _angleOrigine + (minutes / 1440.0) * 360.0;
    // Aiguille des minutes : ancrée au chiffre de l'heure en cours.
    final angleMinutes = angleBaseHeure + fractionHeure * 360.0;
    // Trotteuse : balayage fluide (fraction de seconde du contrôleur).
    final angleSecondes = angleBaseHeure +
        (((minutes.floor() % 60) + fractionSeconde) / 60.0) * 360.0;

    _aiguille(canvas, centre, angleHeures, rayon * 0.46, 7.0,
        nuit ? AppColors.orPastel : AppColors.ardoise);
    _aiguille(canvas, centre, angleMinutes, rayon * 0.64, 4.5,
        nuit ? AppColors.orPastel : AppColors.ardoise);
    _aiguille(
        canvas, centre, angleSecondes, rayon * 0.74, 2.0, AppColors.orSolaire);
    _contrepoids(canvas, centre, angleSecondes, 18, 2.0, AppColors.orSolaire);

    // Moyeu central doré.
    canvas.drawCircle(centre, 6.5, Paint()..color = AppColors.orSolaire);
    canvas.drawCircle(
      centre,
      2.6,
      Paint()..color = AppColors.blanc,
    );
  }

  /// Trace une aiguille (triangle effilé) depuis le centre à [angleDegres]
  /// (° depuis le haut, sens horaire).
  void _aiguille(Canvas canvas, Offset centre, double angleDegres,
      double longueur, double largeur, Color couleur) {
    final a = angleDegres * math.pi / 180.0;
    final dir = Offset(math.sin(a), -math.cos(a));
    final bout = centre + dir * longueur;
    final perp = Offset(-dir.dy, dir.dx);
    final demi = largeur / 2;
    final chemin = Path()
      ..moveTo(centre.dx + perp.dx * demi, centre.dy + perp.dy * demi)
      ..lineTo(bout.dx, bout.dy)
      ..lineTo(centre.dx - perp.dx * demi, centre.dy - perp.dy * demi)
      ..close();
    canvas.drawPath(chemin, Paint()..color = couleur);
  }

  void _contrepoids(Canvas canvas, Offset centre, double angleDegres,
      double longueur, double largeur, Color couleur) {
    final a = angleDegres * math.pi / 180.0;
    final dir = Offset(math.sin(a), -math.cos(a));
    final bout = centre - dir * longueur;
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
      ancien.dernierCoucher != dernierCoucher ||
      ancien.prochainCoucher != prochainCoucher ||
      ancien.fondCadran != fondCadran;
}
