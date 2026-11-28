/// ⭐ ÉCRAN CALENDRIER (§7) — REPRODUCTION FIDÈLE du calendrier biblique
/// de 364 jours déjà implémenté dans Yeshua Connect Mobile, HABILLÉ du
/// design du projet web « calendrier de YHWH » (en-tête radial, grille
/// alignée sur les jours de semaine, clic sur une date → fiche détaillée
/// avec zones et légendes, mode grille / mode cartes) :
///   • moteur LOCAL hors connexion (parité 100 % avec le backend,
///     prouvée par les tests du package horloge_celeste_engine) ;
///   • palette officielle Horloge Céleste (bleu céleste / or solaire / ivoire) ;
///   • coucher du soleil RÉEL LOCAL (plus de 18 h 00 symboliques) ;
///   • changement de date biblique synchronisé au coucher réel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import '../../state/horloge_controller.dart';
import '../../state/settings_controller.dart';
import '../widgets/calendrier_grille.dart';
import '../widgets/carte_saisonniere.dart';
import '../widgets/cartes.dart';
import '../widgets/fetes_et_saisons.dart';
import '../widgets/fiche_jour.dart';
import '../widgets/images_fetes.dart';

class CalendrierScreen extends ConsumerStatefulWidget {
  const CalendrierScreen({super.key});

  @override
  ConsumerState<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends ConsumerState<CalendrierScreen>
    with TickerProviderStateMixin {
  int _moisCourant = 1;
  int _decalageAnnee = 0; // navigation ◀ ▶ entre années
  bool _moisInitialise = false;
  bool _modeCartes = false; // mode de visualisation : grille ou cartes
  JourBiblique? _jourSelectionne;
  int _semaineCourante = 1;
  bool _semaineInitialisee = false;
  int _trimestreCourant = 1;
  bool _trimestreInitialise = false;

  /// Contrôleur explicite : les vues Semaine / Trimestre / Année peuvent
  /// sauter vers l'onglet « Mois » au tap d'une mini-grille de l'année.
  late final TabController _onglets = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _onglets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(horlogeProvider);
    // MODE HÉBRAÏQUE (§7) — translittération des jours du calendrier.
    final hebreu = ref.watch(settingsProvider).modeHebreu;
    final anneeReference = etat.anneeBiblique?.annee ??
        BiblicalCalendarEngine.anneePourDate(DateTime.now()).annee;
    final anneeChoisie = (anneeReference + _decalageAnnee).clamp(
        BiblicalCalendarEngine.anneeMin, BiblicalCalendarEngine.anneeMax);
    final annee = BiblicalCalendarEngine.construireAnnee(anneeChoisie);

    // Mois courant = celui qui contient aujourd'hui (init une seule fois).
    if (!_moisInitialise) {
      _moisInitialise = true;
      final j = annee.jourPourDate(DateTime.now());
      _moisCourant = j?.mois ?? 1;
      _jourSelectionne = j;
    }
    // Semaine et trimestre courants — même principe d'initialisation.
    if (!_semaineInitialisee) {
      _semaineInitialisee = true;
      final j = annee.jourPourDate(DateTime.now());
      _semaineCourante = j != null ? ((j.jourDeAnnee - 1) ~/ 7) + 1 : 1;
    }
    if (!_trimestreInitialise) {
      _trimestreInitialise = true;
      final j = annee.jourPourDate(DateTime.now());
      _trimestreCourant = j?.trimestre ?? 1;
    }

    return Column(
      children: [
        TabBar(
          controller: _onglets,
          indicatorColor: AppColors.bleuCiel,
          labelColor: AppColors.bleuCiel,
          unselectedLabelColor: AppColors.grisSecondaire,
          dividerColor: Colors.transparent,
          labelStyle:
              const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.today_outlined), text: 'Aujourd\u2019hui'),
            Tab(icon: Icon(Icons.calendar_view_week_rounded), text: 'Semaine'),
            Tab(icon: Icon(Icons.calendar_view_month_outlined), text: 'Mois'),
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Trimestre'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Année'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _onglets,
            children: [
              _vueAujourdhui(etat, annee, hebreu),
              _vueSemaine(annee, etat, hebreu),
              _vueMensuelle(annee, etat, hebreu),
              _vueTrimestre(annee, etat, hebreu),
              _vueAnnee(annee, etat),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Vue 1 : aujourd'hui ────────────────────────────────────────────

  Widget _vueAujourdhui(HorlogeState etat, AnneeBiblique annee, bool hebreu) {
    final jour = etat.jourBiblique ?? annee.jourPourDate(DateTime.now());
    final maintenant = etat.maintenant;
    // Fêtes à venir (joursRestants ≥ 0).
    final fetesAVenir = annee.fetes
        .map((f) => (
              fete: f,
              joursRestants: BiblicalCalendarEngine.joursRestants(f,
                  maintenant: maintenant)
            ))
        .where((x) => x.joursRestants >= 0)
        .toList()
      ..sort((a, b) => a.joursRestants.compareTo(b.joursRestants));
    final prochaineFete = fetesAVenir.isNotEmpty ? fetesAVenir.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (jour != null) ...[
          _carteJourBiblique(jour, maintenant, etat, hebreu),
          const SizedBox(height: 12),
          _carteCoucherSoleil(etat),
          const SizedBox(height: 12),
        ],
        if (prochaineFete != null) ...[
          _carteProchaineFete(prochaineFete.fete, prochaineFete.joursRestants),
          const SizedBox(height: 12),
        ],
        TitreSection(
          'Fêtes de l\u2019Éternel à venir',
          icone: Icons.celebration_outlined,
          couleur: AppColors.orSolaire,
        ),
        if (fetesAVenir.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Aucune autre fête à venir dans cette année biblique — '
              'naviguez vers l\u2019année suivante.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisSecondaire, fontSize: 12.5),
            ),
          ),
        for (final x in fetesAVenir.skip(1))
          _carteFete(x.fete, x.joursRestants),
      ],
    );
  }

  Widget _carteJourBiblique(
      JourBiblique j, DateTime maintenant, HorlogeState etat, bool hebreu) {
    final aujourdhui =
        DateTime(maintenant.year, maintenant.month, maintenant.day);
    final estJourCourant = j.dateGregorienne == aujourdhui;
    final saisonImage = ImageSaison.depuisTrimestre(j.trimestre);
    final saison = ImageSaison.noms[saisonImage]!;

    // Carte principale avec IMAGE DE SAISON sous voile — même
    // embellissement que la carte « jour en cours » de la page web.
    return BandeauSaisonnier(
      saison: saisonImage,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.orVif),
              const SizedBox(width: 6),
              Text(
                estJourCourant
                    ? 'JOUR BIBLIQUE EN COURS · $saison'
                    : 'JOUR BIBLIQUE · $saison',
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
            '${j.jourDuMois} ${j.nomMois}',
            style: const TextStyle(
              color: AppColors.blanc,
              fontWeight: FontWeight.w800,
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${nomJourAffiche(j.nomJourSemaine, hebreu)} · '
            'Jour ${j.jourDeAnnee} de l\u2019année ${etat.anneeBiblique?.libelle ?? ''}',
            style: TextStyle(
                color: AppColors.blanc.withValues(alpha: 0.82), fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.orVif),
              const SizedBox(width: 6),
              Text(
                dateCourteFrancais(j.dateGregorienne),
                style: TextStyle(
                  color: AppColors.blanc.withValues(alpha: 0.85),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          if (j.estShabbat) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.orSolaire.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.orSolaire.withValues(alpha: 0.6)),
              ),
              child: const Text(
                'Shabbat — du coucher du soleil au coucher du soleil',
                style: TextStyle(
                  color: AppColors.orVif,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Trimestre ${j.trimestre} · Mois ${j.mois}/12 · Saison de $saison',
            style: TextStyle(
              color: AppColors.blanc.withValues(alpha: 0.75),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Compte à rebours du COUCHER RÉEL LOCAL — improvement directe du
  /// miroir web qui affichait « ~18:00 UTC » (§2.3 : le coucher réel
  /// constitue la référence).
  Widget _carteCoucherSoleil(HorlogeState etat) {
    return CarteCeleste(
      bordure: AppColors.orSolaire.withValues(alpha: 0.45),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_twilight, size: 18, color: AppColors.orSolaire),
              SizedBox(width: 8),
              Text(
                'Coucher de soleil',
                style: TextStyle(
                  color: AppColors.ardoise,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Le jour biblique se termine au coucher du soleil réel de '
            '${etat.position.libelle}.',
            style: const TextStyle(
                color: AppColors.grisSecondaire, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          BoitesCompteARebours(
            duree: etat.compteAReboursCoucher,
            accent: AppColors.orSolaire,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined,
                  size: 12, color: AppColors.orSolaire),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Prochain coucher : ${etat.prochainCoucher != null ? heureCivilFormat(etat.prochainCoucher!) : '—'} (heure locale)',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.9),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _carteProchaineFete(FeteBiblique fete, int joursRestants) {
    final couleur = AppColors.depuisHex(fete.couleur);
    final asset = imagePourFete(fete);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // IMAGE SYMBOLIQUE de la fête — l'agneau de Pessah, les matzot,
              // le shofar… (§7).
              if (asset.isNotEmpty) ...[
                MedaillonFete(asset: asset, taille: 52),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROCHAINE FÊTE',
                      style: TextStyle(
                        color: couleur.withValues(alpha: 1.0),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fete.nomFr,
                      style: const TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (fete.nomHebrew != null && fete.nomHebrew!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                fete.nomHebrew!,
                style: const TextStyle(color: AppColors.ardoise, fontSize: 13),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            joursRestants == 0
                ? 'Aujourd\u2019hui !'
                : 'Dans $joursRestants ${joursRestants == 1 ? 'jour' : 'jours'}',
            style: const TextStyle(
              color: AppColors.ardoise,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${fete.dateBiblique} — ${dateCourteFrancais(fete.dateGregorienne)}',
            style: const TextStyle(
              color: AppColors.grisSecondaire,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteFete(FeteBiblique fete, int joursRestants) {
    final couleur = AppColors.depuisHex(fete.couleur);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: couleur, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ardoisePastel.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // IMAGE SYMBOLIQUE de la fête (§7).
          MedaillonFete(asset: imagePourFete(fete), taille: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fete.nomFr}${fete.nomHebrew != null ? ' · ${fete.nomHebrew}' : ''}',
                  style: const TextStyle(
                    color: AppColors.ardoise,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${fete.dateBiblique} — ${dateCourteFrancais(fete.dateGregorienne)}'
                  '${fete.dureeJours > 1 ? ' · ${fete.dureeJours} jours' : ''}',
                  style: const TextStyle(
                      color: AppColors.grisSecondaire, fontSize: 12.5),
                ),
                Text(
                  fete.referenceEcritures,
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.orSolaire.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'J-$joursRestants',
              style: const TextStyle(
                color: AppColors.orFonce,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Aides de navigation Semaine / Trimestre ────────────────────────

  /// Les 7 jours de la semaine [semaine] (1-52) de l'année donnée.
  List<JourBiblique> _joursSemaine(AnneeBiblique annee, int semaine) =>
      annee.jours
          .where((j) => ((j.jourDeAnnee - 1) ~/ 7) + 1 == semaine)
          .toList();

  void _changerSemaine(AnneeBiblique annee, {required int delta}) {
    setState(() {
      final cible = _semaineCourante + delta;
      if (cible >= 1 && cible <= 52) {
        _semaineCourante = cible;
        final js = _joursSemaine(annee, cible);
        if (js.isNotEmpty) _jourSelectionne = js.first;
        return;
      }
      // Passage d'année : semaine 52 → 1 de l'année suivante (et inverse).
      final deltaAnnee = cible < 1 ? -1 : 1;
      _decalageAnnee += deltaAnnee;
      _semaineCourante = cible < 1 ? 52 : 1;
      final anneeCible = BiblicalCalendarEngine.construireAnnee(
          (annee.annee + deltaAnnee).clamp(BiblicalCalendarEngine.anneeMin,
              BiblicalCalendarEngine.anneeMax));
      final js = _joursSemaine(anneeCible, _semaineCourante);
      if (js.isNotEmpty) _jourSelectionne = js.first;
    });
  }

  void _changerTrimestre(AnneeBiblique annee, {required int delta}) {
    setState(() {
      final cible = _trimestreCourant + delta;
      List<JourBiblique> joursCible;
      if (cible >= 1 && cible <= 4) {
        _trimestreCourant = cible;
        joursCible = annee.jours.where((j) => j.trimestre == cible).toList();
      } else {
        // Passage d'année : trimestre 4 → 1 de l'année suivante (et inverse).
        final deltaAnnee = cible < 1 ? -1 : 1;
        _decalageAnnee += deltaAnnee;
        _trimestreCourant = cible < 1 ? 4 : 1;
        final anneeCible = BiblicalCalendarEngine.construireAnnee(
            (annee.annee + deltaAnnee).clamp(BiblicalCalendarEngine.anneeMin,
                BiblicalCalendarEngine.anneeMax));
        joursCible = anneeCible.jours
            .where((j) => j.trimestre == _trimestreCourant)
            .toList();
      }
      if (joursCible.isNotEmpty) _jourSelectionne = joursCible.first;
    });
  }

  // ─── Vue 2 : vue hebdomadaire — les 7 jours de la semaine courante ──

  Widget _vueSemaine(AnneeBiblique annee, HorlogeState etat, bool hebreu) {
    final jours = _joursSemaine(annee, _semaineCourante);
    final jourDuJour = annee.jourPourDate(etat.maintenant);

    if (jours.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 40),
          Text(
            'Semaine introuvable dans cette année biblique.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grisSecondaire, fontSize: 12.5),
          ),
        ],
      );
    }

    final debut = jours.first;
    final fin = jours.last;
    final saisonImage = ImageSaison.depuisTrimestre(debut.trimestre);
    final saison = ImageSaison.noms[saisonImage]!;

    // Fêtes de la semaine (ouvertures, sans doublons de durée).
    final fetesSemaine = <FeteBiblique>[];
    for (final j in jours) {
      for (final f in fetesDuJour(annee, j)) {
        if (!fetesSemaine.any((x) => x.id == f.id)) fetesSemaine.add(f);
      }
    }
    final fetesSelectionnees = _jourSelectionne != null
        ? fetesDuJour(annee, _jourSelectionne!)
        : const <FeteBiblique>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        _enteteSemaine(annee, jours, saison, jourDuJour),
        const SizedBox(height: 12),
        TitreSection(
          'Les 7 jours de la semaine $_semaineCourante',
          icone: Icons.calendar_view_week_rounded,
          couleur: AppColors.bleuCiel,
        ),
        for (final j in jours)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _tuileJour(annee, j, hebreu),
          ),
        const SizedBox(height: 6),
        if (_jourSelectionne != null)
          FicheJour(
            jour: _jourSelectionne!,
            annee: annee,
            fetes: fetesSelectionnees,
            modeHebreu: hebreu,
          ),
        const SizedBox(height: 14),
        const LegendeCalendrier(),
        const SizedBox(height: 14),
        TitreSection(
          'Fêtes de cette semaine',
          icone: Icons.celebration_outlined,
          couleur: AppColors.orSolaire,
        ),
        if (fetesSemaine.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blanc.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.ardoisePastel.withValues(alpha: 0.7)),
            ),
            child: const Text(
              'Aucune convocation sainte cette semaine — le shabbat '
              'hebdomadaire rythme seul le temps de l\u2019alliance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisSecondaire, fontSize: 12),
            ),
          )
        else
          for (final f in fetesSemaine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _carteFete(f, BiblicalCalendarEngine.joursRestants(f)),
            ),
      ],
    );
  }

  /// En-tête radial de la vue Semaine — même habillage que la vue mensuelle
  /// (dégradé radial, navigation ◀ ▶, chips jours/semaine, Aujourd'hui).
  Widget _enteteSemaine(AnneeBiblique annee, List<JourBiblique> jours,
      String saison, JourBiblique? jourDuJour) {
    final debut = jours.first;
    final fin = jours.last;
    final semaineDuJour =
        jourDuJour != null ? ((jourDuJour.jourDeAnnee - 1) ~/ 7) + 1 : null;
    final peutReculer = _semaineCourante > 1 ||
        _decalageAnnee > (BiblicalCalendarEngine.anneeMin - annee.annee);
    final peutAvancer = _semaineCourante < 52 ||
        _decalageAnnee < (BiblicalCalendarEngine.anneeMax - annee.annee);

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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                _chevronNav(
                    Icons.chevron_left_rounded,
                    peutReculer
                        ? () => _changerSemaine(annee, delta: -1)
                        : null,
                    'Semaine précédente',
                    sombre: true),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Semaine $_semaineCourante/52',
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
                        'du ${dateCourteFrancais(debut.dateGregorienne)} au '
                        '${dateCourteFrancais(fin.dateGregorienne)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.blanc.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Trimestre ${debut.trimestre} · Saison de $saison · '
                        '${annee.libelle}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.blanc.withValues(alpha: 0.7),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _chevronNav(
                    Icons.chevron_right_rounded,
                    peutAvancer ? () => _changerSemaine(annee, delta: 1) : null,
                    'Semaine suivante',
                    sombre: true),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Flexible(
                  child: _chipEnTete(
                      'Jours', '${debut.jourDeAnnee}–${fin.jourDeAnnee}'),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _chipEnTete('Semaine', '$_semaineCourante/52'),
                ),
                const SizedBox(width: 8),
                Expanded(child: _chipFetes(annee, saison)),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _boutonAujourdhui(() {
                setState(() {
                  if (jourDuJour != null) {
                    _semaineCourante = semaineDuJour ?? _semaineCourante;
                    _jourSelectionne = jourDuJour;
                  }
                });
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Tuile d'un jour de la semaine — liseré fête/shabbat, badge
  /// « Aujourd'hui », sélection → fiche détaillée. Dates ABRÉGÉES et noms
  /// de jours translittérés selon le mode (§7).
  Widget _tuileJour(AnneeBiblique annee, JourBiblique j, bool hebreu) {
    final fetes = fetesDuJour(annee, j);
    final couleur =
        fetes.isNotEmpty ? AppColors.depuisHex(fetes.first.couleur) : null;
    final estSelectionne = _jourSelectionne != null &&
        _jourSelectionne!.jourDeAnnee == j.jourDeAnnee;
    final g = j.dateGregorienne;
    final aujourdhui = DateTime.now();
    final estAujourdhui = g.year == aujourdhui.year &&
        g.month == aujourdhui.month &&
        g.day == aujourdhui.day;
    final bordure = estSelectionne
        ? AppColors.bleuCiel
        : estAujourdhui
            ? AppColors.orSolaire
            : AppColors.ardoisePastel;

    return Material(
      color: estSelectionne
          ? AppColors.bleuCiel.withValues(alpha: 0.06)
          : AppColors.blanc,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _jourSelectionne = j),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: bordure,
              width: estSelectionne || estAujourdhui ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: j.estShabbat
                      ? AppColors.orSolaire.withValues(alpha: 0.14)
                      : AppColors.bleuCiel.withValues(alpha: 0.10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${j.jourDuMois}',
                      style: TextStyle(
                        color: couleur ??
                            (j.estShabbat
                                ? AppColors.orFonce
                                : AppColors.bleuCielFonce),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      j.nomMois,
                      style: const TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 6.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${nomJourAffiche(j.nomJourSemaine, hebreu)} · '
                            'Jour ${j.jourDeAnnee}/364',
                            style: const TextStyle(
                              color: AppColors.ardoise,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (estAujourdhui) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.orSolaire.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Aujourd\u2019hui',
                              style: TextStyle(
                                color: AppColors.orFonce,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateCourteFrancais(g),
                      style: const TextStyle(
                          color: AppColors.grisSecondaire, fontSize: 11.5),
                    ),
                    if (fetes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          fetes.map((f) => f.nomFr).join(' · '),
                          style: TextStyle(
                            color: couleur!,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (j.estShabbat) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded,
                    size: 16, color: AppColors.orSolaire),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chevronNav(IconData icone, VoidCallback? onTap, String hint,
      {bool sombre = false}) {
    return Tooltip(
      message: hint,
      child: Material(
        color: sombre
            ? AppColors.blanc.withValues(alpha: 0.16)
            : AppColors.bleuCielPastel.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icone,
                size: 20,
                color: sombre ? AppColors.orVif : AppColors.bleuCielFonce),
          ),
        ),
      ),
    );
  }

  Widget _chipEnTete(String label, String valeur) => Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.ardoise.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        // FittedBox : le chip se réduit proprement sur les petits écrans.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label : ',
                style: const TextStyle(
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
        ),
      );

  Widget _chipFetes(AnneeBiblique annee, String saison) => GestureDetector(
        onTap: () => ouvrirFetesEtSaisons(context, annee),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: AppColors.orSolaire.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: AppColors.orSolaire.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 13, color: AppColors.orVif),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  'Fêtes & saisons · $saison',
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
      );

  Widget _boutonAujourdhui(VoidCallback? onTap) => Material(
        color: AppColors.orSolaire.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home_rounded, size: 13, color: AppColors.ardoise),
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
      );

  // ─── Vue 3 : vue trimestrielle — la saison entière, ses 3 mois ──────

  Widget _vueTrimestre(AnneeBiblique annee, HorlogeState etat, bool hebreu) {
    final saison = ImageSaison.depuisTrimestre(_trimestreCourant);
    final nom = ImageSaison.noms[saison]!;
    final joursTrimestre =
        annee.jours.where((j) => j.trimestre == _trimestreCourant).toList();
    final shabbatsTrimestre = joursTrimestre.where((j) => j.estShabbat).length;
    final moisDuTrimestre = [
      (_trimestreCourant - 1) * 3 + 1,
      (_trimestreCourant - 1) * 3 + 2,
      (_trimestreCourant - 1) * 3 + 3,
    ];

    // Solennités de la saison (ouvertures, sans répétitions de durée).
    final fetesSaison = <FeteBiblique>[];
    final idsVus = <String>{};
    for (final f in annee.fetes) {
      final j = annee.jourPourDate(f.dateGregorienne);
      if (j == null || j.trimestre != _trimestreCourant) continue;
      final idBase = f.id.replaceFirst(RegExp(r'-\d+$'), '');
      if (idsVus.add(idBase)) fetesSaison.add(f);
    }
    final fetesSelectionnees = _jourSelectionne != null
        ? fetesDuJour(annee, _jourSelectionne!)
        : const <FeteBiblique>[];
    final peutReculer = _trimestreCourant > 1 ||
        _decalageAnnee > (BiblicalCalendarEngine.anneeMin - annee.annee);
    final peutAvancer = _trimestreCourant < 4 ||
        _decalageAnnee < (BiblicalCalendarEngine.anneeMax - annee.annee);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        FriseSaisonnier(
          saison: saison,
          titre: 'Saison $_trimestreCourant · $nom',
          sousTitre: joursTrimestre.isNotEmpty
              ? 'Jours ${joursTrimestre.first.jourDeAnnee}–'
                  '${joursTrimestre.last.jourDeAnnee} · 91 jours · '
                  '13 semaines · $shabbatsTrimestre shabbats · '
                  '${fetesSaison.length} solennité${fetesSaison.length > 1 ? 's' : ''}'
              : annee.libelle,
          hauteur: 96,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blanc,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ardoisePastel),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _chevronNav(
                      Icons.chevron_left_rounded,
                      peutReculer
                          ? () => _changerTrimestre(annee, delta: -1)
                          : null,
                      'Saison précédente'),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Trimestre $_trimestreCourant/4 · $nom',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.bleuCielFonce,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          annee.libelle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.grisSecondaire,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _chevronNav(
                      Icons.chevron_right_rounded,
                      peutAvancer
                          ? () => _changerTrimestre(annee, delta: 1)
                          : null,
                      'Saison suivante'),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _boutonAujourdhui(() {
                  final j = annee.jourPourDate(etat.maintenant);
                  setState(() {
                    if (j != null) {
                      _trimestreCourant = j.trimestre;
                      _jourSelectionne = j;
                    }
                  });
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          descriptionsSaisons[_trimestreCourant] ?? '',
          style: const TextStyle(
            color: AppColors.ardoise,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        for (final mois in moisDuTrimestre) ...[
          TitreSection(
            'Mois $mois — ${annee.joursDuMois(mois).isNotEmpty ? annee.joursDuMois(mois).first.nomMois : ''}',
            icone: Icons.calendar_view_month_outlined,
            couleur: AppColors.bleuCiel,
          ),
          const SizedBox(height: 6),
          GrilleMois(
            joursMois: annee.joursDuMois(mois),
            fetesParJour: _fetesPourMois(annee, annee.joursDuMois(mois)),
            jourSelectionne: _jourSelectionne,
            onJourTape: (j) => setState(() => _jourSelectionne = j),
            modeHebreu: hebreu,
          ),
          const SizedBox(height: 12),
        ],
        if (_jourSelectionne != null)
          FicheJour(
            jour: _jourSelectionne!,
            annee: annee,
            fetes: fetesSelectionnees,
            modeHebreu: hebreu,
          ),
        const SizedBox(height: 14),
        TitreSection(
          'Fêtes de la saison de $nom',
          icone: Icons.celebration_outlined,
          couleur: AppColors.orSolaire,
        ),
        if (fetesSaison.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blanc.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.ardoisePastel.withValues(alpha: 0.7)),
            ),
            child: const Text(
              'Aucune convocation sainte cette saison — les shabbats '
              'hebdomadaires rythment seuls le temps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisSecondaire, fontSize: 12),
            ),
          )
        else
          for (final f in fetesSaison)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _carteFete(f, BiblicalCalendarEngine.joursRestants(f)),
            ),
      ],
    );
  }

  // ─── Vue 4 : vue mensuelle — design web (en-tête radial, grille, cartes,
  //     clic sur une date → fiche détaillée, légendes) ───────────────────

  Widget _vueMensuelle(AnneeBiblique annee, HorlogeState etat, bool hebreu) {
    final joursMois = annee.joursDuMois(_moisCourant);
    final nomMois = joursMois.isNotEmpty ? joursMois.first.nomMois : '';
    final saisonImage =
        ImageSaison.depuisTrimestre(((_moisCourant - 1) ~/ 3) + 1);
    final saison = ImageSaison.noms[saisonImage]!;
    final fetesParJour = _fetesPourMois(annee, joursMois);
    final jourDuJour = annee.jourPourDate(etat.maintenant);
    final jourSelectionneEffectif = _jourSelectionne;

    // La fête couvrant le jour sélectionné (durée > 1 jour comprise).
    final fetesSelectionnees = jourSelectionneEffectif != null
        ? fetesDuJour(annee, jourSelectionneEffectif)
        : const <FeteBiblique>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        // ── En-tête radial — miroir du CalendarHeader.tsx web ──
        EnTeteRadialCalendrier(
          annee: annee,
          mois: _moisCourant,
          jourDuJour: jourDuJour,
          sousTitreMois:
              'Saison de $saison · Shabbats dorés · Fêtes surlignées — '
              'touchez une date pour ouvrir sa fiche détaillée.',
          onMoisPrecedent:
              _moisCourant > 1 ? () => setState(() => _moisCourant--) : null,
          onMoisSuivant:
              _moisCourant < 12 ? () => setState(() => _moisCourant++) : null,
          onAnneePrecedente:
              _decalageAnnee > (BiblicalCalendarEngine.anneeMin - annee.annee)
                  ? () => setState(() => _decalageAnnee--)
                  : null,
          onAnneeSuivante:
              _decalageAnnee < (BiblicalCalendarEngine.anneeMax - annee.annee)
                  ? () => setState(() => _decalageAnnee++)
                  : null,
          onAujourdhui: () {
            final j = annee.jourPourDate(DateTime.now());
            setState(() {
              _decalageAnnee = 0;
              if (j != null) {
                _moisCourant = j.mois;
                _jourSelectionne = j;
              }
            });
          },
          onOuvrirFetes: () => ouvrirFetesEtSaisons(context, annee),
        ),
        const SizedBox(height: 12),

        // ── Sélecteur de mode de visualisation (grille / cartes) ──
        SegmentedButton<bool>(
          selected: {_modeCartes},
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.bleuCiel
                    : AppColors.blanc),
            foregroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.blanc
                    : AppColors.grisSecondaire),
            side: WidgetStateProperty.all(
                BorderSide(color: AppColors.bleuCiel.withValues(alpha: 0.4))),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.calendar_view_month_rounded, size: 16),
              label: Text('Grille'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.view_agenda_outlined, size: 16),
              label: Text('Cartes'),
            ),
          ],
          onSelectionChanged: (selection) =>
              setState(() => _modeCartes = selection.first),
        ),
        const SizedBox(height: 12),

        // ── Grille ou cartes — transition animée (vivacité du web) ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (enfant, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: enfant,
            ),
          ),
          child: _modeCartes
              ? Container(
                  key: ValueKey('cartes-$_moisCourant-$_decalageAnnee'),
                  child: CartesMois(
                    joursMois: joursMois,
                    fetesParJour: fetesParJour,
                    jourSelectionne: jourSelectionneEffectif,
                    onJourTape: (j) => setState(() => _jourSelectionne = j),
                    modeHebreu: hebreu,
                  ),
                )
              : Container(
                  key: ValueKey('grille-$_moisCourant-$_decalageAnnee'),
                  child: GrilleMois(
                    joursMois: joursMois,
                    fetesParJour: fetesParJour,
                    jourSelectionne: jourSelectionneEffectif,
                    onJourTape: (j) => setState(() => _jourSelectionne = j),
                    modeHebreu: hebreu,
                  ),
                ),
        ),
        const SizedBox(height: 14),

        // ── ZONE DE DÉTAIL — la fiche du jour cliqué (miroir DateInfo web) ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (enfant, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: enfant,
            ),
          ),
          child: jourSelectionneEffectif != null
              ? Container(
                  key: ValueKey(
                      'fiche-${jourSelectionneEffectif.jourDeAnnee}-${jourSelectionneEffectif.dateGregorienne.year}'),
                  child: FicheJour(
                    jour: jourSelectionneEffectif,
                    annee: annee,
                    fetes: fetesSelectionnees,
                    modeHebreu: hebreu,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),

        // ── LÉGENDE affichée APRÈS la zone de détail (miroir Legend web) ──
        const LegendeCalendrier(),
        const SizedBox(height: 14),

        // ── Fêtes du mois ──
        TitreSection(
          'Fêtes du mois de $nomMois',
          icone: Icons.celebration_outlined,
          couleur: AppColors.orSolaire,
        ),
        if (fetesParJour.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blanc.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.ardoisePastel.withValues(alpha: 0.7)),
            ),
            child: const Text(
              'Aucune convocation sainte ce mois — les shabbats hebdomadaires '
              'rythment seuls le temps de l\u2019alliance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grisSecondaire, fontSize: 12),
            ),
          )
        else
          for (final entree in fetesParJour.entries)
            for (final f in entree.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Builder(builder: (context) {
                  final joursRestants = BiblicalCalendarEngine.joursRestants(f);
                  return _carteFete(f, joursRestants);
                }),
              ),
      ],
    );
  }

  // ─── Vue 5 : vue annuelle — les 12 mois + les fêtes de l'Éternel ────

  Widget _vueAnnee(AnneeBiblique annee, HorlogeState etat) {
    final fetesTriees = [...annee.fetes]
      ..sort((a, b) => a.dateGregorienne.compareTo(b.dateGregorienne));
    final aujourdhui = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Frise de la saison en cours — embellissement de la vue annuelle
        // (image de saison sous voile, comme les cartes trimestres du web).
        FriseSaisonnier(
          saison: ImageSaison.approx(aujourdhui),
          titre:
              'Fêtes de l\u2019Éternel · ${ImageSaison.noms[ImageSaison.approx(aujourdhui)]}',
          sousTitre:
              'Saison en cours — ${annee.libelle} (${annee.nombreJours} jours)',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.bleuCiel),
              onPressed: _decalageAnnee >
                      (BiblicalCalendarEngine.anneeMin - annee.annee)
                  ? () => setState(() => _decalageAnnee--)
                  : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    annee.libelle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.bleuCielFonce,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${dateCourteFrancais(annee.debut).split(' ').skip(1).join(' ')} → '
                    '${dateCourteFrancais(annee.fin).split(' ').skip(1).join(' ')} · '
                    '${annee.nombreJours} jours',
                    style: const TextStyle(
                      color: AppColors.grisSecondaire,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.bleuCiel),
              onPressed: _decalageAnnee <
                      (BiblicalCalendarEngine.anneeMax - annee.annee)
                  ? () => setState(() => _decalageAnnee++)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TitreSection(
          'Vue annuelle — les 12 mois de ${annee.libelle}',
          icone: Icons.calendar_month_outlined,
          couleur: AppColors.bleuCiel,
        ),
        const SizedBox(height: 4),
        for (var paire = 0; paire < 12; paire += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _miniMois(annee, paire + 1)),
                const SizedBox(width: 8),
                Expanded(child: _miniMois(annee, paire + 2)),
              ],
            ),
          ),
        const SizedBox(height: 2),
        // Bouton d'ouverture du panneau complet « Fêtes & saisons ».
        Material(
          color: AppColors.bleuCiel.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ouvrirFetesEtSaisons(context, annee),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 15, color: AppColors.bleuCiel),
                  SizedBox(width: 7),
                  Text(
                    'Ouvrir « Fêtes & saisons » — le tour complet de l\u2019année',
                    style: TextStyle(
                      color: AppColors.bleuCiel,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final fete in fetesTriees)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _carteFete(
                fete,
                BiblicalCalendarEngine.joursRestants(fete,
                    maintenant: aujourdhui)),
          ),
      ],
    );
  }

  // ─── Mini-grilles de l'année — 12 mois compacts tapables ────────────

  static const _entetesMini = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

  Widget _miniMois(AnneeBiblique annee, int mois) {
    final jours = annee.joursDuMois(mois);
    if (jours.isEmpty) return const SizedBox.shrink();
    final decalage = jours.first.jourDeSemaine - 1;
    final fetesDuMois = _fetesPourMois(annee, jours);

    final cases = <Widget>[
      for (var i = 0; i < decalage; i++)
        const Expanded(child: SizedBox.shrink()),
      for (final j in jours)
        Expanded(
          child: _caseMiniJour(
              j, fetesDuMois[j.jourDuMois] ?? const <FeteBiblique>[]),
        ),
      for (var i = (decalage + jours.length) % 7; i > 0 && i < 7; i++)
        const Expanded(child: SizedBox.shrink()),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.blanc,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.ardoisePastel.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Text(
            '${jours.first.nomMois} · mois $mois',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.bleuCielFonce,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < _entetesMini.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _entetesMini[i],
                      style: TextStyle(
                        color: i == 6
                            ? AppColors.orFonce
                            : AppColors.grisSecondaire,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          for (var ligne = 0; ligne < cases.length; ligne += 7)
            Row(
              children: cases.skip(ligne).take(7).toList(growable: false),
            ),
        ],
      ),
    );
  }

  /// Une case compacte de la vue annuelle — tap → sélectionne le jour et
  /// bascule sur la vue mensuelle détaillée.
  Widget _caseMiniJour(JourBiblique j, List<FeteBiblique> fetes) {
    final g = j.dateGregorienne;
    final aujourdhui = DateTime.now();
    final estAujourdhui = g.year == aujourdhui.year &&
        g.month == aujourdhui.month &&
        g.day == aujourdhui.day;
    final aFete = fetes.isNotEmpty;
    final couleurFete = aFete ? AppColors.depuisHex(fetes.first.couleur) : null;
    final couleurFond = aFete
        ? couleurFete!.withValues(alpha: 0.16)
        : j.estShabbat
            ? AppColors.orSolaire.withValues(alpha: 0.14)
            : Colors.transparent;
    final couleurNumero = aFete
        ? couleurFete!
        : j.estShabbat
            ? AppColors.orFonce
            : AppColors.ardoise;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _jourSelectionne = j;
          _moisCourant = j.mois;
        });
        _onglets.animateTo(2);
      },
      child: Container(
        height: 26,
        margin: const EdgeInsets.all(0.8),
        decoration: BoxDecoration(
          color: couleurFond,
          borderRadius: BorderRadius.circular(6),
          border: estAujourdhui
              ? Border.all(color: AppColors.bleuCiel, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            '${j.jourDuMois}',
            style: TextStyle(
              color: couleurNumero,
              fontSize: 9.5,
              fontWeight:
                  aFete || j.estShabbat ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Aides ────────────────────────────────────────────────────────────

  /// Fêtes du mois indexées par jourDuMois — la DURÉE de chaque fête est
  /// parcourue (une fête de 7 jours surligne ses 7 jours, comme la page web).
  Map<int, List<FeteBiblique>> _fetesPourMois(
      AnneeBiblique annee, List<JourBiblique> joursMois) {
    final longueurMois = joursMois.length;
    // Le mois est dérivé des jours passés — la même aide sert à la vue
    // mensuelle ET aux grilles de la vue trimestrielle.
    final mois = joursMois.isNotEmpty ? joursMois.first.mois : _moisCourant;
    final map = <int, List<FeteBiblique>>{};
    for (final fete in annee.fetes) {
      final debut = annee.jourPourDate(fete.dateGregorienne);
      if (debut == null || debut.mois != mois) continue;
      for (var k = 0; k < fete.dureeJours; k++) {
        final jourCible = debut.jourDuMois + k;
        if (jourCible > longueurMois) break;
        map.putIfAbsent(jourCible, () => <FeteBiblique>[]).add(fete);
      }
    }
    return map;
  }

  /// Les fêtes couvrant un jour donné (n'importe quel mois) — la durée de
  /// chaque fête est incluse, comme le faisait le « getHolidaysForDate » web.
  List<FeteBiblique> fetesDuJour(AnneeBiblique annee, JourBiblique jour) {
    final resultat = <FeteBiblique>[];
    for (final fete in annee.fetes) {
      final debut = annee.jourPourDate(fete.dateGregorienne);
      if (debut == null || debut.mois != jour.mois) continue;
      final dernierJour = debut.jourDuMois + fete.dureeJours - 1;
      if (jour.jourDuMois >= debut.jourDuMois &&
          jour.jourDuMois <= dernierJour) {
        resultat.add(fete);
      }
    }
    return resultat;
  }
}
