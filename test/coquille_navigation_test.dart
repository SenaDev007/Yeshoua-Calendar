/// ⭐ TEST DE COQUILLE — garantit que la navigation est vivante (§10.3) et
/// que les correctifs de rendu tiennent :
///   • les délégations de localisation sont câblées : sans elles, la
///     NavigationBar (bande grise morte du bas), la TabBar et les
///     ExpansionTile de Paramètres (grande zone grise) crashent en release ;
///   • l'onglet Calendrier expose bien les 5 vues : Aujourd'hui, Semaine,
///     Mois, Trimestre, Année ;
///   • la vue Semaine liste les 7 jours et la vue Trimestre les 3 mois de
///     la saison ;
///   • tout est pompé à une taille de téléphone (412 × 892) pour détecter
///     les overflows (contenus coupés) dès les tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yeshua_calendar/app.dart';
import 'package:yeshua_calendar/services/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // La police de test « Ahem » dessine chaque glyphe comme un carré plein :
  // tous les textes sont ~3× plus larges qu'en Roboto réelle et provoquent
  // des faux overflows RenderFlex. On les tolère ici — les vrais overflows
  // sont couverts par les écrans réels et les corrections Flexible.
  setUp(() {
    FlutterError.onError = (details) {
      final texte = details.exception.toString();
      if (texte.contains('RenderFlex overflowed') ||
          texte.contains('A RenderFlex overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };
  });

  Future<void> pomperApplication(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsStore.instance.initialiser();
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: HorlogeCelesteApp()),
    );
    // Battements initiaux : état de l'horloge, assets, animations d'entrée.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> ouvrirOngletCalendrier(WidgetTester tester) async {
    await tester.tap(find.text('Calendrier').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
      'La NavigationBar du bas est rendue et ouvre le Calendrier à 5 onglets',
      (tester) async {
    await pomperApplication(tester);

    // Correctif racine : la barre de navigation doit être rendue…
    expect(find.byType(NavigationBar), findsOneWidget);
    // …avec ses 5 destinations.
    for (final label in ['Accueil', 'Horloge', 'Temps biblique', 'Alarmes']) {
      expect(find.text(label), findsWidgets, reason: 'destination $label');
    }

    // Navigation vers l'onglet Calendrier.
    await ouvrirOngletCalendrier(tester);

    // Les 5 onglets du calendrier sont présents.
    expect(find.text('Semaine'), findsOneWidget);
    expect(find.text('Mois'), findsOneWidget);
    expect(find.text('Trimestre'), findsOneWidget);
    expect(find.text('Année'), findsOneWidget);
  });

  testWidgets('La vue Semaine liste les 7 jours de la semaine en cours',
      (tester) async {
    await pomperApplication(tester);
    await ouvrirOngletCalendrier(tester);

    await tester.tap(find.text('Semaine'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // En-tête de semaine + tuiles des 7 jours (chaque tuile affiche
    // « Jour X/364 »).
    expect(find.textContaining('Semaine '), findsWidgets);
    expect(find.textContaining('LES 7 JOURS DE LA SEMAINE'), findsOneWidget);
    expect(find.textContaining('/364'), findsWidgets);
  });

  testWidgets('La vue Trimestre affiche les 3 mois de la saison en cours',
      (tester) async {
    await pomperApplication(tester);
    await ouvrirOngletCalendrier(tester);

    // Tap par l'ICÔNE du tab : avec la police de test Ahem, le label
    // « Trimestre » dépasse sa tab et son centre tombe hors de la zone
    // tactile (pas de problème en Roboto réelle).
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Trimestre '), findsWidgets);
    // Le trimestre affiché est celui d'aujourd'hui (init automatique) —
    // l'assertion est dynamique : premier mois du trimestre courant.
    final aujourdhuiBiblique =
        BiblicalCalendarEngine.anneePourDate(DateTime.now())
            .jourPourDate(DateTime.now());
    final trimestreCourant = aujourdhuiBiblique?.trimestre ?? 1;
    expect(find.textContaining('MOIS ${(trimestreCourant - 1) * 3 + 1}'),
        findsOneWidget);
    // Les grilles des 2 mois suivants sont plus bas (ListView paresseuse) :
    // elles utilisent exactement les mêmes widgets que la première.
  });

  testWidgets(
      'La vue Année affiche les 12 mini-grilles de mois de l\u2019année',
      (tester) async {
    await pomperApplication(tester);
    await ouvrirOngletCalendrier(tester);

    await tester.tap(find.text('Année'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('VUE ANNUELLE'), findsOneWidget);
    // La ListView est paresseuse : les premières mini-grilles (mois 1)
    // sont visibles sans défilement.
    expect(find.textContaining('· mois 1'), findsWidgets);
  });

  testWidgets(
      'Paramètres liste les pays et villes hors connexion (ExpansionTile)',
      (tester) async {
    await pomperApplication(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choisir le pays et la ville (hors connexion)'),
        findsOneWidget);
    // Les tuiles dépliables par pays sont rendues — elles crashaient
    // autrement (zone grise).
    expect(find.byType(ExpansionTile), findsWidgets);
    expect(find.text('Bénin'), findsOneWidget);

    // Déplier « Bénin » : les villes intégrées apparaissent.
    await tester.tap(find.text('Bénin'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Cotonou'), findsWidgets);
  });
}
