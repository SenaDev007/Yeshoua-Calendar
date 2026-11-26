/// ⭐ TIME ENGINE — Module A du cahier des charges (§12).
///
/// Heure locale, fuseau horaire, actualisation et DÉTECTION DES RUPTURES
/// TEMPORELLES (§13/§14) : modification manuelle de l'heure système,
/// changement de fuseau, redémarrage, mise en veille prolongée, reprise
/// après plusieurs heures. Le moteur resynchronise toujours à partir de
/// l'heure réelle — jamais à partir d'anciens états en mémoire.
library;

import 'models.dart';

class TimeEngine {
  TimeEngine._();

  /// Heure locale réelle (toujours l'horloge du système).
  static DateTime maintenant() => DateTime.now();

  /// Fuseau horaire IANA approximé depuis l'offset local et le nom du
  /// système (ex. « Africa/Porto-Novo » si le système le fournit).
  ///
  /// Sur mobile, le plugin `flutter_timezone` fournit le nom IANA exact ;
  /// ici on retombe sur le nom/offset système si indisponible.
  static String fuseauCourant({String? iana}) {
    if (iana != null && iana.isNotEmpty) return iana;
    final now = DateTime.now();
    final nom = now.timeZoneName;
    final offset = now.timeZoneOffset;
    final signe = offset.isNegative ? '-' : '+';
    final h = offset.inHours.abs().toString().padLeft(2, '0');
    final mn = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return nom.length <= 3 && nom.contains('UTC')
        ? 'UTC$signe$h:$mn'
        : '${nom}_$signe$h:$mn';
  }

  /// Détecte un décalage anormal entre deux « battements » du moteur :
  /// saut en avant ou en arrière, changement de fuseau, heure corrigée.
  ///
  /// Utilisé à chaque reprise de l'application (§13) pour forcer un
  /// recalcul complet de l'état temporel.
  static RuptureTemporelle? detecterRupture({
    required EtatTemporel? dernierEtat,
    DateTime? maintenant,
  }) {
    final now = maintenant ?? DateTime.now();
    final etat = dernierEtat;
    if (etat == null) return null;

    final fuseauActuel = fuseauCourant();
    final fuseauChange = fuseauActuel != etat.fuseau;

    final ecart = now.difference(etat.horodatage);
    // Un écart de plus de 5 minutes entre deux battements prévus à moins
    // de 2 minutes d'intervalle signale une interruption / correction —
    // y compris une reprise après plusieurs heures (§13).
    final sautDetecte = ecart.abs() > const Duration(minutes: 5);

    final coucherRecalculeChange = etat.prochainCoucherCalcule != null &&
        etat.prochainCoucherCalcule!.isBefore(now);

    if (fuseauChange) {
      return RuptureTemporelle('Changement de fuseau horaire détecté '
          '(${etat.fuseau} → $fuseauActuel)');
    }
    if (coucherRecalculeChange) {
      return RuptureTemporelle(
          'Le prochain coucher du soleil conservé est dépassé — recalcul');
    }
    if (sautDetecte) {
      return RuptureTemporelle(
          'Saut temporel détecté (${ecart.inMinutes} min) — recalcul complet');
    }
    return null;
  }
}

/// Une rupture de continuité temporelle détectée (§13).
class RuptureTemporelle {
  final String motif;
  const RuptureTemporelle(this.motif);

  @override
  String toString() => 'RuptureTemporelle($motif)';
}
