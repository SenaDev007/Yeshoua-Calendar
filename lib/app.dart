/// ⭐ Horloge Céleste APP — coquille de navigation (§10.3) : cinq espaces, pas plus.
///
///   1. Accueil      — vue d'ensemble du cycle biblique en cours ;
///   2. Horloge      — divine clock numérique / analogique (§6) ;
///   3. Temps biblique — veilles + parties du jour + heures (§3, §4, §11) ;
///   4. Calendrier   — calendrier de 364 jours (§7) ;
///   5. Alarmes      — les trois RHEMA (§8).
///
/// NavigationBar Material 3, état préservé par IndexedStack.
/// BASCULE AUTOMATIQUE : les pages Accueil et Horloge s'échangent toutes
/// les 5 secondes avec une animation (§11 — demande utilisateur) ; l'horloge
/// ANALOGIQUE est toujours affichée lorsque la page Horloge apparaît.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'services/settings_store.dart';
import 'services/wallpaper_service.dart';
import 'state/settings_controller.dart';
import 'ui/screens/accueil_screen.dart';
import 'ui/screens/alarmes_screen.dart';
import 'ui/screens/calendrier_screen.dart';
import 'ui/screens/horloge_screen.dart';
import 'ui/screens/parametres_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/temps_biblique_screen.dart';

class HorlogeCelesteApp extends ConsumerWidget {
  const HorlogeCelesteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '${AppConfig.nomApp} — ${AppConfig.signature}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('fr'),
      // Délégations de localisation OBLIGATOIRES : sans elles,
      // MaterialLocalizations.of(context) est null en français — la
      // NavigationBar (onglets !), les ExpansionTile de Paramètres et les
      // TextField lèvent une exception au build et deviennent le widget
      // gris d'erreur en release (zones grises + navigation morte).
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr')],
      // Loader animé : le médaillon vivant (sablier, comète, éclat) accueille
      // l'utilisateur à l'allumage, puis fondu vers la coquille (§10.3).
      home: const SplashScreen(),
      routes: {'/accueil': (_) => const CoquilleNavigation()},
    );
  }
}

class CoquilleNavigation extends ConsumerStatefulWidget {
  const CoquilleNavigation({super.key});

  @override
  ConsumerState<CoquilleNavigation> createState() => _CoquilleNavigationState();
}

class _CoquilleNavigationState extends ConsumerState<CoquilleNavigation> {
  int _index = 0;
  Timer? _basculeAutomatique;

  /// Durée entre deux bascules Accueil ⇄ Horloge (demande : 5 s).
  static const Duration _delaiBascule = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _basculeAutomatique = Timer.periodic(_delaiBascule, (_) => _basculer());
    // Proposition « écran de verrouillage » (§9.5) : UNE SEULE fois,
    // après le premier rendu (le dialogue a besoin du contexte monté).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _proposerEcranVerrouillage();
    });
  }

  /// Propose d'installer l'Horloge Céleste COMME ÉCRAN DE VERROUILLAGE
  /// (fond d'écran animé affectable au verrouillage sur Android 13+, aux
  /// deux écrans sinon). Une seule proposition — rejouable dans Paramètres.
  Future<void> _proposerEcranVerrouillage() async {
    final store = SettingsStore.instance;
    if (store.propositionVerrouillageVue()) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.blanc,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.orSolaire.withValues(alpha: 0.55)),
        ),
        title: Row(
          children: const [
            Icon(Icons.lock_clock, color: AppColors.orSolaire, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sur votre écran\nde verrouillage',
                style: TextStyle(
                  color: AppColors.ardoise,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installez l\'horloge biblique 24 h comme fond d\'écran animé : '
              'elle s\'affichera quand votre téléphone se verrouille, avec '
              'vos alarmes programmées et la prochaine sonnerie.',
              style: TextStyle(
                color: AppColors.grisSecondaire,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sur Android 13+, choisissez « Écran de verrouillage » dans le '
              'sélecteur : votre écran d\'accueil reste inchangé. Activable '
              'ou désactivable à tout moment dans les Paramètres.',
              style: TextStyle(
                color: AppColors.grisSecondaire.withValues(alpha: 0.85),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.wallpaper, size: 17),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.bleuCiel,
              foregroundColor: AppColors.blanc,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              WallpaperService.ouvrirChoix();
            },
            label: const Text('Ajouter l\'horloge'),
          ),
        ],
      ),
    );
    // Marquage APRÈS le dialogue : si l'app est fermée pendant, la
    // proposition sera repoussée au prochain lancement (jamais perdue).
    await store.marquerPropositionVerrouillageVue();
  }

  @override
  void dispose() {
    _basculeAutomatique?.cancel();
    super.dispose();
  }

  /// Bascule animée Accueil ⇄ Horloge toutes les 5 s — uniquement lorsque
  /// l'une des deux pages est visible (jamais sur Calendrier/Alarmes, et
  /// jamais pendant qu'un écran plein (Paramètres…) est ouvert).
  void _basculer() {
    if (!mounted) return;
    if (_index != 0 && _index != 1) return;
    // Un itinéraire poussé (Paramètres…) recouvre la coquille : on s'arrête.
    if (Navigator.of(context, rootNavigator: true).canPop()) return;
    setState(() {
      _index = _index == 0 ? 1 : 0;
      if (_index == 1) {
        // En arrivant sur la page Horloge, l'HORLOGE ANALOGIQUE doit être
        // vue (demande utilisateur explicite).
        final settings = ref.read(settingsProvider);
        if (!settings.horlogeAnalogique) {
          ref.read(settingsProvider.notifier).basculerHorlogeAnalogique(true);
        }
      }
    });
  }

  static const List<String> _titres = [
    'Accueil',
    'Horloge',
    'Temps biblique',
    'Calendrier',
    'Alarmes',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: _index == 0
            ? Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bleuCielNuit,
                      border: Border.all(color: AppColors.orSolaire, width: 2),
                    ),
                    // Logo Horloge Céleste (placeholder — logo officiel à
                    // intégrer quand il sera fourni).
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo-horloge-celeste.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Horloge Céleste',
                          style: TextStyle(
                            color: AppColors.ardoise,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          AppConfig.signature,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grisSecondaire,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Text(_titres[_index]),
        actions: [
          IconButton(
            tooltip: 'Paramètres et localisation',
            icon: const Icon(Icons.settings_outlined,
                color: AppColors.grisSecondaire),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ParametresScreen(),
            )),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        // Transition douce entre les deux pages qui basculent (§11).
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (enfant, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(animation),
            child: enfant,
          ),
        ),
        child: IndexedStack(
          // La clé déclenche l'animation à chaque bascule d'index.
          key: ValueKey<int>(_index),
          index: _index,
          children: const [
            AccueilScreen(),
            HorlogeScreen(),
            TempsBibliqueScreen(),
            CalendrierScreen(),
            AlarmesScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch),
            label: 'Horloge',
          ),
          NavigationDestination(
            icon: Icon(Icons.nightlight_outlined),
            selectedIcon: Icon(Icons.nightlight),
            label: 'Temps biblique',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendrier',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alarmes',
          ),
        ],
      ),
      // settings.horlogeAnalogique est consommé par HorlogeScreen.
      // (référence ici pour lier l'état des préférences à la coquille.)
    );
  }
}
