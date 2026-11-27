/// Test d'import du moteur depuis l'application Flutter :
/// vérifie que le package horloge_celeste_engine est bien résolu et que les règles
/// clés restent intactes côté app (miroir léger des tests du moteur).
///
/// ⚠️ Nécessite le SDK Flutter : `flutter test`.
import 'package:flutter_test/flutter_test.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

void main() {
  test('le calendrier 364 jours est intégré et conforme', () {
    final annee = BiblicalCalendarEngine.construireAnnee(2026);
    expect(annee.jours.length, 364);
    expect(annee.debut.weekday, DateTime.wednesday);
    expect(annee.jours.where((j) => j.estShabbat).length, 52);
    expect(annee.fetes.length, 10);
  });

  test('les alarmes planifiées respectent les règles (§8)', () {
    final matin = AlarmPlanner.prochainRhemaMatin(DateTime(2026, 3, 20, 6, 30));
    expect(matin.day, 21);
    expect(matin.hour, 5);
  });
}
