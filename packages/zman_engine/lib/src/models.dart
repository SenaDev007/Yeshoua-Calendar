/// ⭐ Modèles de données du moteur ZMAN.
///
/// Les structures du calendrier 364 jours sont le MIROIR EXACT de la
/// sérialisation du backend « Mouvement Christ Libère »
/// (`/api/calendrier-biblique/{annee}` — même jour : AnneeBibliqueModel,
/// JourBibliqueModel, FeteModel, EvenementShofarModel dans l'app mobile
/// existante yeshua-connect-mobile) : les tests de parité comparent ce
/// moteur aux données réelles servies par le backend.
library;

// ─────────────────────────────────────────────────────────────────────
//  Temps solaire
// ─────────────────────────────────────────────────────────────────────

/// Horaires solaires d'une journée pour une position donnée.
///
/// [lever] et [coucher] peuvent être `null` : région polaire (soleil
/// permanent ou absent). L'application doit alors afficher
/// l'indisponibilité — JAMAIS un horaire inventé (cahier des charges §9.4).
class SolarTimes {
  /// Lever du soleil (heure locale).
  final DateTime? lever;

  /// Coucher du soleil (heure locale).
  final DateTime? coucher;

  /// Position utilisée pour le calcul.
  final double latitude;
  final double longitude;

  const SolarTimes({
    this.lever,
    this.coucher,
    required this.latitude,
    required this.longitude,
  });

  bool get calculable => lever != null && coucher != null;

  /// Durée du jour (lever → coucher) en minutes.
  /// `null` si le calcul est impossible (région polaire).
  double? get dureeJourMinutes =>
      calculable ? coucher!.difference(lever!).inMinutes.toDouble() : null;

  /// Durée de la nuit (coucher → lever suivant) en minutes.
  /// `null` si le calcul est impossible.
  double? dureeNuitMinutes(SolarTimes jourSuivant) =>
      calculable && jourSuivant.calculable
          ? jourSuivant.lever!.difference(coucher!).inMinutes.toDouble()
          : null;

  @override
  String toString() =>
      'SolarTimes(lever: $lever, coucher: $coucher, lat: $latitude, lon: $longitude)';
}

// ─────────────────────────────────────────────────────────────────────
//  Temps biblique — veilles, heures saisonnières, parties du jour
// ─────────────────────────────────────────────────────────────────────

/// Statut d'une période (veille / heure saisonnière / partie du jour).
enum StatutPeriode { aVenir, enCours, terminee }

/// Les trois veilles de la nuit (Exode 14:24, Juges 7:19, 1 Samuel 11:11).
enum IndiceVeille { premiere, deuxieme, troisieme }

/// Une veille de la nuit.
class VeilleModel {
  final IndiceVeille indice;
  final String nom;
  final String sousTitre;
  final DateTime debut;
  final DateTime fin;
  final Duration duree;
  final StatutPeriode statut;
  /// Progression 0.0 → 1.0 (1.0 pour une période terminée, 0.0 à venir).
  final double progression;

  const VeilleModel({
    required this.indice,
    required this.nom,
    required this.sousTitre,
    required this.debut,
    required this.fin,
    required this.duree,
    required this.statut,
    required this.progression,
  });
}

/// Les quatre parties du jour (convention d'affichage de l'app, §4.3).
enum IndicePartie { premiere, deuxieme, troisieme, quatrieme }

/// Une partie du jour — regroupement de 3 heures saisonnières.
class PartieJourModel {
  final IndicePartie indice;
  final int de; // première heure saisonnière (1-12)
  final int a; // dernière heure saisonnière (1-12)
  final String designation; // Matin, Approche du milieu du jour, …
  final StatutPeriode statut;
  final double progression;

  const PartieJourModel({
    required this.indice,
    required this.de,
    required this.a,
    required this.designation,
    required this.statut,
    required this.progression,
  });
}

/// Une heure saisonnière du jour (1 à 12).
class HeureSaisonniereModel {
  final int numero; // 1-12
  final DateTime debut;
  final DateTime fin;
  final Duration duree;
  final StatutPeriode statut;
  final double progression;
  /// Partie du jour à laquelle appartient cette heure (1-4).
  final int partie;
  /// Repère scripturaire traditionnel (3ᵉ, 6ᵉ, 9ᵉ, 11ᵉ heure), sinon null.
  final String? repereScripturaire;

  const HeureSaisonniereModel({
    required this.numero,
    required this.debut,
    required this.fin,
    required this.duree,
    required this.statut,
    required this.progression,
    required this.partie,
    this.repereScripturaire,
  });
}

/// La période actuellement en cours — réponse centrale du
/// [BiblicalTimeEngine].
sealed class PeriodeActuelle {
  const PeriodeActuelle();
}

/// Le soleil est couché : une veille de la nuit est en cours.
class NuitEnCours extends PeriodeActuelle {
  final VeilleModel veille;
  final List<VeilleModel> veilles;
  /// Prochain lever du soleil.
  final DateTime prochainLever;
  const NuitEnCours({
    required this.veille,
    required this.veilles,
    required this.prochainLever,
  });
}

/// Le soleil est levé : une heure saisonnière et une partie du jour.
class JourEnCours extends PeriodeActuelle {
  final HeureSaisonniereModel heure;
  final List<HeureSaisonniereModel> heures;
  final List<PartieJourModel> parties;
  /// Prochain coucher du soleil.
  final DateTime prochainCoucher;
  const JourEnCours({
    required this.heure,
    required this.heures,
    required this.parties,
    required this.prochainCoucher,
  });
}

/// Calcul impossible (région polaire) — jamais d'horaire inventé.
class PeriodeIndisponible extends PeriodeActuelle {
  final String motif;
  const PeriodeIndisponible(this.motif);
}

// ─────────────────────────────────────────────────────────────────────
//  Calendrier biblique de 364 jours
// ─────────────────────────────────────────────────────────────────────

/// Un jour de l'année biblique (miroir `JourBibliqueModel` du backend).
class JourBiblique {
  final int jourDeAnnee; // 1-364
  final int mois; // 1-12 biblique
  final String nomMois; // Aviv, Ziv…
  final int jourDuMois;
  final int jourDeSemaine; // 1 = Dimanche … 7 = Shabbat (Samedi)
  final String nomJourSemaine;
  final bool estShabbat;
  final DateTime dateGregorienne; // minuit local du jour civil
  final int trimestre; // 1-4

  const JourBiblique({
    required this.jourDeAnnee,
    required this.mois,
    required this.nomMois,
    required this.jourDuMois,
    required this.jourDeSemaine,
    required this.nomJourSemaine,
    required this.estShabbat,
    required this.dateGregorienne,
    required this.trimestre,
  });
}

/// Une fête de l'Éternel (miroir `FeteModel` du backend).
class FeteBiblique {
  final String id;
  final String nomFr;
  final String? nomHebrew;
  final String referenceEcritures;
  final String description;
  final String categorie; // nouvelle_annee | convocation_sainte | jeune
  final String couleur; // hex du backend — conservé tel quel
  final bool travailInterdit;
  final int dureeJours;
  final String dateBiblique; // « 14 Aviv »
  final DateTime dateGregorienne;
  final int jourDeSemaine;
  final int joursRestants;

  const FeteBiblique({
    required this.id,
    required this.nomFr,
    this.nomHebrew,
    required this.referenceEcritures,
    required this.description,
    required this.categorie,
    this.couleur = '#C9A227',
    required this.dateGregorienne,
    this.travailInterdit = false,
    this.dureeJours = 1,
    this.dateBiblique = '',
    this.jourDeSemaine = 1,
    this.joursRestants = 0,
  });
}

/// Une année biblique de 364 jours (miroir `AnneeBibliqueModel` du backend).
class AnneeBiblique {
  final int annee; // étiquette civile de départ (« 2025 » → libellé 2025-2026)
  final String libelle; // « 2025-2026 »
  final DateTime debut; // 1er jour (1 Aviv), minuit local
  final DateTime fin; // 364ᵉ jour, minuit local
  final int nombreJours; // toujours 364
  final List<JourBiblique> jours;
  final List<FeteBiblique> fetes;

  const AnneeBiblique({
    required this.annee,
    required this.libelle,
    required this.debut,
    required this.fin,
    required this.jours,
    required this.fetes,
  })  : nombreJours = jours.length;

  JourBiblique? jourPourDate(DateTime date) {
    for (final j in jours) {
      final d = j.dateGregorienne;
      if (d.year == date.year && d.month == date.month && d.day == date.day) {
        return j;
      }
    }
    return null;
  }
}

/// Un événement « shofar » (miroir `EvenementShofarModel` du backend) :
/// Shabbat hebdomadaire ou solennité, entrée au coucher du soleil réel.
class EvenementShofar {
  final String id;
  final String type; // shabbat | fete
  final String titre;
  final String? titreHebreu;
  final String couleur;
  final String? dateBiblique;
  final DateTime dateGregorienne;
  final DateTime entree; // coucher du soleil d'entrée
  final DateTime sortie; // coucher du soleil de sortie
  final int dureeJours;
  final String? description;
  final String? reference;
  final bool travailInterdit;
  final List<JalonJalons> jalons;

  const EvenementShofar({
    required this.id,
    required this.type,
    required this.titre,
    this.titreHebreu,
    this.couleur = '#C9A227',
    required this.dateGregorienne,
    required this.entree,
    required this.sortie,
    this.dateBiblique,
    this.dureeJours = 1,
    this.description,
    this.reference,
    this.travailInterdit = false,
    this.jalons = const [],
  });

  bool get estFete => type == 'fete';
}

/// Jalon de notification d'une solennité : J-7 / J-3 / J-24 h.
class JalonJalons {
  final String cle; // j7 | j3 | j24h
  final DateTime date;
  final String label;

  const JalonJalons({required this.cle, required this.date, required this.label});
}

// ─────────────────────────────────────────────────────────────────────
//  Transition de jour biblique
// ─────────────────────────────────────────────────────────────────────

/// Résultat d'une évaluation de transition (protection anti-double).
class ResultatTransition {
  /// `true` si un nouveau jour biblique a commencé depuis [precedente].
  final bool transitionDue;
  /// Date du coucher du soleil qui a déclenché la transition.
  final DateTime? coucherDeclencheur;
  /// Nouveau jour biblique en cours après transition (null si indisponible).
  final JourBiblique? nouveauJour;
  /// Identifiant de la transition (annee-jourDeAnnee) — clé anti-doublon.
  final String? cleTransition;

  const ResultatTransition({
    required this.transitionDue,
    this.coucherDeclencheur,
    this.nouveauJour,
    this.cleTransition,
  });
}

/// Instantané persistable de l'état temporel (§13 — fiabilité).
class EtatTemporel {
  final DateTime horodatage;
  final String fuseau;
  final DateTime? dernierCoucherCalcule;
  final DateTime? prochainCoucherCalcule;
  final String? cleDerniereTransition;
  final int anneeBibliqueEnCours;
  final int jourDeAnneeEnCours;

  const EtatTemporel({
    required this.horodatage,
    required this.fuseau,
    this.dernierCoucherCalcule,
    this.prochainCoucherCalcule,
    this.cleDerniereTransition,
    this.anneeBibliqueEnCours = 0,
    this.jourDeAnneeEnCours = 0,
  });

  Map<String, dynamic> toJson() => {
        'horodatage': horodatage.toIso8601String(),
        'fuseau': fuseau,
        'dernierCoucherCalcule': dernierCoucherCalcule?.toIso8601String(),
        'prochainCoucherCalcule': prochainCoucherCalcule?.toIso8601String(),
        'cleDerniereTransition': cleDerniereTransition,
        'anneeBibliqueEnCours': anneeBibliqueEnCours,
        'jourDeAnneeEnCours': jourDeAnneeEnCours,
      };

  static EtatTemporel fromJson(Map<String, dynamic> json) => EtatTemporel(
        horodatage:
            DateTime.tryParse(json['horodatage'] as String? ?? '') ?? DateTime.now(),
        fuseau: json['fuseau'] as String? ?? '',
        dernierCoucherCalcule:
            DateTime.tryParse(json['dernierCoucherCalcule'] as String? ?? ''),
        prochainCoucherCalcule:
            DateTime.tryParse(json['prochainCoucherCalcule'] as String? ?? ''),
        cleDerniereTransition: json['cleDerniereTransition'] as String?,
        anneeBibliqueEnCours: (json['anneeBibliqueEnCours'] as num?)?.toInt() ?? 0,
        jourDeAnneeEnCours: (json['jourDeAnneeEnCours'] as num?)?.toInt() ?? 0,
      );
}
