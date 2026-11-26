/// Liaison du cycle de vie de l'app (§13 — reprise de l'application).
///
/// Un observer racine notifie le moteur à chaque reprise après mise en
/// arrière-plan : recalcul complet de l'état temporel depuis l'heure
/// réelle — jamais depuis les anciens états conservés.
library;

import 'package:flutter/widgets.dart';

class AppCycleLiaison with WidgetsBindingObserver {
  AppCycleLiaison._();
  static final AppCycleLiaison instance = AppCycleLiaison._();

  void Function()? _callbackReprise;
  DateTime? _arrierePlanDepuis;

  /// Enregistre le callback de reprise (appelé par ZmanController).
  void enregistrerCallback(void Function()? callback) {
    _callbackReprise = callback;
  }

  /// À brancher UNE fois dans main() — observer racine.
  void attacher() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _arrierePlanDepuis = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      // Reprise : notifie le moteur (recalcul complet §13). Même une
      // courte mise en arrière-plan déclenche un recalcul — l'astronomie
      // reste la référence et le coût est négligeable.
      _callbackReprise?.call();
      _arrierePlanDepuis = null;
    }
  }

  /// Durée passée en arrière-plan (utile pour l'audit / les logs).
  Duration? dureeArrierePlan() => _arrierePlanDepuis == null
      ? null
      : DateTime.now().difference(_arrierePlanDepuis!);
}
