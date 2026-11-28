/// ⭐ APERÇU SONORE (§8.4) — lecture IMMÉDIATE des sonneries embarquées et
/// vibration réelle : quand l'utilisateur tape « shofar », « cloche »,
/// « harpe » ou « vibration », il ENTEND le son ou SENT la vibration sur-
/// le-champ — même téléphone en silencieux (le canal haptique ne dépend
/// pas du mode de sonnerie).
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class ApercuiSonore {
  ApercuiSonore._();
  static final ApercuiSonore instance = ApercuiSonore._();

  final AudioPlayer _lecteur = AudioPlayer();
  String? _assetEnCours;

  /// Asset MP3 correspondant au mode de sonnerie choisi ('' = silence).
  static String assetPourSon(String son) => switch (son) {
        'shofar' => 'sounds/shofar.mp3',
        'cloche' => 'sounds/cloche.mp3',
        'harpe' => 'sounds/harpe.mp3',
        _ => '',
      };

  /// Joue le son choisi depuis le début (aperçu dans l'écran Alarmes).
  Future<void> jouer(String son) async {
    final asset = assetPourSon(son);
    if (asset.isEmpty) {
      await stopper();
      return;
    }
    try {
      await _lecteur.stop();
      _assetEnCours = asset;
      // lowLatency : démarrage quasi instantané pour un aperçu réactif.
      await _lecteur.play(AssetSource(asset), mode: PlayerMode.lowLatency);
    } catch (_) {
      // L'aperçu ne doit jamais bloquer l'interface.
    }
  }

  Future<void> stopper() async {
    try {
      await _lecteur.stop();
    } catch (_) {
      // Silencieux.
    }
    _assetEnCours = null;
  }

  /// Vibration réelle (double pulsation) — perceptible même lorsque le
  /// téléphone est en mode silencieux ou vibreur.
  Future<void> vibrer() async {
    try {
      final ok = await Vibration.hasVibrator() ?? false;
      if (!ok) return;
      await Vibration.vibrate(pattern: [0, 400, 200, 400]);
    } catch (_) {
      // Pas de vibreur : rien à faire.
    }
  }
}
