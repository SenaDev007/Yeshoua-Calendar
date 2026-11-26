/// ⭐ ÉCRAN PARAMÈTRES (§9, §10.2) — localisation automatique/manuelle,
/// fuseau horaire, informations sur le calendrier. Le logo Zman est
/// respecté (§10.2) : aucun remplacement, déclinaison d'icône seulement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../state/settings_controller.dart';
import '../../state/zman_controller.dart';
import '../widgets/cartes.dart';

class ParametresScreen extends ConsumerWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final zman = ref.watch(zmanProvider);
    final villesParPays = <String, List<VilleIntegree>>{};
    for (final v in villesIntegreees) {
      villesParPays.putIfAbsent(v.pays, () => []).add(v);
    }

    return Scaffold(
      backgroundColor: AppColors.ivoire,
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ── Localisation (§9) ──
          TitreSection('Localisation', icone: Icons.place_outlined),
          CarteZman(
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bleuCiel.withValues(alpha: 0.10),
                        border: Border.all(
                            color: AppColors.bleuCiel.withValues(alpha: 0.45)),
                      ),
                      child: const Icon(Icons.gps_fixed,
                          color: AppColors.bleuCiel, size: 21),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.position.libelle,
                            style: const TextStyle(
                              color: AppColors.ardoise,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${settings.position.latitude.toStringAsFixed(4)}°, '
                            '${settings.position.longitude.toStringAsFixed(4)}° · '
                            '${settings.position.fuseau}',
                            style: const TextStyle(
                              color: AppColors.grisSecondaire,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    settings.chargement
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : IconButton(
                            tooltip: 'Localiser automatiquement',
                            icon: const Icon(Icons.my_location,
                                color: AppColors.bleuCiel),
                            onPressed: () => ref
                                .read(settingsProvider.notifier)
                                .localiserAutomatiquement(),
                          ),
                  ],
                ),
                if (settings.message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    settings.message!,
                    style: TextStyle(
                      color: AppColors.bleuCielFonce,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'La localisation est ponctuelle : demandée uniquement quand '
                  'vous appuyez sur le bouton GPS — jamais en arrière-plan. '
                  'Après un changement de position, tous les horaires solaires, '
                  'veilles, heures saisonnières et alarmes du soir sont recalculés.',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                const Divider(height: 24),
                // Choix manuel du pays/ville (§9.2).
                Text(
                  'Choisir le pays et la ville (hors connexion)',
                  style: const TextStyle(
                    color: AppColors.ardoise,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  for (final entry in villesParPays.entries)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      dense: true,
                      iconColor: AppColors.bleuCiel,
                      collapsedIconColor: AppColors.grisSecondaire,
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppColors.ardoise,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      children: [
                        for (final ville in entry.value)
                          ListTile(
                            dense: true,
                            leading: Icon(
                              settings.position.libelle ==
                                      '${ville.ville}, ${ville.pays}'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: AppColors.bleuCiel,
                            ),
                            title: Text(ville.ville,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                              '${ville.latitude.toStringAsFixed(2)}, ${ville.longitude.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .choisirVille(ville);
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Position manuelle libre ──
          TitreSection('Position manuelle', icone: Icons.edit_location_alt_outlined),
          const _CartePositionManuelle(),
          const SizedBox(height: 12),

          // ── État du moteur (§13) ──
          TitreSection('Moteur de temps', icone: Icons.engineering_outlined),
          CarteZman(
            enfant: Column(
              children: [
                _ligne('Horaires solaires calculés',
                    zman.calculSolaireIndisponible ? 'indisponibles (polaire)' : 'locaux, hors connexion'),
                _ligne('Dernière transition de jour',
                    zman.cleTransition ?? '—'),
                _ligne('Année biblique en cours',
                    zman.anneeBiblique?.libelle ?? '—'),
                _ligne('Jour de l\u2019année',
                    zman.jourBiblique != null
                        ? '${zman.jourBiblique!.jourDeAnnee} / 364'
                        : '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── À propos (§10.2 : identité conservée) ──
          TitreSection('À propos', icone: Icons.info_outline),
          CarteZman(
            enfant: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bleuCielNuit,
                        border: Border.all(
                            color: AppColors.orSolaire, width: 2.4),
                      ),
                      child: const Icon(Icons.schedule,
                          size: 28, color: AppColors.orSolaire),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '${AppConfig.nomApp} · ${AppConfig.hebreuApp}',
                          style: TextStyle(
                            color: AppColors.ardoise,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          AppConfig.signature,
                          style: TextStyle(
                            color: AppColors.grisSecondaire,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Calendrier biblique de 364 jours — mêmes règles que le '
                  'calendrier du Mouvement Christ Libère (52 semaines exactes, '
                  '1ᵉʳ Aviv un mercredi à l\u2019équinoxe de mars, 12 mois de '
                  '30/31 jours, 10 fêtes de l\u2019Éternel, Shabbats hebdomadaires). '
                  'Parité vérifiée automatiquement sur les données réelles.',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligne(String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.grisSecondaire, fontSize: 12.5),
            ),
            Text(
              valeur,
              style: const TextStyle(
                color: AppColors.ardoise,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
}

/// Carte de saisie d'une position manuelle (lat/lon).
class _CartePositionManuelle extends ConsumerStatefulWidget {
  const _CartePositionManuelle();

  @override
  ConsumerState<_CartePositionManuelle> createState() =>
      _CartePositionManuelleState();
}

class _CartePositionManuelleState extends ConsumerState<_CartePositionManuelle> {
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CarteZman(
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saisissez une latitude et une longitude si votre ville n\u2019est '
            'pas dans la liste.',
            style: TextStyle(
              color: AppColors.grisSecondaire.withValues(alpha: 0.9),
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lat,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lon,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final lat = double.tryParse(_lat.text.replaceAll(',', '.'));
                  final lon = double.tryParse(_lon.text.replaceAll(',', '.'));
                  if (lat == null ||
                      lon == null ||
                      lat < -90 ||
                      lat > 90 ||
                      lon < -180 ||
                      lon > 180) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Latitude/longitude invalides.'),
                    ));
                    return;
                  }
                  ref
                      .read(settingsProvider.notifier)
                      .positionManuelle(lat, lon, 'Position manuelle');
                  Navigator.of(context).pop();
                },
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
