/// ⭐ ÉCRAN ACCUEIL (§11) — tout ce qui compte en quelques secondes :
///   • nom Horloge Céleste, date biblique, heure civile ;
///   • horloge + indicateur du nouveau jour + compte à rebours du coucher ;
///   • soleil : lever / coucher / durées ;
///   • période en cours (veille ou heure saisonnière) ;
///   • prochain rendez-vous spirituel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import '../../state/alarms_controller.dart';
import '../../state/horloge_controller.dart';
import '../widgets/carte_saisonniere.dart';
import '../widgets/cartes.dart';
import 'parametres_screen.dart';

class AccueilScreen extends ConsumerWidget {
  const AccueilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(horlogeProvider);
    final alarms = ref.watch(alarmsProvider);
    final periode = etat.periode;
    final jour = etat.jourBiblique;

    final enNuit = periode is NuitEnCours;
    final enJour = periode is JourEnCours;
    final indisponible = periode is PeriodeIndisponible;

    // Prochain rendez-vous spirituel = première alarme planifiée à venir.
    AlarmeAffichee? prochainRendezVous;
    DateTime? instantLePlusProche;
    for (final a in alarms.alarmes) {
      if (a.prefs.activee && a.prochainInstant != null) {
        if (instantLePlusProche == null ||
            a.prochainInstant!.isBefore(instantLePlusProche)) {
          instantLePlusProche = a.prochainInstant;
          prochainRendezVous = a;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ── Date biblique + heure civile, habillées de l'image de saison
        //    (même principe d'embellissement que la page web
        //    /calendrier-biblique : image sous voile dégradé) ──
        BandeauSaisonnier(
          saison: jour != null
              ? ImageSaison.depuisTrimestre(jour.trimestre)
              : ImageSaison.approx(etat.maintenant),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.orVif),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      jour != null
                          ? (enNuit
                              ? 'NOUVEAU JOUR BIBLIQUE · ${ImageSaison.noms[ImageSaison.depuisTrimestre(jour.trimestre)]}'
                              : 'JOUR BIBLIQUE EN COURS · ${ImageSaison.noms[ImageSaison.depuisTrimestre(jour.trimestre)]}')
                          : 'DATE BIBLIQUE',
                      style: const TextStyle(
                        color: AppColors.orVif,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Position et localisation',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.place_outlined,
                        size: 18, color: AppColors.orVif),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ParametresScreen()),
                    ),
                  ),
                ],
              ),
              Text(
                jour != null
                    ? '${jour.jourDuMois} ${jour.nomMois} — ${jour.nomJourSemaine}'
                    : '—',
                style: const TextStyle(
                  color: AppColors.blanc,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                [
                  if (jour != null) 'Jour ${jour.jourDeAnnee} de l\u2019année ${etat.anneeBiblique?.libelle ?? ''}',
                  if (jour != null)
                    'Trimestre ${jour.trimestre} · ${BiblicalSaisons.saison(jour.trimestre)}',
                  'Année de 364 jours — 52 Shabbats',
                ].join(' · '),
                style: TextStyle(
                  color: AppColors.blanc.withValues(alpha: 0.80),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.watch_later_outlined,
                      size: 15, color: AppColors.blanc.withValues(alpha: 0.75)),
                  const SizedBox(width: 6),
                  Text(
                    'Heure civile ${heureSecondeFormat(etat.maintenant)}',
                    style: TextStyle(
                      color: AppColors.blanc.withValues(alpha: 0.88),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Période en cours ──
        if (indisponible)
          CarteCeleste(
            bordure: AppColors.orSolaire.withValues(alpha: 0.5),
            enfant: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.orFonce),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (periode as PeriodeIndisponible).motif,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ardoise),
                  ),
                ),
              ],
            ),
          )
        else if (enNuit)
          CartePeriodeActive(
            nuit: true,
            nom: (periode as NuitEnCours).veille.nom,
            sousTitre: (periode).veille.sousTitre,
            horodatageCourant: etat.maintenant,
            progression: (periode).veille.progression,
            complement:
                'Jusqu\u2019à ${heureCivilFormat((periode).veille.fin)}',
          )
        else if (enJour)
          CartePeriodeActive(
            nuit: false,
            nom: '${_ordinalHeure((periode as JourEnCours).heure.numero)} heure saisonnière',
            sousTitre:
                '${(periode).parties[_partieActive((periode).parties)].designation} · heures ${(periode).parties[_partieActive((periode).parties)].de}–${(periode).parties[_partieActive((periode).parties)].a}',
            horodatageCourant: etat.maintenant,
            progression: (periode).heure.progression,
            complement:
                'Jusqu\u2019à ${heureCivilFormat((periode).heure.fin)}',
          ),
        const SizedBox(height: 12),

        // ── Compte à rebours vers le prochain coucher ──
        if (!etat.calculSolaireIndisponible)
          CarteCeleste(
            bordure: AppColors.orSolaire.withValues(alpha: 0.45),
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timelapse, size: 17, color: AppColors.orSolaire),
                    const SizedBox(width: 8),
                    const Text(
                      'Prochain changement de jour',
                      style: TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Coucher du soleil à ${etat.prochainCoucher != null ? heureCivilFormat(etat.prochainCoucher!) : '—'} '
                  '— le nouveau jour biblique commence',
                  style: const TextStyle(
                    color: AppColors.grisSecondaire,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 12),
                BoitesCompteARebours(
                  duree: etat.compteAReboursCoucher,
                  accent: AppColors.orSolaire,
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // ── Soleil ──
        CarteSoleil(
          lever: etat.solarJour?.lever,
          coucher: etat.solarJour?.coucher,
          dureeJour: etat.solarJour?.dureeJourMinutes == null
              ? '—'
              : dureeLisible(
                  Duration(minutes: etat.solarJour!.dureeJourMinutes!.round())),
          dureeNuit: etat.solarJour == null ||
                  etat.solarSuivant == null ||
                  !etat.solarJour!.calculable ||
                  !etat.solarSuivant!.calculable
              ? '—'
              : dureeLisible(Duration(
                  minutes: etat.solarJour!
                      .dureeNuitMinutes(etat.solarSuivant!)!
                      .round())),
          disponible: etat.solarJour?.calculable ?? false,
        ),
        const SizedBox(height: 12),

        // ── Prochain rendez-vous spirituel ──
        if (prochainRendezVous != null && instantLePlusProche != null)
          CarteCeleste(
            enfant: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orSolaire.withValues(alpha: 0.13),
                    border: Border.all(
                        color: AppColors.orSolaire.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.orSolaire, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PROCHAIN RENDEZ-VOUS SPIRITUEL',
                        style: TextStyle(
                          color: AppColors.orFonce,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        prochainRendezVous.nom,
                        style: const TextStyle(
                          color: AppColors.ardoise,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        'à ${heureCivilFormat(instantLePlusProche)} — '
                        'dans ${dureeFormat(instantLePlusProche.difference(etat.maintenant))}',
                        style: const TextStyle(
                          color: AppColors.grisSecondaire,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _partieActive(List<PartieJourModel> parties) {
    for (var i = 0; i < parties.length; i++) {
      if (parties[i].statut == StatutPeriode.enCours) return i;
    }
    return 0;
  }

  String _ordinalHeure(int n) =>
      const ['', 'Première', 'Deuxième', 'Troisième', 'Quatrième', 'Cinquième',
        'Sixième', 'Septième', 'Huitième', 'Neuvième', 'Dixième',
        'Onzième', 'Douzième'][n];
}

/// Noms des saisons bibliques (trimestres).
class BiblicalSaisons {
  BiblicalSaisons._();
  static String saison(int trimestre) =>
      const ['Printemps', 'Été', 'Automne', 'Hiver'][(trimestre - 1).clamp(0, 3)];
}
