/// ⭐ TEST DE PARITÉ — la preuve de la REPRODUCTION EXACTE.
///
/// Compare le moteur Dart aux données RÉELLES du backend « Mouvement
/// Christ Libère » (fichiers golden téléchargés de
/// `/api/calendrier-biblique/{annee}`) pour 7 années échantillonnées :
/// 1900, 2025, 2026, 2027, 2028 (semaine intercalaire), 2032 (semaine
/// intercalaire) et 2100 — soit 2 548 jours et 70 fêtes comparés champ
/// par champ.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:zman_engine/zman_engine.dart';

const goldens = [
  '1900', '2025', '2026', '2027', '2028', '2032', '2100',
];

DateTime _dateAPI(String iso) {
  final d = DateTime.parse(iso);
  return DateTime(d.year, d.month, d.day);
}

void main() {
  final dossierGolden = Directory('test/golden');

  test('les fichiers golden du backend sont présents', () {
    for (final a in goldens) {
      expect(
        File('${dossierGolden.path}/annee-$a.json').existsSync(),
        isTrue,
        reason: 'golden manquant : annee-$a.json',
      );
    }
  });

  for (final anneeStr in goldens) {
    group('Parité année $anneeStr', () {
      final anneeAttendue =
          jsonDecode(File('${dossierGolden.path}/annee-$anneeStr.json')
                  .readAsStringSync()) as Map<String, dynamic>;
      final annee = BiblicalCalendarEngine.construireAnnee(int.parse(anneeStr));

      test('en-tête de l\u2019année (début, fin, nombre de jours, libellé)', () {
        expect(annee.annee, anneeAttendue['annee']);
        expect(annee.libelle, anneeAttendue['libelle']);
        expect(annee.nombreJours, anneeAttendue['nombreJours']);
        expect(annee.nombreJours, 364);
        expect(
          _dateAPI(anneeAttendue['debut'] as String),
          DateTime(annee.debut.year, annee.debut.month, annee.debut.day),
        );
        expect(
          _dateAPI(anneeAttendue['fin'] as String),
          DateTime(annee.fin.year, annee.fin.month, annee.fin.day),
        );
      });

      test('les 364 jours — champ par champ', () {
        final joursAttendus =
            (anneeAttendue['jours'] as List).cast<Map<String, dynamic>>();
        expect(annee.jours.length, joursAttendus.length);
        var ecarts = <String>[];
        for (var i = 0; i < joursAttendus.length; i++) {
          final a = joursAttendus[i];
          final j = annee.jours[i];
          if (j.jourDeAnnee != a['jourDeAnnee']) {
            ecarts.add('jour ${i + 1}: jourDeAnnee ${j.jourDeAnnee} ≠ ${a['jourDeAnnee']}');
          }
          if (j.mois != a['mois']) ecarts.add('jour ${i + 1}: mois ${j.mois} ≠ ${a['mois']}');
          if (j.nomMois != a['nomMois']) {
            ecarts.add('jour ${i + 1}: nomMois ${j.nomMois} ≠ ${a['nomMois']}');
          }
          if (j.jourDuMois != a['jourDuMois']) {
            ecarts.add('jour ${i + 1}: jourDuMois ${j.jourDuMois} ≠ ${a['jourDuMois']}');
          }
          if (j.jourDeSemaine != a['jourDeSemaine']) {
            ecarts.add('jour ${i + 1}: jourDeSemaine ${j.jourDeSemaine} ≠ ${a['jourDeSemaine']}');
          }
          if (j.nomJourSemaine != a['nomJourSemaine']) {
            ecarts.add('jour ${i + 1}: nomJourSemaine ${j.nomJourSemaine} ≠ ${a['nomJourSemaine']}');
          }
          if (j.estShabbat != a['estShabbat']) {
            ecarts.add('jour ${i + 1}: estShabbat ${j.estShabbat} ≠ ${a['estShabbat']}');
          }
          if (j.trimestre != a['trimestre']) {
            ecarts.add('jour ${i + 1}: trimestre ${j.trimestre} ≠ ${a['trimestre']}');
          }
          final gregAPI = _dateAPI(a['dateGregorienne'] as String);
          if (j.dateGregorienne.year != gregAPI.year ||
              j.dateGregorienne.month != gregAPI.month ||
              j.dateGregorienne.day != gregAPI.day) {
            ecarts.add(
                'jour ${i + 1}: date ${j.dateGregorienne} ≠ $gregAPI');
          }
        }
        expect(ecarts, isEmpty, reason: 'écarts de jours : ${ecarts.take(10)}');
      });

      test('les 10 fêtes — champ par champ', () {
        final fetesAttendues =
            (anneeAttendue['fetes'] as List).cast<Map<String, dynamic>>();
        expect(annee.fetes.length, fetesAttendues.length,
            reason: 'nombre de fêtes');
        for (var i = 0; i < fetesAttendues.length; i++) {
          final a = fetesAttendues[i];
          final f = annee.fetes[i];
          expect(f.id, a['id'], reason: 'fête $i id');
          expect(f.nomFr, a['nomFr'], reason: 'fête $i nomFr');
          expect(f.nomHebrew, a['nomHebrew'], reason: 'fête $i hébreu');
          expect(f.referenceEcritures, a['referenceEcritures'],
              reason: 'fête $i référence');
          expect(f.description, a['description'], reason: 'fête $i description');
          expect(f.categorie, a['categorie'], reason: 'fête $i catégorie');
          expect(f.couleur, a['couleur'], reason: 'fête $i couleur');
          expect(f.travailInterdit, a['travailInterdit'],
              reason: 'fête $i travailInterdit');
          expect(f.dureeJours, a['dureeJours'], reason: 'fête $i durée');
          expect(f.dateBiblique, a['dateBiblique'], reason: 'fête $i dateBiblique');
          final gregAPI = _dateAPI(a['dateGregorienne'] as String);
          expect(
            DateTime(f.dateGregorienne.year, f.dateGregorienne.month,
                f.dateGregorienne.day),
            gregAPI,
            reason: 'fête $i (${f.nomFr}) date grégorienne',
          );
          expect(f.jourDeSemaine, a['jourDeSemaine'],
              reason: 'fête $i jour de semaine');
        }
      });
    });
  }

  group('Règles d\u2019ancrage (échantillon étendu vérifié contre l\u2019API)', () {
    // Débuts deannée vérifiés contre l'API pour 26 années (audit).
    const debutsAPI = {
      2020: '2020-03-18', 2021: '2021-03-17', 2022: '2022-03-23',
      2023: '2023-03-22', 2024: '2024-03-20', 2025: '2025-03-19',
      2026: '2026-03-18', 2027: '2027-03-17', 2028: '2028-03-22',
      2029: '2029-03-21', 2030: '2030-03-20', 2031: '2031-03-19',
      2032: '2032-03-17', 2033: '2033-03-23', 2034: '2034-03-22',
      2035: '2035-03-21', 2040: '2040-03-21', 2050: '2050-03-23',
      2060: '2060-03-17', 2070: '2070-03-19', 2080: '2080-03-20',
      2090: '2090-03-22', 1950: '1950-03-22', 1990: '1990-03-21',
    };
    for (final entry in debutsAPI.entries) {
      test('1ᵉʳ Aviv ${entry.key} = ${entry.value} (mercredi)', () {
        final debut = BiblicalCalendarEngine.debutAnneeBiblique(entry.key);
        expect(debut.weekday, DateTime.wednesday,
            reason: 'l\u2019année commence toujours un mercredi');
        final attendu = DateTime.parse(entry.value);
        expect(
            DateTime(debut.year, debut.month, debut.day),
            DateTime(attendu.year, attendu.month, attendu.day),
            reason: 'début de l\u2019année ${entry.key}');
      });
    }
  });
}
