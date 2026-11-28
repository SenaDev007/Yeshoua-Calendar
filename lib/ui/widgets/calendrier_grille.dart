/// ⭐ VUES DU CALENDRIER MENSUEL — transposition fidèle du design du projet
/// web « calendrier de YHWH » (CalendarHeader.tsx + CalendarGrid.tsx +
/// CalendarDay.tsx) dans la palette Horloge Céleste :
///   • EN-TÊTE en dégradé radial bleu céleste (miroir du dégradé radial du
///     web) avec logo, titre, sous-titre or, navigation double chevrons
///     année/mois, bouton « Aujourd'hui », chips Jour X/364 et Semaine X/52 ;
///   • GRILLE 7 colonnes alignée sur les vrais jours de semaine du moteur
///     (cases vides en tête de mois, comme la grille web) ;
///   • MODE CARTES : grandes cartes d'au moins 2 colonnes (miroir des cartes
///     h-24 du web) avec nom de fête, badge shabbat et date grégorienne ;
///   • chaque case est animée (pression → échelle 0,93, miroir whileTap de
///     framer-motion) pour la vivacité demandée.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import 'carte_saisonniere.dart';
import 'images_fetes.dart';

// ─────────────────────────────────────────────────────────────────────
//  En-tête radial — miroir du CalendarHeader.tsx web
// ─────────────────────────────────────────────────────────────────────

class EnTeteRadialCalendrier extends StatelessWidget {
  const EnTeteRadialCalendrier({
    super.key,
    required this.annee,
    required this.mois,
    required this.jourDuJour,
    required this.sousTitreMois,
    required this.onMoisPrecedent,
    required this.onMoisSuivant,
    required this.onAnneePrecedente,
    required this.onAnneeSuivante,
    required this.onAujourdhui,
    required this.onOuvrirFetes,
  });

  final AnneeBiblique annee;
  final int mois;
  final JourBiblique? jourDuJour;
  final String sousTitreMois;
  final VoidCallback? onMoisPrecedent;
  final VoidCallback? onMoisSuivant;
  final VoidCallback? onAnneePrecedente;
  final VoidCallback? onAnneeSuivante;
  final VoidCallback onAujourdhui;
  final VoidCallback onOuvrirFetes;

  @override
  Widget build(BuildContext context) {
    final saison = ImageSaison.depuisTrimestre(((mois - 1) ~/ 3) + 1);
    final joursMois = annee.joursDuMois(mois);
    final debut = joursMois.isNotEmpty ? joursMois.first : null;
    final fin = joursMois.isNotEmpty ? joursMois.last : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -1.1),
          radius: 1.6,
          colors: [
            AppColors.bleuCiel,
            AppColors.bleuCielFonce,
            AppColors.ardoiseClair,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          children: [
            // ── Ligne 1 : logo + titre + bouton Aujourd'hui ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.blanc,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.orSolaire.withValues(alpha: 0.8),
                        width: 1.6),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo-horloge-celeste.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendrier biblique',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Le temps de l\u2019alliance de l\u2019Éternel',
                        style: TextStyle(
                          color: AppColors.orVif,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.orSolaire.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onAujourdhui,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_rounded,
                              size: 13, color: AppColors.ardoise),
                          SizedBox(width: 5),
                          Text(
                            'Aujourd\u2019hui',
                            style: TextStyle(
                              color: AppColors.ardoise,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Ligne 2 : navigation année / mois ──
            Row(
              children: [
                _chevron(Icons.keyboard_double_arrow_left_rounded,
                    onAnneePrecedente, 'Année précédente',
                    grand: true),
                _chevron(Icons.chevron_left_rounded, onMoisPrecedent,
                    'Mois précédent'),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        joursMois.isNotEmpty ? joursMois.first.nomMois : '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.orVif,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mois $mois/12 · ${annee.libelle}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.blanc.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                      if (debut != null && fin != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${debut.jourDuMois} ${debut.nomMois} → '
                            '${fin.jourDuMois} ${fin.nomMois}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.blanc.withValues(alpha: 0.7),
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _chevron(
                    Icons.chevron_right_rounded, onMoisSuivant, 'Mois suivant'),
                _chevron(Icons.keyboard_double_arrow_right_rounded,
                    onAnneeSuivante, 'Année suivante',
                    grand: true),
              ],
            ),
            const SizedBox(height: 10),

            // ── Ligne 3 : chips Jour X/364 · Semaine X/52 · saison ──
            Row(
              children: [
                if (jourDuJour != null) ...[
                  _chipOmbre(
                      'Jour de l\u2019année', '${jourDuJour!.jourDeAnnee}/364'),
                  const SizedBox(width: 8),
                  _chipOmbre('Semaine',
                      '${((jourDuJour!.jourDeAnnee - 1) ~/ 7) + 1}/52'),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: onOuvrirFetes,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: AppColors.orSolaire.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.orSolaire.withValues(alpha: 0.55)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 13, color: AppColors.orVif),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Fêtes & saisons · ${ImageSaison.noms[saison]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.orVif,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 13, color: AppColors.orVif),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                sousTitreMois,
                style: TextStyle(
                  color: AppColors.blanc.withValues(alpha: 0.66),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chevron(IconData icone, VoidCallback? onTap, String hint,
      {bool grand = false}) {
    return Tooltip(
      message: hint,
      child: Material(
        color: grand
            ? AppColors.ardoise.withValues(alpha: 0.35)
            : AppColors.blanc.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(grand ? 7 : 5),
            child: Icon(icone, size: grand ? 22 : 18, color: AppColors.orVif),
          ),
        ),
      ),
    );
  }

  Widget _chipOmbre(String label, String valeur) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.ardoise.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label : ',
              style: TextStyle(
                color: AppColors.orVif,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              valeur,
              style: const TextStyle(
                color: AppColors.blanc,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────
//  Grille du mois — alignement réel sur jourDeSemaine (miroir web)
// ─────────────────────────────────────────────────────────────────────

class GrilleMois extends StatelessWidget {
  const GrilleMois({
    super.key,
    required this.joursMois,
    required this.fetesParJour,
    required this.jourSelectionne,
    required this.onJourTape,
    this.jourEnCours,
    this.modeHebreu = false,
  });

  final List<JourBiblique> joursMois;
  final Map<int, List<FeteBiblique>> fetesParJour;
  final JourBiblique? jourSelectionne;
  final ValueChanged<JourBiblique> onJourTape;

  /// Date civile du jour biblique EN COURS (coucher du soleil réel) —
  /// fournie par l'écran calendrier depuis l'état de l'horloge ; null →
  /// repli sur la date civile (comportement historique).
  final DateTime? jourEnCours;

  /// MODE HÉBRAÏQUE (§7) : en-têtes translittérés (Ehad … Shabbat).
  final bool modeHebreu;

  @override
  Widget build(BuildContext context) {
    final decalage =
        joursMois.isNotEmpty ? joursMois.first.jourDeSemaine - 1 : 0;
    final entetes = entetesGrille(modeHebreu);

    // Cases de la grille : vides d'alignement + jours du mois + vides de fin,
    // puis découpage par lignes de 7 — même principe que la grille web.
    final cases = <Widget>[
      for (var i = 0; i < decalage; i++)
        const Expanded(child: SizedBox.shrink()),
      for (final j in joursMois)
        Expanded(
          child: CelluleJourAnimee(
            jour: j,
            fetes: fetesParJour[j.jourDuMois] ?? const [],
            estSelectionne: _memeJour(jourSelectionne, j),
            jourEnCours: jourEnCours,
            onTape: onJourTape,
          ),
        ),
      for (var i = (decalage + joursMois.length) % 7; i > 0 && i < 7; i++)
        const Expanded(child: SizedBox.shrink()),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ardoisePastel),
        boxShadow: [
          BoxShadow(
            color: AppColors.ardoise.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-têtes des jours — abrégés ou translittérés (mode hébraïque).
          Row(
            children: [
              for (final e in entetes)
                Expanded(
                  child: Center(
                    child: Text(
                      e,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: e == 'Shabbat' || e == 'Shab.'
                            ? AppColors.orFonce
                            : AppColors.grisSecondaire,
                        fontSize: e == 'Shabbat' || e == 'Shab.' ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var ligne = 0; ligne < cases.length; ligne += 7)
            Padding(
              padding: const EdgeInsets.only(top: 1.2),
              child: Row(
                children: cases.skip(ligne).take(7).toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  static bool _memeJour(JourBiblique? a, JourBiblique b) =>
      a != null &&
      a.mois == b.mois &&
      a.jourDuMois == b.jourDuMois &&
      a.dateGregorienne.year == b.dateGregorienne.year;
}

/// Une case de jour animée — miroir des boutons de la grille web
/// (whileHover 1.05 / whileTap 0.95 de framer-motion).
class CelluleJourAnimee extends StatefulWidget {
  const CelluleJourAnimee({
    super.key,
    required this.jour,
    required this.fetes,
    required this.estSelectionne,
    required this.onTape,
    this.jourEnCours,
  });

  final JourBiblique jour;
  final List<FeteBiblique> fetes;
  final bool estSelectionne;
  final ValueChanged<JourBiblique> onTape;

  /// Date civile du jour biblique en cours (§2.3) — surlignage
  /// « aujourd'hui » conforme au coucher du soleil réel.
  final DateTime? jourEnCours;

  @override
  State<CelluleJourAnimee> createState() => _CelluleJourAnimeeState();
}

class _CelluleJourAnimeeState extends State<CelluleJourAnimee>
    with SingleTickerProviderStateMixin {
  bool _appuye = false;

  /// EFFET FESTIVAL (§7) : halo doré qui PULSE autour des shabbats et des
  /// fêtes — l'effet « waouh » demandé, visible dès la grille mensuelle.
  AnimationController? _halo;

  bool get _festif => widget.fetes.isNotEmpty || widget.jour.estShabbat;

  @override
  void initState() {
    super.initState();
    _syncHalo();
  }

  @override
  void didUpdateWidget(CelluleJourAnimee ancien) {
    super.didUpdateWidget(ancien);
    _syncHalo();
  }

  void _syncHalo() {
    if (_festif && _halo == null) {
      _halo = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    } else if (!_festif && _halo != null) {
      _halo!.dispose();
      _halo = null;
    }
  }

  @override
  void dispose() {
    _halo?.dispose();
    super.dispose();
  }

  bool get _estAujourdhui {
    final g = widget.jour.dateGregorienne;
    final ref = widget.jourEnCours;
    if (ref != null) {
      return g.year == ref.year && g.month == ref.month && g.day == ref.day;
    }
    final d = DateTime.now();
    return g.year == d.year && g.month == d.month && g.day == d.day;
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jour;
    final fetes = widget.fetes;
    final aFete = fetes.isNotEmpty;
    // ⚠️ Ne JAMAIS appeler fetes.first sans garde : la grille du mois
    // plantait (StateError) pour tout jour sans fête — bug masqué jusque-là
    // par la NavigationBar morte.
    final couleurFete = aFete ? AppColors.depuisHex(fetes.first.couleur) : null;
    final estAujourdhui = _estAujourdhui;
    final couleurHalo = aFete ? couleurFete! : AppColors.orSolaire;

    Color fond = Colors.transparent;
    if (j.estShabbat) fond = AppColors.orSolaire.withValues(alpha: 0.14);
    if (aFete) fond = couleurFete!.withValues(alpha: 0.16);
    if (widget.estSelectionne) {
      fond = AppColors.bleuCiel.withValues(alpha: 0.14);
    }

    final couleurNumero = aFete
        ? couleurFete!
        : j.estShabbat
            ? AppColors.orFonce
            : AppColors.ardoise;

    // Bordure festive dorée / couleur de fête (liseré du festival).
    Color? bordureFestive;
    if (aFete) {
      bordureFestive = couleurFete!.withValues(alpha: 0.65);
    } else if (j.estShabbat) {
      bordureFestive = AppColors.orSolaire.withValues(alpha: 0.60);
    }

    final contenu = GestureDetector(
      onTapDown: (_) => setState(() => _appuye = true),
      onTapCancel: () => setState(() => _appuye = false),
      onTapUp: (_) {
        setState(() => _appuye = false);
        HapticFeedback.selectionClick();
        widget.onTape(j);
      },
      child: AnimatedScale(
        scale: _appuye ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          margin: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.estSelectionne
                  ? AppColors.bleuCiel
                  : estAujourdhui
                      ? AppColors.orSolaire
                      : bordureFestive ?? Colors.transparent,
              width: widget.estSelectionne || estAujourdhui
                  ? 2
                  : bordureFestive != null
                      ? 1.4
                      : 0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${j.jourDuMois}',
                style: TextStyle(
                  color: couleurNumero,
                  fontSize: 13.5,
                  fontWeight:
                      aFete || j.estShabbat ? FontWeight.w800 : FontWeight.w600,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${j.dateGregorienne.day}/${j.dateGregorienne.month}',
                style: TextStyle(
                  color: AppColors.grisSecondaire.withValues(alpha: 0.72),
                  fontSize: 8,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              // Image symbolique en miniature : l'agneau de Pessah, le
              // shofar, les matzot… directement dans la case du jour.
              if (aFete)
                Tooltip(
                  message: fetes.map((f) => f.nomFr).join(' · '),
                  child: MedaillonFete(
                      asset: imagePourFete(fetes.first), taille: 20),
                )
              else if (j.estShabbat)
                MedaillonFete(asset: imageShabbat, taille: 18)
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );

    // Halo pulsé uniquement pour les jours festifs (économie de rendu).
    if (_halo == null) return contenu;
    return AnimatedBuilder(
      animation: _halo!,
      builder: (context, _) {
        final pulse = _halo!.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: couleurHalo.withValues(alpha: 0.22 + 0.30 * pulse),
                blurRadius: 7 + 9 * pulse,
                spreadRadius: 0.6 + 0.8 * pulse,
              ),
            ],
          ),
          child: contenu,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  MODE CARTES — miroir des grandes cartes CalendarDay.tsx (h-24)
// ─────────────────────────────────────────────────────────────────────

class CartesMois extends StatelessWidget {
  const CartesMois({
    super.key,
    required this.joursMois,
    required this.fetesParJour,
    required this.jourSelectionne,
    required this.onJourTape,
    this.jourEnCours,
    this.modeHebreu = false,
  });

  final List<JourBiblique> joursMois;
  final Map<int, List<FeteBiblique>> fetesParJour;
  final JourBiblique? jourSelectionne;
  final ValueChanged<JourBiblique> onJourTape;

  /// Date civile du jour biblique en cours — surlignage « aujourd'hui ».
  final DateTime? jourEnCours;

  /// MODE HÉBRAÏQUE (§7) : noms des jours translittérés sur les cartes.
  final bool modeHebreu;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.62,
      ),
      itemCount: joursMois.length,
      itemBuilder: (context, index) => CarteJourAnimee(
        jour: joursMois[index],
        fetes: fetesParJour[joursMois[index].jourDuMois] ?? const [],
        estSelectionne: GrilleMois._memeJour(jourSelectionne, joursMois[index]),
        jourEnCours: jourEnCours,
        onTape: onJourTape,
        modeHebreu: modeHebreu,
      ),
    );
  }
}

class CarteJourAnimee extends StatefulWidget {
  const CarteJourAnimee({
    super.key,
    required this.jour,
    required this.fetes,
    required this.estSelectionne,
    required this.onTape,
    this.jourEnCours,
    this.modeHebreu = false,
  });

  final JourBiblique jour;
  final List<FeteBiblique> fetes;
  final bool estSelectionne;
  final ValueChanged<JourBiblique> onTape;

  /// Date civile du jour biblique en cours (§2.3) — surlignage
  /// « aujourd'hui » conforme au coucher du soleil réel.
  final DateTime? jourEnCours;

  /// MODE HÉBRAÏQUE (§7) : nom du jour translittéré (Yom Shabbat…).
  final bool modeHebreu;

  @override
  State<CarteJourAnimee> createState() => _CarteJourAnimeeState();
}

class _CarteJourAnimeeState extends State<CarteJourAnimee>
    with SingleTickerProviderStateMixin {
  bool _appuye = false;

  /// EFFET FESTIVAL (§7) : halo pulsé autour des cartes de shabbat et de
  /// fêtes — effet « waouh » en mode cartes.
  AnimationController? _halo;

  bool get _festif => widget.fetes.isNotEmpty || widget.jour.estShabbat;

  @override
  void initState() {
    super.initState();
    _syncHalo();
  }

  @override
  void didUpdateWidget(CarteJourAnimee ancien) {
    super.didUpdateWidget(ancien);
    _syncHalo();
  }

  void _syncHalo() {
    if (_festif && _halo == null) {
      _halo = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1700),
      )..repeat(reverse: true);
    } else if (!_festif && _halo != null) {
      _halo!.dispose();
      _halo = null;
    }
  }

  @override
  void dispose() {
    _halo?.dispose();
    super.dispose();
  }

  bool get _estAujourdhui {
    final g = widget.jour.dateGregorienne;
    final ref = widget.jourEnCours;
    if (ref != null) {
      return g.year == ref.year && g.month == ref.month && g.day == ref.day;
    }
    final d = DateTime.now();
    return g.year == d.year && g.month == d.month && g.day == d.day;
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jour;
    final fetes = widget.fetes;
    final aFete = fetes.isNotEmpty;
    final couleurFete = aFete ? AppColors.depuisHex(fetes.first.couleur) : null;
    final estAujourdhui = _estAujourdhui;
    final couleurHalo = aFete ? couleurFete! : AppColors.orSolaire;
    final assetFete =
        aFete ? imagePourFete(fetes.first) : (j.estShabbat ? imageShabbat : '');

    Color fond = AppColors.blanc;
    Color? bordure = AppColors.ardoisePastel.withValues(alpha: 0.8);
    if (j.estShabbat) {
      fond = AppColors.orSolaire.withValues(alpha: 0.12);
      bordure = AppColors.orSolaire.withValues(alpha: 0.5);
    }
    if (aFete) {
      fond = couleurFete!.withValues(alpha: 0.13);
      bordure = couleurFete.withValues(alpha: 0.55);
    }
    if (estAujourdhui) bordure = AppColors.bleuCiel;
    if (widget.estSelectionne) bordure = AppColors.bleuCielFonce;

    final contenu = GestureDetector(
      onTapDown: (_) => setState(() => _appuye = true),
      onTapCancel: () => setState(() => _appuye = false),
      onTapUp: (_) {
        setState(() => _appuye = false);
        HapticFeedback.selectionClick();
        widget.onTape(j);
      },
      child: AnimatedScale(
        scale: _appuye ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: bordure!,
              width: widget.estSelectionne || estAujourdhui
                  ? 2
                  : (_festif ? 1.6 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ardoise.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${j.jourDuMois}',
                    style: TextStyle(
                      color: aFete
                          ? couleurFete!
                          : j.estShabbat
                              ? AppColors.orFonce
                              : AppColors.ardoise,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      nomJourAfficheCourt(j.nomJourSemaine, widget.modeHebreu),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Image symbolique de la fête ou du shabbat — l'agneau de
                  // Pessah, le shofar de Teroua, les matzot, la cabane…
                  if (assetFete.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    MedaillonFete(asset: assetFete, taille: 40),
                    const SizedBox(width: 6),
                  ],
                  if (estAujourdhui)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.bleuCiel,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Aujourd\u2019hui',
                        style: TextStyle(
                          color: AppColors.blanc,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              if (aFete)
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: couleurFete),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        fetes.map((f) => f.nomFr).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: couleurFete,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                )
              else if (j.estShabbat)
                const Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 12, color: AppColors.orSolaire),
                    SizedBox(width: 4),
                    Text(
                      'Shabbat — repos saint',
                      style: TextStyle(
                        color: AppColors.orFonce,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 14),
              const SizedBox(height: 4),
              Text(
                'Jour ${j.jourDeAnnee}/364 · ${j.dateGregorienne.day}/${j.dateGregorienne.month}/${j.dateGregorienne.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.grisSecondaire.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Halo pulsé AROUND la carte — effet de festival pour le shabbat et
    // chaque fête de l'Alliance (§7).
    if (_halo == null) return contenu;
    return AnimatedBuilder(
      animation: _halo!,
      builder: (context, _) {
        final pulse = _halo!.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: couleurHalo.withValues(alpha: 0.20 + 0.32 * pulse),
                blurRadius: 10 + 12 * pulse,
                spreadRadius: 0.8 + 1.2 * pulse,
              ),
            ],
          ),
          child: contenu,
        );
      },
    );
  }
}
