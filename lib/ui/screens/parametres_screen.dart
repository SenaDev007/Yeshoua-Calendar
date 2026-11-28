/// ⭐ ÉCRAN PARAMÈTRES (§9, §10.2) — localisation automatique/manuelle,
/// fuseau horaire, informations sur le calendrier. Le logo Horloge Céleste est
/// respecté (§10.2) : aucun remplacement, déclinaison d'icône seulement.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../state/settings_controller.dart';
import '../../state/horloge_controller.dart';
import '../widgets/cartes.dart';

class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends ConsumerState<ParametresScreen> {
  /// Recherche de pays/ville — la liste couvre désormais TOUS les pays
  /// (203 États et territoires, hors connexion), un filtre est indispensable.
  final _recherche = TextEditingController();
  String _filtre = '';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final etat = ref.watch(horlogeProvider);
    final requete = _filtre.trim().toLowerCase();
    final villesFiltrees = requete.isEmpty
        ? villesIntegreees
        : villesIntegreees
            .where((v) =>
                v.pays.toLowerCase().contains(requete) ||
                v.ville.toLowerCase().contains(requete))
            .toList();
    final villesParPays = <String, List<VilleIntegree>>{};
    for (final v in villesFiltrees) {
      villesParPays.putIfAbsent(v.pays, () => []).add(v);
    }
    final paysTries = villesParPays.keys.toList()..sort();

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
          CarteCeleste(
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
                // RECHERCHE — indispensable avec les ~200 pays intégrés.
                TextField(
                  controller: _recherche,
                  onChanged: (v) => setState(() => _filtre = v),
                  decoration: InputDecoration(
                    hintText:
                        'Rechercher un pays ou une ville (ex. : Bénin, Paris)…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 19),
                    suffixIcon: _filtre.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _recherche.clear();
                              setState(() => _filtre = '');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${villesFiltrees.length} villes · ${villesParPays.length} pays '
                  '(tous intégrés hors connexion)',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
                for (final pays in paysTries)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    iconColor: AppColors.bleuCiel,
                    collapsedIconColor: AppColors.grisSecondaire,
                    title: Text(
                      pays,
                      style: const TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    children: [
                      for (final ville in villesParPays[pays]!)
                        // Material transparent requis : le ListTile est
                        // posé sur un Container coloré — sans lui, une
                        // assertion Flutter casse le rendu (zone grise).
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
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
                        ),
                    ],
                  ),
                if (villesParPays.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Aucun pays ne correspond à cette recherche.',
                      style: TextStyle(
                          color: AppColors.grisSecondaire, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Affichage (§7) — MODE HÉBRAÏQUE ──
          TitreSection('Affichage', icone: Icons.style_outlined),
          CarteCeleste(
            enfant: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orSolaire.withValues(alpha: 0.12),
                    border: Border.all(
                        color: AppColors.orSolaire.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.translate_rounded,
                      color: AppColors.orFonce, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode hébraïque',
                        style: TextStyle(
                          color: AppColors.ardoise,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Les jours s\u2019affichent en translittération : '
                        'Yom Ehad (jour 1), Yom Sheni… jusqu\u2019à '
                        'Yom Shabbat (7e jour).',
                        style: TextStyle(
                          color:
                              AppColors.grisSecondaire.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.modeHebreu,
                  activeColor: AppColors.orSolaire,
                  activeTrackColor: AppColors.orSolaire.withValues(alpha: 0.55),
                  inactiveThumbColor: AppColors.blanc,
                  inactiveTrackColor: AppColors.grisSecondaire,
                  onChanged: (v) =>
                      ref.read(settingsProvider.notifier).basculerModeHebreu(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Position manuelle libre ──
          TitreSection('Position manuelle',
              icone: Icons.edit_location_alt_outlined),
          const _CartePositionManuelle(),
          const SizedBox(height: 12),

          // ── État du moteur (§13) ──
          TitreSection('Moteur de temps', icone: Icons.engineering_outlined),
          CarteCeleste(
            enfant: Column(
              children: [
                _ligne(
                    'Horaires solaires calculés',
                    etat.calculSolaireIndisponible
                        ? 'indisponibles (polaire)'
                        : 'locaux, hors connexion'),
                _ligne(
                    'Dernière transition de jour', etat.cleTransition ?? '—'),
                _ligne('Année biblique en cours',
                    etat.anneeBiblique?.libelle ?? '—'),
                _ligne(
                    'Jour de l\u2019année',
                    etat.jourBiblique != null
                        ? '${etat.jourBiblique!.jourDeAnnee} / 364'
                        : '—'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── À propos (§10.2 : identité conservée) ──
          TitreSection('À propos', icone: Icons.info_outline),
          CarteCeleste(
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
                        border:
                            Border.all(color: AppColors.orSolaire, width: 2.4),
                      ),
                      // Logo Horloge Céleste (placeholder — logo officiel
                      // à intégrer quand il sera fourni).
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo-horloge-celeste.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '${AppConfig.nomApp}',
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
                  'Le calendrier de l\u2019Éternel est un système calendaire '
                  'solaire de 364 jours décrit dans le Livre d\u2019Hénoch, le '
                  'Livre des Jubilés et les Manuscrits de Qumrân. Il est '
                  'parfaitement divisible par sept, créant exactement '
                  '52 semaines par an. Chaque année commence un mercredi et '
                  'maintient une structure immuable, contrairement au '
                  'calendrier lunaire traditionnel.',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '© 2026 Horloge Céleste — YEHI OR Tech',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
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
              style: const TextStyle(
                  color: AppColors.grisSecondaire, fontSize: 12.5),
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

class _CartePositionManuelleState
    extends ConsumerState<_CartePositionManuelle> {
  final _lat = TextEditingController();
  final _lon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CarteCeleste(
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
