/// ⭐ CALENDRIER BIBLIQUE DE 364 JOURS — PHASE 5 du cahier des charges ZMAN.
///
/// REPRODUCTION EXACTE du calendrier servi par le backend « Mouvement
/// Christ Libère » (`/api/calendrier-biblique/{annee}`), moteur du
/// calendrier déjà implémenté dans Yeshua Connect Mobile. Les règles ont
/// été RÉTRO-INGÉNIÉRÉES depuis les données réelles de l'API puis
/// VALIDÉES sur 26 années échantillonnées (1900 → 2100) : parité 100 %
/// sur la structure des années, des mois, des jours de semaine, des
/// Shabbats et des 10 fêtes de l'Éternel (voir `test/` du package).
///
/// RÈGLES (identiques au backend, NE PAS MODIFIER — §18) :
///   1. L'année fait 364 jours = 52 semaines exactes, toujours 7×52 ;
///   2. L'année commence le mercredi le plus proche (distance en jours
///      entiers) de l'ÉQUINOXE DE MARS de son année de départ — le
///      mercredi étant le jour de la création des luminaires
///      (Genèse 1:14-19) ;
///   3. Les semaines intercalaires « émergent » de la règle (écart de
///      8 jours observé entre certaines années : 2022, 2028, 2033…) ;
///   4. 12 mois — Aviv, Ziv, Sivan, Tammouz, Av, Éloul, Éthanim, Boul,
///      Kislev, Tévet, Shevat, Adar — longueurs [30,30,31,30,30,31,
///      30,30,31,30,30,31] = 364 ;
///   5. Jour de semaine : 1 = Dimanche … 7 = Samedi (Shabbat) ; comme
///      l'année démarre un mercredi, chaque Samedi civil est un Shabbat ;
///   6. Trimestres (saisons) : mois 1-3 = Printemps, 4-6 = Été, 7-9 =
///      Automne, 10-12 = Hiver ;
///   7. Les 10 fêtes de l'Éternel ont des dates bibliques FIXES
///      (Lévitique 23, Exode 12:2).
library;

import 'dart:math' as math;

import 'models.dart';

class BiblicalCalendarEngine {
  BiblicalCalendarEngine._();

  /// Bornes d'années prises en charge (identiques au backend).
  static const int anneeMin = 1900;
  static const int anneeMax = 2100;

  /// Noms des mois bibliques (1-12) — exactement ceux du backend.
  static const List<String> nomsMois = [
    'Aviv', 'Ziv', 'Sivan', 'Tammouz', 'Av', 'Éloul',
    'Éthanim', 'Boul', 'Kislev', 'Tévet', 'Shevat', 'Adar',
  ];

  /// Longueurs des mois (somme = 364) — exactement celles du backend.
  static const List<int> longueursMois = [
    30, 30, 31, 30, 30, 31,
    30, 30, 31, 30, 30, 31,
  ];

  /// Noms des jours de semaine (index = jourDeSemaine - 1).
  static const List<String> nomsJoursSemaine = [
    'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi',
  ];

  static const List<String> nomsSaisons = [
    'Printemps', 'Été', 'Automne', 'Hiver',
  ];

  // ── RÈGLE D'ANCRAGE ANNUEL ──────────────────────────────────────────

  /// Équinoxe de mars de [annee] (heure UTC) — Meeus, Astronomical
  /// Algorithms ch. 27 (précision ~±2 min, largement suffisante pour
  /// déterminer le jour de l'équinoxe).
  static DateTime equinoxeMarsUTC(int annee) {
    final y = (annee - 2000) / 1000.0;
    // Instant astronomique (temps terrestre) en jours juliens
    var jde = 2451623.80984 +
        365242.37404 * y +
        0.05169 * y * y -
        0.00411 * y * y * y -
        0.00057 * y * y * y * y;
    final t = jde / 36525.0;
    final w = 35999.373 * t - 2.47;
    final dl = 1 + 0.0334 * _cosR(_rad(w)) + 0.0007 * _cosR(_rad(2 * w));
    var s = 0.0;
    void ajoute(double a, double b, double c) =>
        s += c * _cosR(_rad(a + b * t));
    ajoute(485, 324.96, 0.00103);
    ajoute(203, 337.23, 0.00084);
    ajoute(199, 342.08, 0.00064);
    ajoute(182, 27.85, 0.00112);
    ajoute(156, 73.14, 0.00082);
    ajoute(136, 171.52, 0.00067);
    ajoute(77, 222.54, 0.00023);
    ajoute(74, 296.72, 0.00003);
    ajoute(70, 18.68, 0.00013);
    jde += 0.00001 * s * dl;
    // Correction Delta T → heure UTC
    final deltaT = _deltaTSecondes(annee);
    final jdUTC = jde - deltaT / 86400.0;
    return _depuisJourJulien(jdUTC);
  }

  /// Le 1ᵉʳ jour (1 Aviv) de l'année biblique étiquetée [annee] :
  /// mercredi le plus proche de l'équinoxe de mars, distance mesurée en
  /// jours entiers (égalité impossible — les distances sont impaires).
  static DateTime debutAnneeBiblique(int annee) {
    final eq = equinoxeMarsUTC(annee);
    final jourEquinoxe = DateTime.utc(eq.year, eq.month, eq.day);
    // Dart weekday : 1 = lundi … 7 = dimanche → mercredi = 3
    var delta = (jourEquinoxe.weekday - 3) % 7;
    if (delta > 3) delta -= 7;
    return jourEquinoxe.add(Duration(days: -delta)).toLocal();
  }

  // ── CONSTRUCTION D'UNE ANNÉE ────────────────────────────────────────

  /// Construit l'année biblique complète (364 jours + fêtes).
  static AnneeBiblique construireAnnee(int annee) {
    final debut = debutAnneeBiblique(annee);

    final jours = <JourBiblique>[];
    var jourDeAnnee = 1;
    for (var mois = 1; mois <= 12; mois++) {
      final nomMois = nomsMois[mois - 1];
      final longueur = longueursMois[mois - 1];
      for (var j = 1; j <= longueur; j++) {
        final date = DateTime(debut.year, debut.month, debut.day)
            .add(Duration(days: jourDeAnnee - 1));
        // jourDeSemaine 1 = Dimanche … 7 = Samedi
        final jourDeSemaine = (date.weekday % 7) + 1;
        jours.add(JourBiblique(
          jourDeAnnee: jourDeAnnee,
          mois: mois,
          nomMois: nomMois,
          jourDuMois: j,
          jourDeSemaine: jourDeSemaine,
          nomJourSemaine: nomsJoursSemaine[jourDeSemaine - 1],
          estShabbat: jourDeSemaine == 7,
          dateGregorienne: DateTime(date.year, date.month, date.day),
          trimestre: ((mois - 1) ~/ 3) + 1,
        ));
        jourDeAnnee++;
      }
    }

    final fetes = _construireFetes(annee, debut);

    return AnneeBiblique(
      annee: annee,
      libelle: '$annee-${annee + 1}',
      debut: DateTime(debut.year, debut.month, debut.day),
      fin: DateTime(debut.year, debut.month, debut.day)
          .add(const Duration(days: 363)),
      jours: jours,
      fetes: fetes,
    );
  }

  /// L'année biblique qui contient [date] (label = année civile de départ).
  static AnneeBiblique anneePourDate(DateTime date) {
    var annee = date.year;
    // La recherche descend : une date de début d'année peut se rattacher
    // à l'année étiquetée l'année précédente (décembre…), ou l'année
    // suivante si on est déjà au 1ᵉʳ Aviv.
    for (var i = 0; i < 3; i++) {
      final debut = debutAnneeBiblique(annee);
      if (!date.isBefore(debut)) {
        final fin = debut.add(const Duration(days: 364));
        if (date.isBefore(fin)) return construireAnnee(annee);
      }
      annee--;
    }
    // Secours : année contenant la date la plus proche.
    return construireAnnee(date.year);
  }

  // ── FÊTES DE L'ÉTERNEL (définitions EXACTES du backend) ─────────────

  static List<FeteBiblique> _construireFetes(int annee, DateTime debut) {
    const defs = <_FeteDef>[
      _FeteDef(
        id: 'tete_annee', nomFr: "Tête de l'année", nomHebrew: 'ראש השנה',
        reference: 'Exode 12:2',
        description: "Nouvelle année biblique. Ce jour marque le début du compte des mois selon l'Éternel (Exode 12:2). L'année commence toujours un mercredi, jour de la création des luminaires (Genèse 1:14-19).",
        categorie: 'nouvelle_annee', couleur: '#C9A227',
        travailInterdit: false, dureeJours: 1,
        mois: 1, jour: 1, jourDeSemaineFixe: 4,
      ),
      _FeteDef(
        id: 'pessah', nomFr: 'Pessah (Pâque)', nomHebrew: 'פֶּסַח',
        reference: 'Lévitique 23:5',
        description: "Sacrifice de l'agneau au crépuscule. Commémoration de la sortie d'Égypte. Accomplie en Yeshoua, l'Agneau de Dieu qui ôte le péché du monde (Jean 1:29). La Pâque commence au coucher du soleil du mardi (14 Aviv).",
        categorie: 'convocation_sainte', couleur: '#C9A227',
        travailInterdit: false, dureeJours: 1,
        mois: 1, jour: 14, jourDeSemaineFixe: 3,
      ),
      _FeteDef(
        id: 'matsot_1', nomFr: 'Pains sans levain — 1er jour', nomHebrew: 'חַג הַמַּצּוֹת',
        reference: 'Lévitique 23:6-7',
        description: "Convocation sainte, pas de travail. Les sept jours de pain sans levain qui suivent Pessah. Le levain représentant le péché, cette fête illustre la sanctification — ôter le vieux levain pour manger le pain de la pureté (1 Corinthiens 5:7-8).",
        categorie: 'convocation_sainte', couleur: '#C9A227',
        travailInterdit: true, dureeJours: 1,
        mois: 1, jour: 15, jourDeSemaineFixe: 4,
      ),
      _FeteDef(
        id: 'matsot_7', nomFr: 'Pains sans levain — 7e jour', nomHebrew: 'חַג הַמַּצּוֹת',
        reference: 'Lévitique 23:8',
        description: 'Convocation sainte, pas de travail. Dernier jour de la fête des pains sans levain. Clôture de la semaine de sanctification.',
        categorie: 'convocation_sainte', couleur: '#C9A227',
        travailInterdit: true, dureeJours: 1,
        mois: 1, jour: 21, jourDeSemaineFixe: 3,
      ),
      _FeteDef(
        id: 'reshit_katzir', nomFr: 'Reshit Katzir (Prémices)', nomHebrew: 'רֵאשִׁית קְצִיר',
        reference: 'Lévitique 23:10-11',
        description: 'Offrande de la gerbe agitée, lendemain du sabbat qui suit Pessah. Accomplie en la résurrection de Yeshoua, « prémices de ceux qui sont morts » (1 Corinthiens 15:20).',
        categorie: 'convocation_sainte', couleur: '#C9A227',
        travailInterdit: false, dureeJours: 1,
        mois: 1, jour: 26, jourDeSemaineFixe: 1,
      ),
      _FeteDef(
        id: 'shavouot', nomFr: 'Shavouot (Pentecôte)', nomHebrew: 'שָׁבוּעוֹת',
        reference: 'Lévitique 23:15-16',
        description: "50 jours exacts après Reshit Katzir. Commémoration du don de la Torah au Sinaï ET de l'effusion du Saint-Esprit à Jérusalem (Actes 2). Fête de l'alliance scellée par l'Esprit.",
        categorie: 'convocation_sainte', couleur: '#C9A227',
        travailInterdit: true, dureeJours: 1,
        mois: 3, jour: 15, jourDeSemaineFixe: 1,
      ),
      _FeteDef(
        id: 'yom_teroua', nomFr: 'Yom Teroua (Trompettes)', nomHebrew: 'יוֹם תְּרוּעָה',
        reference: 'Lévitique 23:24',
        description: "Convocation sainte, sonnerie de trompettes. Annonce prophétique du retour du Messie : « le Seigneur lui-même descendra du ciel avec un cri, à la voix d'un archange et au son de la trompette de Dieu » (1 Thessaloniciens 4:16).",
        categorie: 'convocation_sainte', couleur: '#8C5FA8',
        travailInterdit: true, dureeJours: 1,
        mois: 7, jour: 1, jourDeSemaineFixe: 4,
      ),
      _FeteDef(
        id: 'yom_kippour', nomFr: 'Yom Kippour (Expiations)', nomHebrew: 'יוֹם כִּפּוּר',
        reference: 'Lévitique 23:27',
        description: "Jeûne, affliction de l'âme. Le jour le plus saint du calendrier. Accompli en Yeshoua, grand sacrificateur qui est entré une fois pour toutes dans le sanctuaire céleste avec son propre sang (Hébreux 9:12). Prophétiquement : le jour du jugement d'Israël et des nations.",
        categorie: 'jeune', couleur: '#B5502F',
        travailInterdit: true, dureeJours: 1,
        mois: 7, jour: 10, jourDeSemaineFixe: 6,
      ),
      _FeteDef(
        id: 'souccot_1', nomFr: 'Souccot (Tabernacles) — 1er jour', nomHebrew: 'סוּכּוֹת',
        reference: 'Lévitique 23:34',
        description: "Convocation sainte, 7 jours sous tentes. En mémoire de l'exode dans le désert. Prophétiquement : l'incarnation de Dieu parmi les hommes (« Il a tabernaclé parmi nous » Jean 1:14) et le rassemblement eschatologique des nations (Zacharie 14:16).",
        categorie: 'convocation_sainte', couleur: '#5B7052',
        travailInterdit: true, dureeJours: 7,
        mois: 7, jour: 15, jourDeSemaineFixe: 4,
      ),
      _FeteDef(
        id: 'shemini_atzeret', nomFr: 'Shemini Atzeret (8e jour)', nomHebrew: 'שְׁמִינִי עֲצֶרֶת',
        reference: 'Lévitique 23:36',
        description: "Assemblée de clôture, le 8e jour après Souccot. Jour de grande joie. Symbolise le huitième jour — l'éternité au-delà du temps créé (sept jours).",
        categorie: 'convocation_sainte', couleur: '#5B7052',
        travailInterdit: true, dureeJours: 1,
        mois: 7, jour: 22, jourDeSemaineFixe: 4,
      ),
    ];

    final fetes = <FeteBiblique>[];
    for (final def in defs) {
      final date = _jourBibliqueVersGregorien(debut, def.mois, def.jour);
      if (date == null) continue; // jamais atteint avec ces définitions
      final jourDeSemaine = (date.weekday % 7) + 1;
      fetes.add(FeteBiblique(
        id: def.id,
        nomFr: def.nomFr,
        nomHebrew: def.nomHebrew,
        referenceEcritures: def.reference,
        description: def.description,
        categorie: def.categorie,
        couleur: def.couleur,
        travailInterdit: def.travailInterdit,
        dureeJours: def.dureeJours,
        dateBiblique: '${def.jour} ${nomsMois[def.mois - 1]}',
        dateGregorienne: date,
        jourDeSemaine: jourDeSemaine,
        joursRestants: 0, // recalcule dynamiquement (voir joursRestants)
      ));
    }
    return fetes;
  }

  /// Jours restants avant une fête — même convention que le backend :
  /// (fête − aujourd'hui) en jours entiers ; négatif si passée.
  static int joursRestants(FeteBiblique fete, {DateTime? maintenant}) {
    final aujourdhui = maintenant ?? DateTime.now();
    final a = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
    final b = DateTime(fete.dateGregorienne.year, fete.dateGregorienne.month,
        fete.dateGregorienne.day);
    return b.difference(a).inDays;
  }

  // ── ÉVÉNEMENTS SHOFAR (Shabbats + fêtes, entrée au coucher réel) ────

  /// Construit les événements shofar d'une année. [coucherDuSoleilDe]
  /// fournit le coucher du soleil (heure locale) d'une date : Jérusalem
  /// pour reproduire le backend, position de l'utilisateur dans l'app.
  static List<EvenementShofar> construireEvenements(
    AnneeBiblique annee,
    DateTime Function(DateTime jour) coucherDuSoleilDe,
  ) {
    final evenements = <EvenementShofar>[];

    // Shabbats — entrée vendredi soir, sortie samedi soir.
    final shabbatDesc =
        "Le septième jour, jour de repos et de sainte convocation (Exode 20:8-11). Le shofar retentit à l'entrée, au coucher du soleil.";
    for (final jour in annee.jours) {
      if (!jour.estShabbat) continue;
      final veille =
          jour.dateGregorienne.subtract(const Duration(days: 1));
      evenements.add(EvenementShofar(
        id: 'shabbat-${_id(jour.dateGregorienne)}',
        type: 'shabbat',
        titre: 'Shabbat',
        titreHebreu: 'שַׁבָּת',
        couleur: '#2A0E3D',
        dateGregorienne: jour.dateGregorienne,
        entree: coucherDuSoleilDe(veille),
        sortie: coucherDuSoleilDe(jour.dateGregorienne),
        dureeJours: 1,
        description: shabbatDesc,
        reference: 'Lévitique 23:3',
        travailInterdit: true,
      ));
    }

    // Fêtes — entrée au coucher de la veille, sortie au coucher du
    // dernier jour (durée 1 → coucher du jour même ; 7 → coucher du
    // 7ᵉ jour, comme le backend : Souccot sort à l'entrée de Shemini).
    for (final fete in annee.fetes) {
      final dernierJour = fete.dateGregorienne
          .add(Duration(days: fete.dureeJours - 1));
      final entree =
          coucherDuSoleilDe(fete.dateGregorienne.subtract(const Duration(days: 1)));
      final sortie = coucherDuSoleilDe(dernierJour);
      final jalons = [
        JalonJalons(cle: 'j7', date: entree.subtract(const Duration(days: 7)), label: '7 jours'),
        JalonJalons(cle: 'j3', date: entree.subtract(const Duration(days: 3)), label: '3 jours'),
        JalonJalons(cle: 'j24h', date: entree.subtract(const Duration(hours: 24)), label: '24 heures'),
      ];
      evenements.add(EvenementShofar(
        id: 'fete-${fete.id}-${annee.annee}',
        type: 'fete',
        titre: fete.nomFr,
        titreHebreu: fete.nomHebrew,
        couleur: fete.couleur,
        dateBiblique: fete.dateBiblique,
        dateGregorienne: fete.dateGregorienne,
        entree: entree,
        sortie: sortie,
        dureeJours: fete.dureeJours,
        description: fete.description,
        reference: fete.referenceEcritures,
        travailInterdit: fete.travailInterdit,
        jalons: jalons,
      ));
    }

    evenements.sort((a, b) => a.entree.compareTo(b.entree));
    return evenements;
  }

  // ── AIDES ───────────────────────────────────────────────────────────

  /// Date grégorienne du [jour]ᵉ jour du mois biblique [mois] de l'année.
  static DateTime? _jourBibliqueVersGregorien(
      DateTime debut, int mois, int jour) {
    if (mois < 1 || mois > 12) return null;
    if (jour < 1 || jour > longueursMois[mois - 1]) return null;
    var offset = 0;
    for (var m = 1; m < mois; m++) {
      offset += longueursMois[m - 1];
    }
    return DateTime(debut.year, debut.month, debut.day)
        .add(Duration(days: offset + jour - 1));
  }

  static String _id(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Astronomie : équinoxe (Meeus) ───────────────────────────────────

  static double _deltaTSecondes(int annee) {
    if (annee < 1920) {
      return -20.0 + 32.0 * _carre((annee - 1820) / 100.0);
    } else if (annee < 2005) {
      return 62.0 + 1.2 * (annee - 1950);
    } else if (annee < 2050) {
      return 62.92 + 0.32 * (annee - 2000);
    }
    return 62.92 + 0.36 * (annee - 2000);
  }

  /// Jour julien → DateTime UTC.
  static DateTime _depuisJourJulien(double jd) {
    final z = jd + 0.5;
    final zi = z.floor();
    final f = z - zi;
    double a;
    if (zi < 2299161) {
      a = zi.toDouble();
    } else {
      final alpha = ((zi - 1867216.25) / 36524.25).floor();
      a = (zi + 1 + alpha - (alpha / 4).floor()).toDouble();
    }
    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d0 = (365.25 * c).floor();
    final e = ((b - d0) / 30.6001).floor();
    final jourFraction = b - d0 - (30.6001 * e).floor() + f;
    final jour = jourFraction.floor();
    final fraction = jourFraction - jour;
    // Mois/année depuis le cycle julien (e : 1-14 ; les mois couvrent
    // mars = 1 … février = 14 de l'année suivante).
    var mois = e - 1;
    var annee = c - 4716;
    if (mois > 12) mois -= 12;
    if (mois <= 2) annee += 1;
    final heures = fraction * 24.0;
    final h = heures.floor();
    final resteMinutes = (heures - h) * 60.0;
    final minutes = resteMinutes.floor();
    final secondes = ((resteMinutes - minutes) * 60.0).round();
    return DateTime.utc(annee, mois, jour, h, minutes, secondes);
  }

  static double _carre(double v) => v * v;
  static double _rad(double d) => d * 3.1415926535897932 / 180.0;
  static double _cosR(double r) => math.cos(r);
}

/// Définition statique d'une fête de l'Éternel (données EXACTES du
/// backend — id, noms, référence, description, catégorie, couleur,
/// travail interdit, durée, mois/jour bibliques et jour de semaine fixe).
class _FeteDef {
  final String id;
  final String nomFr;
  final String nomHebrew;
  final String reference;
  final String description;
  final String categorie;
  final String couleur;
  final bool travailInterdit;
  final int dureeJours;
  final int mois;
  final int jour;
  final int jourDeSemaineFixe;

  const _FeteDef({
    required this.id,
    required this.nomFr,
    required this.nomHebrew,
    required this.reference,
    required this.description,
    required this.categorie,
    required this.couleur,
    required this.travailInterdit,
    required this.dureeJours,
    required this.mois,
    required this.jour,
    required this.jourDeSemaineFixe,
  });
}
