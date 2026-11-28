/// Écran de démarrage (loader) — première seconde de vie de l'application.
///
/// Affiche le médaillon **animé** (le sablier qui s'écoule, la comète dorée qui
/// parcourt la lunette graduée, la lueur centrale, les étincelles, les
/// rouleaux qui « respirent », l'engrenage qui tourne, le texte hébraïque qui
/// s'écrit de droite à gauche et le retournement masqué par un éclair) le
/// temps que les préférences, le moteur d'alarmes et Riverpod finissent de
/// s'initialiser, puis rejoint la coquille de navigation avec un fondu.
///
/// AMBIANCE SONORE : un tic-tac de montre (tick… tock…) retentit pendant le
/// chargement — le temps d'observer l'horloge vivante — puis se tait à
/// l'entrée dans l'application.
///
/// Le fichier `assets/images/logo-horloge-celeste-anime.webp` est un WebP
/// animé lu nativement par Flutter (comme un GIF, sans paquet additionnel) :
/// la boucle de 2,5 s rejoue en continu toute la vie du médaillon.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Durée d'affichage : un peu plus d'une boucle complète du logo (2,5 s),
  /// le temps de voir le sablier se vider, le texte s'écrire et se
  /// retourner une fois.
  static const Duration _dureeAffichage = Duration(milliseconds: 3300);

  AudioPlayer? _ticTac;

  @override
  void initState() {
    super.initState();
    _jouerTicTac();
    Timer(_dureeAffichage, () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/accueil');
    });
  }

  /// Le tic-tac d'horloge pendant le chargement (en boucle douce) : le son
  /// de l'aiguille qui tourne, en écho à l'horloge biblique animée.
  Future<void> _jouerTicTac() async {
    try {
      final lecteur = AudioPlayer(playerId: 'tic_tac_splash');
      _ticTac = lecteur;
      await lecteur.setReleaseMode(ReleaseMode.loop);
      await lecteur.setVolume(0.55);
      await lecteur.play(AssetSource('sounds/tictac.mp3'));
    } catch (_) {
      // Le son est un agrément : jamais de blocage du loader.
    }
  }

  @override
  void dispose() {
    _ticTac?.stop();
    _ticTac?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2142),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, t, enfant) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: enfant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Halo nocturne doré derrière le médaillon.
              Container(
                width: 268,
                height: 268,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2ECFA63A), Color(0x000F2142)],
                    stops: [0.0, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/images/logo-horloge-celeste-anime.webp',
                  width: 228,
                  height: 228,
                  fit: BoxFit.contain,
                  // WebP animé décodé nativement : chaque cycle rejoue le
                  // sablier (écoulement, comète, éclair du retournement).
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Horloge Céleste',
                style: TextStyle(
                  color: AppColors.orVif,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Le temps de l\u2019alliance de l\u2019Éternel',
                style: TextStyle(
                  color: Color(0xB8FFFFFF),
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.orSolaire),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
