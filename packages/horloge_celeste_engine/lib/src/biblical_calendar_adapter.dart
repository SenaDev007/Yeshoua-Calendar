/// ⭐ BIBLICAL CALENDAR ADAPTER — PHASE 5 du cahier des charges (§7, §14).
///
/// Synchronisation entre le moteur de temps biblique et le calendrier de
/// 364 jours EXISTANT (règles du backend conservées intégralement) :
///
///   • le jour biblique commence au COUCHER DU SOLEIL RÉEL local —
///     jamais à minuit, jamais à 18 h 00 fixes (§2.3, §18) ;
///   • la transition est protégée contre les DOUBLES INCRÉMENTATIONS par
///     une clé de transition (année-jour) persistée localement (§14) ;
///   • à la reprise de l'application, l'état est recalculé depuis l'heure
///     réelle et l'astronomie — jamais depuis les anciens états (§13).
library;

import 'biblical_calendar_engine.dart';
import 'models.dart';
import 'solar_engine.dart';
import 'time_engine.dart';

class BiblicalCalendarAdapter {
  BiblicalCalendarAdapter({
    required this.latitude,
    required this.longitude,
    this.cleDerniereTransition,
  });

  /// Position utilisée pour les couchers de soleil (§9).
  final double latitude;
  final double longitude;

  /// Clé de la dernière transition traitée (persistée par l'app — §13/§14).
  final String? cleDerniereTransition;

  /// Le jour biblique en cours à [maintenant].
  ///
  /// Convention (identique aux événements du backend) : le jour biblique
  /// correspondant au jour civil [D] commence au coucher du soleil de
  /// [D−1] et finit au coucher du soleil de [D]. Après le coucher de [D],
  /// c'est le jour biblique de [D+1] qui est en cours.
  ///
  /// Pour une date civile [date] évaluée PENDANT son jour (après lever,
  /// avant coucher), la réponse est le jour du calendrier mappé sur
  /// [date] ; évaluée le SOIR (après coucher), celui de [date + 1].
  JourBiblique? jourBibliqueActuel(DateTime maintenant) {
    final solar = SolarEngine.calculer(maintenant, latitude, longitude);
    if (!solar.calculable) {
      // Région polaire : repli sur la date civile (convention d'affichage)
      // — l'indisponibilité du cycle solaire reste signalée ailleurs.
      return BiblicalCalendarEngine.anneePourDate(maintenant)
          .jourPourDate(maintenant);
    }
    final coucher = solar.coucher!;
    final apresCoucher = maintenant.isAfter(coucher);
    final dateCivileJourBiblique = apresCoucher
        ? maintenant.add(const Duration(days: 1))
        : maintenant;
    final annee = BiblicalCalendarEngine.anneePourDate(dateCivileJourBiblique);
    return annee.jourPourDate(dateCivileJourBiblique);
  }

  /// Évalue si une transition de jour biblique est due à [maintenant]
  /// (§14 — les 7 étapes). [cleTraitee] est la dernière clé de transition
  /// persistée par l'app.
  ResultatTransition evaluerTransition({
    required DateTime maintenant,
    String? cleTraitee,
  }) {
    final solar = SolarEngine.calculer(maintenant, latitude, longitude);
    if (!solar.calculable) {
      return const ResultatTransition(transitionDue: false);
    }
    final coucher = solar.coucher!;
    if (maintenant.isBefore(coucher)) {
      return ResultatTransition(transitionDue: false);
    }
    final dateNouveauJour = maintenant.add(const Duration(days: 1));
    final annee = BiblicalCalendarEngine.anneePourDate(dateNouveauJour);
    final nouveauJour = annee.jourPourDate(dateNouveauJour);
    if (nouveauJour == null) {
      return const ResultatTransition(transitionDue: false);
    }
    final cle = '${annee.annee}-${nouveauJour.jourDeAnnee}';
    // Protection anti-double : transition déjà traitée pour ce jour ?
    final dejaTraitee = cleTraitee == cle ||
        (cleDerniereTransition != null && cleDerniereTransition == cle);
    return ResultatTransition(
      transitionDue: !dejaTraitee,
      coucherDeclencheur: coucher,
      nouveauJour: nouveauJour,
      cleTransition: cle,
    );
  }

  /// Prochain coucher du soleil après [maintenant] (local).
  DateTime? prochainCoucher(DateTime maintenant) {
    final solar = SolarEngine.calculer(maintenant, latitude, longitude);
    if (solar.calculable && maintenant.isBefore(solar.coucher!)) {
      return solar.coucher;
    }
    final demain = SolarEngine.calculer(
        maintenant.add(const Duration(days: 1)), latitude, longitude);
    return demain.calculable ? demain.coucher : null;
  }

  /// Prochain lever du soleil après [maintenant] (local).
  DateTime? prochainLever(DateTime maintenant) {
    final solar = SolarEngine.calculer(maintenant, latitude, longitude);
    if (solar.calculable && maintenant.isBefore(solar.lever!)) {
      return solar.lever;
    }
    final demain = SolarEngine.calculer(
        maintenant.add(const Duration(days: 1)), latitude, longitude);
    return demain.calculable ? demain.lever : null;
  }

  /// Instantané d'état persistable (§13).
  EtatTemporel etatTemporel(DateTime maintenant, {String? fuseau}) {
    final jour = jourBibliqueActuel(maintenant);
    return EtatTemporel(
      horodatage: maintenant,
      fuseau: fuseau ?? TimeEngine.fuseauCourant(),
      dernierCoucherCalcule:
          SolarEngine.calculer(maintenant, latitude, longitude).coucher,
      prochainCoucherCalcule: prochainCoucher(maintenant),
      cleDerniereTransition: cleDerniereTransition,
      anneeBibliqueEnCours:
          BiblicalCalendarEngine.anneePourDate(maintenant).annee,
      jourDeAnneeEnCours: jour?.jourDeAnnee ?? 0,
    );
  }
}
