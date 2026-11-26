/// ⭐ ZMAN APP — coquille de navigation (§10.3) : cinq espaces, pas plus.
///
///   1. Accueil      — vue d'ensemble du cycle biblique en cours ;
///   2. Horloge      — divine clock numérique / analogique (§6) ;
///   3. Temps biblique — veilles + parties du jour + heures (§3, §4, §11) ;
///   4. Calendrier   — calendrier de 364 jours (§7) ;
///   5. Alarmes      — les trois RHEMA (§8).
///
/// NavigationBar Material 3, état préservé par IndexedStack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'state/settings_controller.dart';
import 'ui/screens/accueil_screen.dart';
import 'ui/screens/alarmes_screen.dart';
import 'ui/screens/calendrier_screen.dart';
import 'ui/screens/horloge_screen.dart';
import 'ui/screens/parametres_screen.dart';
import 'ui/screens/temps_biblique_screen.dart';

class ZmanApp extends ConsumerWidget {
  const ZmanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '${AppConfig.nomApp} — ${AppConfig.signature}',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      home: const CoquilleNavigation(),
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
                    child: const Icon(Icons.schedule, size: 20, color: AppColors.orSolaire),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zman · זְמַן',
                        style: TextStyle(
                          color: AppColors.ardoise,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppConfig.signature,
                        style: const TextStyle(
                          color: AppColors.grisSecondaire,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Text(_titres[_index]),
        actions: [
          IconButton(
            tooltip: 'Paramètres et localisation',
            icon: const Icon(Icons.settings_outlined, color: AppColors.grisSecondaire),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ParametresScreen(),
            )),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          AccueilScreen(),
          HorlogeScreen(),
          TempsBibliqueScreen(),
          CalendrierScreen(),
          AlarmesScreen(),
        ],
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
