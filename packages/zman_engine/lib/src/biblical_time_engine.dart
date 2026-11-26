/// ⭐ BIBLICAL TIME ENGINE — PHASE 4 du cahier des charges ZMAN.
///
/// Calcul du temps biblique à partir des horaires solaires RÉELS :
///   • TROIS VEILLES de la nuit (Exode 14:24, Juges 7:19, 1 Samuel 11:11)
///     — la nuit est divisée en trois TIERS ÉGAUX de sa durée réelle
///     (coucher → lever suivant). JAMAIS de tranches fixes de 4 h (§18) ;
///   • DOUZE HEURES SAISONNIÈRES du jour — (coucher − lever) / 12,
///     donc PAS des heures civiles de 60 minutes (Jean 11:9) ;
///   • QUATRE PARTIES DU JOUR — convention d'affichage de l'app (§4.3),
///     regroupant 3 heures saisonnières chacune ;
///   • détermination de la période en cours avec statut et progression.
library;

import 'models.dart';

class BiblicalTimeEngine {
  BiblicalTimeEngine._();

  /// Références scripturaires des veilles — affichées dans l'app.
  static const List<String> referencesVeilles = [
    'Exode 14:24 · Juges 7:19',
    'Juges 7:19 · 1 Samuel 11:11',
    'Matthieu 14:25 · Marc 13:35',
  ];

  static const List<String> nomsVeilles = [
    'PREMIÈRE VEILLE',
    'DEUXIÈME VEILLE',
    'TROISIÈME VEILLE',
  ];

  static const List<String> sousTitresVeilles = [
    'Veille du commencement de la nuit',
    'Veille du milieu de la nuit',
    'Veille du matin',
  ];

  /// Repères horaires scripturaires traditionnels (§4.3).
  static const Map<int, String> reperesScripturaires = {
    3: 'Troisième heure — Marc 15:25',
    6: 'Sixième heure — Jean 4:6',
    9: 'Neuvième heure — Actes 3:1',
    11: 'Onzième heure — Matthieu 20:6',
  };

  static const List<String> designationsParties = [
    'Matin',
    'Approche du milieu du jour',
    'Après-midi',
    'Fin du jour',
  ];

  // ── TROIS VEILLES DE LA NUIT ────────────────────────────────────────

  /// Les trois veilles de la nuit comprise entre [coucher] et [lever].
  ///
  /// Durée d'une veille = durée totale de la nuit / 3 (§3.4) — calculée
  /// chaque jour, jamais fixe.
  static List<VeilleModel> veillesDeLaNuit({
    required DateTime coucher,
    required DateTime lever,
    required DateTime maintenant,
  }) {
    final dureeNuit = lever.difference(coucher);
    if (dureeNuit <= Duration.zero) return const [];
    final dureeVeille = _diviser(dureeNuit, 3.0);

    final resultats = <VeilleModel>[];
    for (var i = 0; i < 3; i++) {
      final debut = coucher.add(_multiplier(dureeVeille, i.toDouble()));
      final fin = coucher.add(_multiplier(dureeVeille, (i + 1).toDouble()));
      final statut = _statut(debut, fin, maintenant);
      resultats.add(VeilleModel(
        indice: IndiceVeille.values[i],
        nom: nomsVeilles[i],
        sousTitre: sousTitresVeilles[i],
        debut: debut,
        fin: fin,
        duree: dureeVeille,
        statut: statut,
        progression: _progression(debut, fin, maintenant),
      ));
    }
    return resultats;
  }

  /// Veille en cours à [maintenant] (null si jour ou calcul impossible).
  static VeilleModel? veilleEnCours({
    required SolarTimes jour,
    required SolarTimes jourSuivant,
    required SolarTimes jourPrecedent,
    required DateTime maintenant,
  }) {
    // La nuit se poursuit jusqu'au lever du jour suivant.
    if (jour.coucher != null &&
        jourSuivant.lever != null &&
        !maintenant.isBefore(jour.coucher!)) {
      final veilles = veillesDeLaNuit(
        coucher: jour.coucher!,
        lever: jourSuivant.lever!,
        maintenant: maintenant,
      );
      return veilles.isEmpty ? null : veilles.firstWhere(
        (v) => v.statut == StatutPeriode.enCours,
        orElse: () => veilles.last,
      );
    }
    // Avant le lever : la nuit entamée la veille continue.
    if (jourPrecedent.coucher != null &&
        jour.lever != null &&
        maintenant.isBefore(jour.lever!)) {
      final veilles = veillesDeLaNuit(
        coucher: jourPrecedent.coucher!,
        lever: jour.lever!,
        maintenant: maintenant,
      );
      return veilles.isEmpty ? null : veilles.firstWhere(
        (v) => v.statut == StatutPeriode.enCours,
        orElse: () => veilles.last,
      );
    }
    return null;
  }

  // ── DOUZE HEURES SAISONNIÈRES ───────────────────────────────────────

  /// Les douze heures saisonnières du jour entre [lever] et [coucher].
  ///
  /// Durée d'une heure saisonnière = durée totale du jour / 12 (§4.1).
  static List<HeureSaisonniereModel> heuresSaisonniere({
    required DateTime lever,
    required DateTime coucher,
    required DateTime maintenant,
  }) {
    final dureeJour = coucher.difference(lever);
    if (dureeJour <= Duration.zero) return const [];
    final dureeHeure = _diviser(dureeJour, 12.0);

    final resultats = <HeureSaisonniereModel>[];
    for (var i = 0; i < 12; i++) {
      final debut = lever.add(_multiplier(dureeHeure, i.toDouble()));
      final fin = lever.add(_multiplier(dureeHeure, (i + 1).toDouble()));
      final numero = i + 1;
      resultats.add(HeureSaisonniereModel(
        numero: numero,
        debut: debut,
        fin: fin,
        duree: dureeHeure,
        statut: _statut(debut, fin, maintenant),
        progression: _progression(debut, fin, maintenant),
        partie: ((i ~/ 3) + 1),
        repereScripturaire: reperesScripturaires[numero],
      ));
    }
    return resultats;
  }

  // ── QUATRE PARTIES DU JOUR ──────────────────────────────────────────

  /// Les quatre parties du jour (3 heures saisonnières chacune, §4.3).
  static List<PartieJourModel> partiesDuJour({
    required DateTime lever,
    required DateTime coucher,
    required DateTime maintenant,
  }) {
    final dureeJour = coucher.difference(lever);
    if (dureeJour <= Duration.zero) return const [];
    final dureePartie = _diviser(dureeJour, 4.0);

    final resultats = <PartieJourModel>[];
    for (var i = 0; i < 4; i++) {
      final debut = lever.add(_multiplier(dureePartie, i.toDouble()));
      final fin = lever.add(_multiplier(dureePartie, (i + 1).toDouble()));
      resultats.add(PartieJourModel(
        indice: IndicePartie.values[i],
        de: i * 3 + 1,
        a: i * 3 + 3,
        designation: designationsParties[i],
        statut: _statut(debut, fin, maintenant),
        progression: _progression(debut, fin, maintenant),
      ));
    }
    return resultats;
  }

  // ── PÉRIODE ACTUELLE ────────────────────────────────────────────────

  /// Détermine la période en cours à [maintenant] :
  ///   • nuit → [NuitEnCours] avec la veille active ;
  ///   • jour → [JourEnCours] avec l'heure saisonnière active ;
  ///   • calcul impossible → [PeriodeIndisponible] (jamais d'invention).
  static PeriodeActuelle periodeActuelle({
    required SolarTimes jour,
    required SolarTimes jourSuivant,
    required SolarTimes jourPrecedent,
    required DateTime maintenant,
  }) {
    if (!jour.calculable) {
      return PeriodeIndisponible(
        'Calcul solaire impossible à cette latitude (région polaire). '
        'Configurez manuellement vos horaires dans les paramètres.',
      );
    }

    final veille = veilleEnCours(
      jour: jour,
      jourSuivant: jourSuivant,
      jourPrecedent: jourPrecedent,
      maintenant: maintenant,
    );

    if (veille != null) {
      final leverSuivant =
          !maintenant.isBefore(jour.lever!) ? jourSuivant.lever! : jour.lever!;
      return NuitEnCours(
        veille: veille,
        veilles: veillesDeLaNuit(
          coucher: maintenant.isBefore(jour.coucher!)
              ? jourPrecedent.coucher!
              : jour.coucher!,
          lever: leverSuivant,
          maintenant: maintenant,
        ),
        prochainLever: leverSuivant,
      );
    }

    // Jour : entre lever et coucher.
    final heures = heuresSaisonniere(
      lever: jour.lever!,
      coucher: jour.coucher!,
      maintenant: maintenant,
    );
    final parties = partiesDuJour(
      lever: jour.lever!,
      coucher: jour.coucher!,
      maintenant: maintenant,
    );
    final enCours = heures.firstWhere(
      (h) => h.statut == StatutPeriode.enCours,
      orElse: () => heures.first,
    );
    return JourEnCours(
      heure: enCours,
      heures: heures,
      parties: parties,
      prochainCoucher: jour.coucher!,
    );
  }

  // ── CYCLE COMPLET (§5) ──────────────────────────────────────────────

  /// Les 10 jalons du cycle complet de la journée biblique, dans l'ordre
  /// chronologique : coucher → 3 veilles → lever → 4 parties → coucher
  /// suivant. [lever] est le lever qui SUIT [coucher] ; [coucherSuivant]
  /// est le coucher qui clôt le jour (fourni par le SolarEngine).
  static List<JalonCycle> cycleComplet({
    required DateTime coucher,
    required DateTime lever,
    required DateTime coucherSuivant,
  }) {
    final dureeNuit = lever.difference(coucher);
    final dureeJour = coucherSuivant.difference(lever);
    final dv = _diviser(dureeNuit, 3.0);
    final dp = _diviser(dureeJour, 4.0);
    return [
      JalonCycle(0, 'Coucher du soleil', 'Commencement du nouveau jour biblique', coucher),
      JalonCycle(1, nomsVeilles[0], sousTitresVeilles[0], coucher),
      JalonCycle(2, nomsVeilles[1], sousTitresVeilles[1], coucher.add(dv)),
      JalonCycle(3, nomsVeilles[2], sousTitresVeilles[2], coucher.add(_multiplier(dv, 2))),
      JalonCycle(4, 'Lever du soleil', 'Commencement du jour', lever),
      JalonCycle(5, 'Première partie du jour', 'Heures 1 à 3 — ${designationsParties[0]}', lever),
      JalonCycle(6, 'Deuxième partie du jour', 'Heures 4 à 6 — ${designationsParties[1]}', lever.add(dp)),
      JalonCycle(7, 'Troisième partie du jour', 'Heures 7 à 9 — ${designationsParties[2]}', lever.add(_multiplier(dp, 2))),
      JalonCycle(8, 'Quatrième partie du jour', 'Heures 10 à 12 — ${designationsParties[3]}', lever.add(_multiplier(dp, 3))),
      JalonCycle(9, 'Coucher du soleil', 'Fin du jour biblique et commencement du suivant', coucherSuivant),
    ];
  }

  // ── AIDES ───────────────────────────────────────────────────────────

  static StatutPeriode _statut(DateTime debut, DateTime fin, DateTime maintenant) {
    if (maintenant.isBefore(debut)) return StatutPeriode.aVenir;
    if (maintenant.isAfter(fin)) return StatutPeriode.terminee;
    return StatutPeriode.enCours;
  }

  static double _progression(DateTime debut, DateTime fin, DateTime maintenant) {
    if (maintenant.isBefore(debut)) return 0.0;
    if (maintenant.isAfter(fin)) return 1.0;
    final total = fin.difference(debut).inMilliseconds;
    if (total <= 0) return 1.0;
    final ecoule =
        maintenant.difference(debut).inMilliseconds.toDouble();
    return (ecoule / total).clamp(0.0, 1.0);
  }

  /// Division d'une durée par un facteur réel (microseconde près).
  static Duration _diviser(Duration d, double diviseur) =>
      Duration(microseconds: (d.inMicroseconds / diviseur).round());

  /// Multiplication d'une durée par un facteur réel (microseconde près).
  static Duration _multiplier(Duration d, double facteur) =>
      Duration(microseconds: (d.inMicroseconds * facteur).round());
}

/// Un jalon du cycle complet de la journée biblique (§5).
class JalonCycle {
  final int ordre;
  final String nom;
  final String sousTitre;
  final DateTime debut;

  const JalonCycle(this.ordre, this.nom, this.sousTitre, this.debut);
}
