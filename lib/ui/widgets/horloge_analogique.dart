/// ⭐ HORLOGE ANALOGIQUE 24 h — CONFORME À L'IMAGE DE RÉFÉRENCE
/// (capture fournie par l'utilisateur) sur le fond de design Horloge
/// Céleste (ciel de nuit étoilé + lune / ciel de jour nuageux + soleil).
///
/// PRINCIPES (demandes explicites de l'utilisateur, v1.0.7) :
///   • cadran CIVIL 24 h : 00 en HAUT, 06 à DROITE, 12 en BAS, 18 à
///     GAUCHE — exactement comme l'image de référence ;
///   • chiffres PAIRS en GRANDS caractères (00, 02 … 22), chiffres IMPAIRS
///     en petits caractères entre eux (01 … 23) ;
///   • MINUTEUR INTERNE : petits nombres 05, 10 … 55, 60 sur un anneau
///     intérieur (60 sous le 00) ;
///   • AIGUILLES À L'HEURE CIVILE RÉELLE : l'aiguille des heures fait UN
///     TOUR PAR 24 h — 13 h pointe entre les chiffres 13 et 14, l'heure
///     analogique est CONFORME à l'heure numérique (défaut corrigé :
///     l'ancien cadran « biblique » décalait les aiguilles) ;
///   • aiguille des SECONDES ROUGE avec contrepoids — deux modes au choix
///     dans les Paramètres : balayage FLUIDE (~60 img/s, synchronisé sur
///     les millisecondes RÉELLES) ou TIC-TAC par seconde (économie) ;
///     L'ANCIENNE VERSION désynchronisait un contrôleur d'animation 1 s
///     d'avec l'horloge système : l'aiguille oscillait avant/arrière —
///     corrigé ici (l'heure vient de DateTime.now(), jamais d'un cycles
///     d'animation indépendant) ;
///   • l'ARC du cycle biblique écoulé depuis le DERNIER COUCHER RÉEL reste
///     la signature Horloge Céleste ; le médaillon central affiche
///     l'heure CIVILE (conforme aux aiguilles et à l'horloge numérique —
///     l'ancien « heure biblique » continue se lisait comme une fausse
///     heure) puis la période biblique en cours (veille / heure
///     saisonnière) ;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Rouge de la trotteuse — même teinte que l'image de référence.
const Color _rougeTrotteuse = Color(0xFFE53935);

class HorlogeAnalogique extends StatefulWidget {
  const HorlogeAnalogique({
    super.key,
    required this.labelPeriode,
    required this.sousLabelPeriode,
    required this.nuit,
    required this.dernierCoucher,
    required this.trotteuseFluide,
  });

  final String labelPeriode;
  final String sousLabelPeriode;
  final bool nuit;

  /// Coucher du soleil RÉEL déclenchant le cycle biblique en cours
  /// (origine de l'arc écoulé et de l'heure biblique du médaillon).
  final DateTime? dernierCoucher;

  /// Trotteuse FLUIDE (balayage continu) sinon tic-tac par seconde —
  /// même réglage que l'écran de verrouillage (Paramètres §9.5).
  final bool trotteuseFluide;

  @override
  State<HorlogeAnalogique> createState() => _HorlogeAnalogiqueState();
}

class _HorlogeAnalogiqueState extends State<HorlogeAnalogique>
    with SingleTickerProviderStateMixin {
  /// Instant RÉEL affiché — mis à jour par le ticker (fluide) ou par un
  /// minutier aligné sur la seconde (tic-tac). JAMAIS depuis un contrôleur
  /// d'animation désynchronisé (cause de l'aiguille qui oscillait).
  final ValueNotifier<DateTime> _instant =
      ValueNotifier<DateTime>(DateTime.now());

  Ticker? _ticker;
  Timer? _minutier;
  ui.Image? _fondCadran;
  bool _fluide = true;

  @override
  void initState() {
    super.initState();
    _fluide = widget.trotteuseFluide;
    _demarrer();
    _chargerFond();
  }

  @override
  void didUpdateWidget(HorlogeAnalogique ancien) {
    super.didUpdateWidget(ancien);
    // Le réglage « Trotteuse fluide » a changé : bascule du mode sans
    // rouvrir l'application.
    if (ancien.trotteuseFluide != widget.trotteuseFluide) {
      _fluide = widget.trotteuseFluide;
      _demarrer();
    }
  }

  /// Démarre la source de temps adaptée au mode choisi.
  void _demarrer() {
    _stopper();
    if (_fluide) {
      // BALAYAGE FLUIDE : une image par rafraîchissement d'écran, l'heure
      // est lue à chaque image — la trotteuse avance avec les
      // millisecondes réelles, sans jamais reculer.
      _ticker = createTicker((_) {
        _instant.value = DateTime.now();
      })
        ..start();
    } else {
      // TIC-TAC : un repaint par seconde, ALIGNÉ sur le changement de
      // seconde (économie de batterie maximale).
      final delai = Duration(
          milliseconds: 1000 - DateTime.now().millisecond);
      Future.delayed(delai, () {
        // Garde : le mode a pu basculer (ou l'écran disparaître) pendant
        // l'attente — on ne crée le minutier que si le tic-tac est voulu.
        if (!mounted || !_fluide) return;
        _instant.value = DateTime.now();
        _minutier = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          _instant.value = DateTime.now();
        });
      });
    }
  }

  void _stopper() {
    _ticker?.dispose();
    _ticker = null;
    _minutier?.cancel();
    _minutier = null;
  }

  /// Charge l'image de fond du cadran (nuit étoilée + lune / jour + soleil)
  /// — conçue professionnellement, sans texte.
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
    _stopper();
    _instant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: _instant,
      builder: (context, instant, _) => CustomPaint(
        size: const Size.square(300),
        painter: _PeintureCadran(
          instant: instant,
          labelPeriode: widget.labelPeriode,
          sousLabelPeriode: widget.sousLabelPeriode,
          nuit: widget.nuit,
          dernierCoucher: widget.dernierCoucher,
          trotteuseFluide: _fluide,
          fondCadran: _fondCadran,
        ),
      ),
    );
  }
}

class _PeintureCadran extends CustomPainter {
  _PeintureCadran({
    required this.instant,
    required this.labelPeriode,
    required this.sousLabelPeriode,
    required this.nuit,
    required this.dernierCoucher,
    required this.trotteuseFluide,
    required this.fondCadran,
  });

  /// Instant RÉEL (DateTime.now() au moment du tracé).
  final DateTime instant;
  final String labelPeriode;
  final String sousLabelPeriode;
  final bool nuit;
  final DateTime? dernierCoucher;

  /// Balayage continu (millisecondes réelles) sinon tic-tac par seconde.
  final bool trotteuseFluide;
  final ui.Image? fondCadran;

  // ── Géométrie du cadran civil 24 h ────────────────────────────────────
  // Angles mesurés en DEGRÉS depuis le HAUT, sens horaire :
  //   00 h = 0° (haut) · 06 h = 90° (droite) · 12 h = 180° (bas) ·
  //   18 h = 270° (GAUCHE) — exactement l'image de référence.
  static const double _degresParHeure = 15.0; // 360 / 24
  static const double _degresParMinute = 6.0; // 360 / 60

  /// Position d'un point du cadran pour un angle (° depuis le haut, horaire).
  Offset _pos(Offset centre, double degres, double rayon) {
    final a = degres * math.pi / 180.0;
    return centre + Offset(math.sin(a) * rayon, -math.cos(a) * rayon);
  }

  /// Minutes écoulées DEPUIS LE DERNIER COUCHER DU SOLEIL RÉEL (0→1440) —
  /// arc du cycle biblique + heure biblique du médaillon. Repli sur 18 h
  /// si le calcul solaire est indisponible (région polaire).
  double _minutesDepuisCoucher() {
    if (dernierCoucher != null) {
      final e = instant.difference(dernierCoucher!).inSeconds / 60.0;
      if (e >= 0) return e % 1440.0;
      return 0.0;
    }
    final h = (instant.hour - 18) % 24;
    return h * 60.0 + instant.minute + instant.second / 60.0;
  }

  /// La moitié HAUTE du cadran (18 h → 06 h en passant par 00) est l'espace
  /// NUIT (ciel étoilé + lune sur l'image de fond) ; la moitié BASSE est
  /// l'espace JOUR (ciel bleu + soleil).
  bool _coteNuit(double angle) => angle >= 262.5 || angle < 97.5;

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

    // ── Graduations : 24 heures majeures + quarts d'heure mineures ──
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

    // ── CHIFFRES DES 24 HEURES CIVILES (image de référence) ──
    //   • chiffres PAIRS (00, 02 … 22) en GRANDS caractères ;
    //   • chiffres IMPAIRS (01 … 23) en petits caractères entre eux ;
    //   • 00 en haut, 18 à gauche — une révolution = 24 h ;
    //   • 06 h et 18 h : PASTILLE SOMBRE derrière le chiffre — l'effet
    //     de lumière du fond (lune/soleil du décor) rendait ces deux
    //     chiffres illisibles (corrigé v1.0.9).
    final tpChiffre = TextPainter(textDirection: TextDirection.ltr);
    for (var h = 0; h < 24; h++) {
      final angle = h * _degresParHeure;
      final pair = h.isEven;
      final coteNuit = _coteNuit(angle);
      final marqueur = h == 6 || h == 18;
      if (marqueur) {
        // Pastille sombre sous le chiffre : contraste garanti sur les
        // zones lumineuses du décor (coucher 18 h — gauche ; lever 06 h —
        // droite).
        final pPastille = _pos(centre, angle, rayon - 26);
        canvas.drawCircle(
          pPastille,
          rayon * 0.10,
          Paint()..color = const Color(0xB30B1226),
        );
      }
      tpChiffre.text = TextSpan(
        text: h.toString().padLeft(2, '0'),
        style: TextStyle(
          color: marqueur
              ? AppColors.blanc.withValues(alpha: 1.0)
              : coteNuit
                  ? (pair
                      ? AppColors.orPastel.withValues(alpha: 0.95)
                      : AppColors.orPastel.withValues(alpha: 0.72))
                  : (pair
                      ? AppColors.ardoise.withValues(alpha: 0.92)
                      : AppColors.ardoise.withValues(alpha: 0.62)),
          fontSize: rayon * (pair ? 0.115 : 0.075),
          fontWeight: pair ? FontWeight.w800 : FontWeight.w700,
        ),
      );
      tpChiffre.layout();
      final r = rayon - 26;
      tpChiffre.paint(
        canvas,
        _pos(centre, angle, r) -
            Offset(tpChiffre.width / 2, tpChiffre.height / 2),
      );
    }

    // ── MINUTEUR INTERNE : 05, 10 … 55, 60 (60 sous le 00, comme la
    //    référence) — chaque minute = 6° depuis le haut, sens horaire.
    final tpMinute = TextPainter(textDirection: TextDirection.ltr);
    for (var m = 0; m < 60; m += 5) {
      final libelle = m == 0 ? '60' : m.toString().padLeft(2, '0');
      final angle = m * _degresParMinute;
      final coteNuit = _coteNuit(angle);
      tpMinute.text = TextSpan(
        text: libelle,
        style: TextStyle(
          color: (coteNuit ? AppColors.orPastel : AppColors.grisSecondaire)
              .withValues(alpha: 0.85),
          fontSize: rayon * 0.05,
          fontWeight: FontWeight.w700,
        ),
      );
      tpMinute.layout();
      final r = rayon * 0.70;
      tpMinute.paint(
        canvas,
        _pos(centre, angle, r) -
            Offset(tpMinute.width / 2, tpMinute.height / 2),
      );
    }

    // ── Marqueurs solaires : 18 h (coucher — gauche) et 06 h (lever —
    //    droite), petits soleils dorés sur le pourtour ──
    for (final a in const [270.0, 90.0]) {
      final p = _pos(centre, a, rayon - 5.5);
      canvas.drawCircle(p, 5, Paint()..color = AppColors.orSolaire);
      canvas.drawCircle(
          p, 2.2, Paint()..color = AppColors.blanc.withValues(alpha: 0.9));
    }

    // ── Arc du cycle biblique écoulé : du coucher (270° = 18 h) à l'heure
    //    courante — la nuit balaie la moitié haute, le jour la moitié basse.
    final minutes = _minutesDepuisCoucher();
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: rayon - 5),
      (270.0 - 90) * math.pi / 180.0,
      (minutes / 1440.0) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.orSolaire.withValues(alpha: 0.75),
    );

    // ── Médaillon central : heure CIVILE (conforme aux aiguilles et à
    // l'horloge numérique — l'ancien médaillon affichait l'heure biblique
    // continue, décalée de +6 h par rapport au cadran, ce qui se lisait
    // comme une fausse heure) + période biblique en cours ──
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
      text: 'HEURE CIVILE\n',
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
          text: '${instant.hour.toString().padLeft(2, '0')} h '
              '${instant.minute.toString().padLeft(2, '0')}',
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

    // ── AIGUILLES À L'HEURE CIVILE RÉELLE (conformes à l'heure numérique) ──
    // Heures : UN TOUR PAR 24 h — 13 h 00 → 195° (entre 13 et 14, en bas à
    // gauche) ; minutes et secondes : 6° par unité.
    final fractionSeconde = instant.millisecond / 1000.0;
    final angleHeures = (instant.hour % 24 +
            instant.minute / 60.0 +
            instant.second / 3600.0) *
        _degresParHeure;
    final angleMinutes = (instant.minute + instant.second / 60.0) *
        _degresParMinute;
    // Trotteuse : FLUIDE = balayage continu sur les millisecondes réelles ;
    // TIC-TAC = saut net à chaque seconde (pas de fraction).
    final angleSecondes = (instant.second +
            (trotteuseFluide ? fractionSeconde : 0.0)) *
        _degresParMinute;

    final couleurAiguilles = nuit ? AppColors.orPastel : AppColors.ardoise;
    _aiguille(canvas, centre, angleHeures, rayon * 0.55, 7.0, couleurAiguilles);
    _aiguille(
        canvas, centre, angleMinutes, rayon * 0.76, 4.5, couleurAiguilles);
    _aiguille(canvas, centre, angleSecondes, rayon * 0.85, 2.0,
        _rougeTrotteuse);
    _contrepoids(canvas, centre, angleSecondes, rayon * 0.16, 2.0,
        _rougeTrotteuse);

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
      ancien.instant != instant ||
      ancien.labelPeriode != labelPeriode ||
      ancien.sousLabelPeriode != sousLabelPeriode ||
      ancien.nuit != nuit ||
      ancien.trotteuseFluide != trotteuseFluide ||
      ancien.dernierCoucher != dernierCoucher ||
      ancien.fondCadran != fondCadran;
}
