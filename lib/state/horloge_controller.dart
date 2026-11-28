/// ⭐ Horloge Céleste CONTROLLER — état central de l'application (Riverpod).
///
/// À chaque seconde :
///   • heure civile réelle (TimeEngine) ;
///   • horaires solaires du jour / veille / lendemain (SolarEngine, cache) ;
///   • période actuelle — veille de nuit ou heure saisonnière
///     (BiblicalTimeEngine) ;
///   • date biblique en cours (calendrier 364 jours + adapter §7) ;
///   • évaluation de la TRANSITION au coucher du soleil réel (§14) :
///     vérification « réellement due » + clé anti-double persistée ;
///   • compte à rebours vers le prochain coucher.
///
/// À la reprise (§13) : recalcul complet depuis l'heure réelle — jamais
/// depuis les anciens états conservés.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../core/app/cycle_app.dart';
import '../services/settings_store.dart';
import '../services/wallpaper_service.dart';
import 'settings_controller.dart';

class HorlogeState {
  final DateTime maintenant;
  final PositionUtilisateur position;
  final SolarTimes? solarJour;
  final SolarTimes? solarPrecedent;
  final SolarTimes? solarSuivant;
  final PeriodeActuelle? periode;
  final JourBiblique? jourBiblique;
  final AnneeBiblique? anneeBiblique;
  final DateTime? prochainCoucher;
  final Duration compteAReboursCoucher;
  final bool transitionEffectuee;
  final String? cleTransition;
  final bool calculSolaireIndisponible;

  const HorlogeState({
    required this.maintenant,
    required this.position,
    this.solarJour,
    this.solarPrecedent,
    this.solarSuivant,
    this.periode,
    this.jourBiblique,
    this.anneeBiblique,
    this.prochainCoucher,
    this.compteAReboursCoucher = Duration.zero,
    this.transitionEffectuee = false,
    this.cleTransition,
    this.calculSolaireIndisponible = false,
  });

  HorlogeState copyWith({
    DateTime? maintenant,
    PositionUtilisateur? position,
    SolarTimes? solarJour,
    SolarTimes? solarPrecedent,
    SolarTimes? solarSuivant,
    PeriodeActuelle? periode,
    JourBiblique? jourBiblique,
    AnneeBiblique? anneeBiblique,
    DateTime? prochainCoucher,
    Duration? compteAReboursCoucher,
    bool? transitionEffectuee,
    String? cleTransition,
    bool? calculSolaireIndisponible,
  }) =>
      HorlogeState(
        maintenant: maintenant ?? this.maintenant,
        position: position ?? this.position,
        solarJour: solarJour ?? this.solarJour,
        solarPrecedent: solarPrecedent ?? this.solarPrecedent,
        solarSuivant: solarSuivant ?? this.solarSuivant,
        periode: periode ?? this.periode,
        jourBiblique: jourBiblique ?? this.jourBiblique,
        anneeBiblique: anneeBiblique ?? this.anneeBiblique,
        prochainCoucher: prochainCoucher ?? this.prochainCoucher,
        compteAReboursCoucher:
            compteAReboursCoucher ?? this.compteAReboursCoucher,
        transitionEffectuee: transitionEffectuee ?? this.transitionEffectuee,
        cleTransition: cleTransition ?? this.cleTransition,
        calculSolaireIndisponible:
            calculSolaireIndisponible ?? this.calculSolaireIndisponible,
      );
}

class HorlogeController extends Notifier<HorlogeState> {
  Timer? _timer;
  BiblicalCalendarAdapter? _adapter;

  @override
  HorlogeState build() {
    final position = SettingsStore.instance.position();
    _adapter = BiblicalCalendarAdapter(
      latitude: position.latitude,
      longitude: position.longitude,
      cleDerniereTransition:
          SettingsStore.instance.derniereTransition(),
    );
    recalculerComplet(position);

    // Battement d'une seconde (§12.A TimeEngine).
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    // Reprise après mise en arrière-plan : recalcul complet (§13).
    AppCycleLiaison.instance.enregistrerCallback(_reprise);

    ref.onDispose(() {
      _timer?.cancel();
      AppCycleLiaison.instance.enregistrerCallback(null);
    });

    return state;
  }

  /// Battement — recalcul léger chaque seconde + gestion des transitions.
  void _tick() {
    if (state.solarJour == null) {
      recalculerComplet(state.position);
      return;
    }
    final maintenant = DateTime.now();

    // ── Transition au coucher du soleil réel (§14 — les 7 étapes) ──
    final adapter = _adapter!;
    final evaluation = adapter.evaluerTransition(
      maintenant: maintenant,
      cleTraitee: SettingsStore.instance.derniereTransition(),
    );
    var transitionFaite = false;
    if (evaluation.transitionDue && evaluation.nouveauJour != null) {
      // 1-2. due + jamais traitée (clé anti-double §14) ; 3. nouvelle date ;
      // 4-5. actualisation du calendrier/période ; 6. affichage ; 7. alarmes.
      SettingsStore.instance
          .sauvegarderDerniereTransition(evaluation.cleTransition!);
      transitionFaite = true;
      recalculerComplet(state.position);
      return;
    }

    final periode = BiblicalTimeEngine.periodeActuelle(
      jour: state.solarJour!,
      jourSuivant: state.solarSuivant!,
      jourPrecedent: state.solarPrecedent!,
      maintenant: maintenant,
    );
    final reste = state.prochainCoucher == null
        ? Duration.zero
        : state.prochainCoucher!.difference(maintenant);

    state = state.copyWith(
      maintenant: maintenant,
      periode: periode,
      compteAReboursCoucher: reste.isNegative ? Duration.zero : reste,
      transitionEffectuee:
          transitionFaite ? true : state.transitionEffectuee,
      cleTransition: evaluation.cleTransition ?? state.cleTransition,
    );

    // État persisté toutes les 30 s (§13).
    if (maintenant.second % 30 == 0) _persisterEtat();

    // Instantané du wallpaper rafraîchi chaque minute : la date biblique et
    // le prochain coucher de l'écran de verrouillage restent exacts même
    // quand l'app est ouverte depuis des heures (§9.5).
    if (maintenant.second == 0) {
      unawaited(WallpaperService.actualiserSnapshot());
    }
  }

  /// Reprise de l'app — recalcul COMPLET depuis l'heure réelle (§13).
  void _reprise() {
    final etatSauvegarde = SettingsStore.instance.etatTemporelJson();
    EtatTemporel? dernier;
    if (etatSauvegarde != null) {
      try {
        dernier = EtatTemporel.fromJson(
            Map<String, dynamic>.from(jsonDecode(etatSauvegarde) as Map));
      } catch (_) {
        dernier = null;
      }
    }
    final rupture = TimeEngine.detecterRupture(dernierEtat: dernier);
    // Quelle que soit la rupture (ou son absence), on recalcule tout :
    // l'astronomie est le référentiel, pas les anciens états.
    recalculerComplet(state.position);
    if (rupture != null) {
      // Les alarmes seront replanifiées par le contrôleur d'alarmes
      // (écoute de l'état de position / démarrage).
    }
  }

  /// Recalcul complet : astronomie + calendrier + période (§13, §16).
  void recalculerComplet(PositionUtilisateur position) {
    final maintenant = DateTime.now();
    final adapter = BiblicalCalendarAdapter(
      latitude: position.latitude,
      longitude: position.longitude,
      cleDerniereTransition: SettingsStore.instance.derniereTransition(),
    );
    _adapter = adapter;

    final solarJour = SolarEngine.calculer(maintenant,
        position.latitude, position.longitude);
    final solarPrecedent = SolarEngine.calculer(
        maintenant.subtract(const Duration(days: 1)),
        position.latitude,
        position.longitude);
    final solarSuivant = SolarEngine.calculer(
        maintenant.add(const Duration(days: 1)),
        position.latitude,
        position.longitude);

    final jourBiblique = adapter.jourBibliqueActuel(maintenant);
    final annee = jourBiblique == null
        ? BiblicalCalendarEngine.anneePourDate(maintenant)
        : BiblicalCalendarEngine.anneePourDate(jourBiblique.dateGregorienne);

    final periode = BiblicalTimeEngine.periodeActuelle(
      jour: solarJour,
      jourSuivant: solarSuivant,
      jourPrecedent: solarPrecedent,
      maintenant: maintenant,
    );

    final prochainCoucher = adapter.prochainCoucher(maintenant);
    final reste = prochainCoucher == null
        ? Duration.zero
        : prochainCoucher.difference(maintenant);

    state = HorlogeState(
      maintenant: maintenant,
      position: position,
      solarJour: solarJour,
      solarPrecedent: solarPrecedent,
      solarSuivant: solarSuivant,
      periode: periode,
      jourBiblique: jourBiblique,
      anneeBiblique: annee,
      prochainCoucher: prochainCoucher,
      compteAReboursCoucher: reste.isNegative ? Duration.zero : reste,
      cleTransition: SettingsStore.instance.derniereTransition(),
      calculSolaireIndisponible: !solarJour.calculable,
    );
    _persisterEtat();
  }

  void _persisterEtat() {
    try {
      final etat = _adapter?.etatTemporel(state.maintenant,
          fuseau: state.position.fuseau);
      if (etat != null) {
        SettingsStore.instance
            .sauvegarderEtatTemporel(jsonEncode(etat.toJson()));
      }
    } catch (_) {
      // La persistance est un confort — jamais bloquante.
    }
  }

  /// Changement de position (§9.2) — recalcul complet immédiat.
  Future<void> changerPosition(PositionUtilisateur position) async {
    await SettingsStore.instance.sauvegarderPosition(position);
    recalculerComplet(position);
  }
}

/// Provider de l'horloge céleste — état central regardé par les écrans
/// (accueil, horloge, calendrier, temps biblique, paramètres) et par le
/// contrôleur d'alarmes (§8).
final horlogeProvider =
    NotifierProvider<HorlogeController, HorlogeState>(HorlogeController.new);
