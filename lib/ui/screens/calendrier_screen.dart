/// ⭐ ÉCRAN CALENDRIER (§7) — REPRODUCTION FIDÈLE du calendrier biblique
/// de 364 jours déjà implémenté dans Yeshua Connect Mobile (vues
/// « Aujourd'hui », grille mensuelle 12 mois, fêtes de l'Éternel par
/// année), MAIS :
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
import '../widgets/carte_saisonniere.dart';
import '../widgets/cartes.dart';

class CalendrierScreen extends ConsumerStatefulWidget {
  const CalendrierScreen({super.key});

  @override
  ConsumerState<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends ConsumerState<CalendrierScreen> {
  int _moisCourant = 1;
  int _decalageAnnee = 0; // navigation ◀ ▶ entre années
  bool _moisInitialise = false;

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(horlogeProvider);
    final anneeReference = etat.anneeBiblique?.annee ??
        BiblicalCalendarEngine.anneePourDate(DateTime.now()).annee;
    final anneeChoisie = (anneeReference + _decalageAnnee)
        .clamp(BiblicalCalendarEngine.anneeMin, BiblicalCalendarEngine.anneeMax);
    final annee = BiblicalCalendarEngine.construireAnnee(anneeChoisie);

    // Mois courant = celui qui contient aujourd'hui (init une seule fois).
    if (!_moisInitialise) {
      _moisInitialise = true;
      final j = annee.jourPourDate(DateTime.now());
      _moisCourant = j?.mois ?? 1;
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppColors.bleuCiel,
            labelColor: AppColors.bleuCiel,
            unselectedLabelColor: AppColors.grisSecondaire,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(icon: Icon(Icons.today_outlined), text: 'Aujourd\u2019hui'),
              Tab(icon: Icon(Icons.calendar_view_month_outlined), text: 'Mois'),
              Tab(icon: Icon(Icons.calendar_today_outlined), text: 'Années'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _vueAujourdhui(etat, annee),
                _vueMensuelle(annee),
                _vueAnnees(annee, etat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vue 1 : aujourd'hui ────────────────────────────────────────────

  Widget _vueAujourdhui(HorlogeState etat, AnneeBiblique annee) {
    final jour = etat.jourBiblique ?? annee.jourPourDate(DateTime.now());
    final maintenant = etat.maintenant;
    // Fêtes à venir (joursRestants ≥ 0).
    final fetesAVenir = annee.fetes
        .map((f) => (fete: f, joursRestants: BiblicalCalendarEngine.joursRestants(f, maintenant: maintenant)))
        .where((x) => x.joursRestants >= 0)
        .toList()
      ..sort((a, b) => a.joursRestants.compareTo(b.joursRestants));
    final prochaineFete = fetesAVenir.isNotEmpty ? fetesAVenir.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (jour != null) ...[
          _carteJourBiblique(jour, maintenant, etat),
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
        for (final x in fetesAVenir.skip(1)) _carteFete(x.fete, x.joursRestants),
      ],
    );
  }

  Widget _carteJourBiblique(JourBiblique j, DateTime maintenant, HorlogeState etat) {
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final estJourCourant = j.dateGregorienne == aujourdhui;
    final saisonImage = ImageSaison.depuisTrimestre(j.trimestre);
    final saison = ImageSaison.noms[saisonImage]!;

    // Carte principale avec IMAGE DE SAISON sous voile — même
    // embellissement que la carte « jour en cours » de la page web.
    return BandeauSaisonnier(
      saison: saisonImage,
      child: Column(
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
            '${j.nomJourSemaine} · Jour ${j.jourDeAnnee} de l\u2019année ${etat.anneeBiblique?.libelle ?? ''}',
            style: TextStyle(color: AppColors.blanc.withValues(alpha: 0.82), fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.orVif),
              const SizedBox(width: 6),
              Text(
                dateLongueFrancais(j.dateGregorienne),
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
                border: Border.all(color: AppColors.orSolaire.withValues(alpha: 0.6)),
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
            style: const TextStyle(color: AppColors.grisSecondaire, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          BoitesCompteARebours(
            duree: etat.compteAReboursCoucher,
            accent: AppColors.orSolaire,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 12, color: AppColors.orSolaire),
              const SizedBox(width: 5),
              Text(
                'Prochain coucher : ${etat.prochainCoucher != null ? heureCivilFormat(etat.prochainCoucher!) : '—'} (heure locale)',
                style: TextStyle(
                  color: AppColors.grisSecondaire.withValues(alpha: 0.9),
                  fontSize: 11.5,
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
          Text(
            'PROCHAINE FÊTE',
            style: TextStyle(
              color: couleur.withValues(alpha: 1.0),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fete.nomFr,
            style: const TextStyle(
              color: AppColors.ardoise,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          if (fete.nomHebrew != null && fete.nomHebrew!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                fete.nomHebrew!,
                style: const TextStyle(color: AppColors.ardoise, fontSize: 13),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            joursRestants == 0 ? 'Aujourd\u2019hui !' : 'Dans $joursRestants ${joursRestants == 1 ? 'jour' : 'jours'}',
            style: const TextStyle(
              color: AppColors.ardoise,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${fete.dateBiblique} — ${dateLongueFrancais(fete.dateGregorienne)}',
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
                  '${fete.dateBiblique} — ${dateLongueFrancais(fete.dateGregorienne)}'
                  '${fete.dureeJours > 1 ? ' · ${fete.dureeJours} jours' : ''}',
                  style: const TextStyle(color: AppColors.grisSecondaire, fontSize: 12.5),
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

  // ─── Vue 2 : grille du mois biblique (miroir du calendrier existant) ──

  Widget _vueMensuelle(AnneeBiblique annee) {
    final joursMois = annee.joursDuMois(_moisCourant);
    final nomMois = joursMois.isNotEmpty ? joursMois.first.nomMois : '';

    // Fêtes du mois (dateBiblique « 14 Aviv » → jour + mois).
    final feteParJour = <int, FeteBiblique>{};
    for (final fete in annee.fetes) {
      final parts = fete.dateBiblique.split(' ');
      if (parts.length < 2) continue;
      final numero = int.tryParse(parts[0]);
      final nom = parts.sublist(1).join(' ').trim();
      if (numero != null && nom == nomMois) feteParJour[numero] = fete;
    }

    final aujourdhui = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Frise saisonnière — embellissement identique à la vue mensuelle
        // de la page web (image de saison sous voile dégradé).
        FriseSaisonnier(
          saison: ImageSaison.depuisTrimestre(((_moisCourant - 1) ~/ 3) + 1),
          titre: 'Mois $_moisCourant · ${ImageSaison.noms[ImageSaison.depuisTrimestre(((_moisCourant - 1) ~/ 3) + 1)]}',
          sousTitre: 'Grille du mois biblique — Shabbats dorés, fêtes surlignées',
        ),
        const SizedBox(height: 10),
        // En-tête mois ◀ ▶
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.bleuCiel),
              onPressed: _moisCourant > 1
                  ? () => setState(() => _moisCourant--)
                  : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    nomMois,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.bleuCielFonce,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    'Mois $_moisCourant · ${joursMois.length} jours · ${annee.libelle}',
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
              onPressed: _moisCourant < 12
                  ? () => setState(() => _moisCourant++)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // En-tête des 7 jours de la semaine biblique.
        const Row(
          children: [
            for (final j in ['J1', 'J2', 'J3', 'J4', 'J5', 'J6', 'Shabbat'])
              Expanded(
                child: Center(
                  child: Text(
                    j,
                    style: TextStyle(
                      color: AppColors.grisSecondaire,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Grille.
        Container(
          decoration: BoxDecoration(
            color: AppColors.blanc,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ardoisePastel),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            border: TableBorder.all(
              color: AppColors.ardoisePastel.withValues(alpha: 0.7),
              width: 0.7,
            ),
            children: [
              for (var ligne = 0; ligne < (joursMois.length / 7).ceil(); ligne++)
                TableRow(
                  children: [
                    for (var col = 0; col < 7; col++)
                      _celluleJour(
                        joursMois: joursMois,
                        index: ligne * 7 + col,
                        feteParJour: feteParJour,
                        aujourdhui: aujourdhui,
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Fêtes du mois.
        if (feteParJour.isNotEmpty) ...[
          TitreSection(
            'Fêtes du mois',
            icone: Icons.celebration_outlined,
            couleur: AppColors.orSolaire,
          ),
          for (final f in feteParJour.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(builder: (context) {
                final joursRestants = BiblicalCalendarEngine.joursRestants(f);
                return _carteFete(f, joursRestants);
              }),
            ),
        ],
      ],
    );
  }

  Widget _celluleJour({
    required List<JourBiblique> joursMois,
    required int index,
    required Map<int, FeteBiblique> feteParJour,
    required DateTime aujourdhui,
  }) {
    if (index >= joursMois.length) {
      return const SizedBox(height: 56);
    }
    final j = joursMois[index];
    final fete = feteParJour[j.jourDuMois];
    final estAujourdhui = j.dateGregorienne.year == aujourdhui.year &&
        j.dateGregorienne.month == aujourdhui.month &&
        j.dateGregorienne.day == aujourdhui.day;

    Color? fond;
    Color texte = AppColors.ardoise;
    if (j.estShabbat) {
      fond = AppColors.orSolaire.withValues(alpha: 0.14);
      texte = AppColors.orFonce;
    }
    if (fete != null) {
      fond = AppColors.depuisHex(fete.couleur).withValues(alpha: 0.22);
    }

    return TableCell(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: fond,
          border: estAujourdhui
              ? Border.all(color: AppColors.bleuCiel, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${j.jourDuMois}',
              style: TextStyle(
                color: texte,
                fontSize: 14,
                fontWeight: j.estShabbat || fete != null
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${j.dateGregorienne.day}/${j.dateGregorienne.month}',
              style: TextStyle(
                color: AppColors.grisSecondaire.withValues(alpha: 0.75),
                fontSize: 8.5,
              ),
            ),
            if (fete != null)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: AppColors.depuisHex(fete.couleur),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Vue 3 : fêtes de l'Éternel par année ────────────────────────────

  Widget _vueAnnees(AnneeBiblique annee, HorlogeState etat) {
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
          titre: 'Fêtes de l\u2019Éternel · ${ImageSaison.noms[ImageSaison.approx(aujourdhui)]}',
          sousTitre: 'Saison en cours — ${annee.libelle} (${annee.nombreJours} jours)',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.bleuCiel),
              onPressed: _decalageAnnee > (BiblicalCalendarEngine.anneeMin - annee.annee)
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
                    '${dateLongueFrancais(annee.debut).split(' ').skip(1).join(' ')} → '
                    '${dateLongueFrancais(annee.fin).split(' ').skip(1).join(' ')} · '
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
              onPressed: _decalageAnnee < (BiblicalCalendarEngine.anneeMax - annee.annee)
                  ? () => setState(() => _decalageAnnee++)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final fete in fetesTriees)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _carteFete(
                fete, BiblicalCalendarEngine.joursRestants(fete, maintenant: aujourdhui)),
          ),
      ],
    );
  }
}
