/// ⭐ ÉCRAN ALARMES (§8) — les trois alarmes spirituelles :
/// RHEMA du matin (05 h 00), Préparation du soir (coucher − 5 min) et
/// RHEMA du soir (au coucher du soleil réel). Activation, message,
/// vibration, historique des notifications.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import '../../state/alarms_controller.dart';
import '../widgets/cartes.dart';

class AlarmesScreen extends ConsumerWidget {
  const AlarmesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etat = ref.watch(alarmsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CarteCeleste(
          enfant: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined,
                      size: 17, color: AppColors.orSolaire),
                  SizedBox(width: 8),
                  Text(
                    'Alarmes spirituelles',
                    style: TextStyle(
                      color: AppColors.ardoise,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Trois rendez-vous avec l\u2019Éternel dans la journée biblique. '
                'Le RHEMA du matin sonne à l\u2019heure que VOUS réglez ; les alarmes '
                'du soir suivent le coucher du soleil RÉEL de votre position '
                '— jamais une heure fixe. Elles fonctionnent même quand l\u2019application '
                'est fermée (dans les limites de votre système).',
                style: const TextStyle(
                  color: AppColors.grisSecondaire,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final alarme in etat.alarmes) ...[
          _carteAlarme(context, ref, alarme),
          const SizedBox(height: 10),
        ],
        TitreSection(
          'Historique des dernières notifications',
          icone: Icons.history,
        ),
        if (etat.historique.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Aucune notification enregistrée pour l\u2019instant.',
              style: TextStyle(
                color: AppColors.grisSecondaire.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            ),
          ),
        for (final h in etat.historique.take(10))
          CarteCeleste(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enfant: Row(
              children: [
                const Icon(Icons.alarm_on_rounded,
                    size: 17, color: AppColors.bleuCiel),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['titre'] ?? '',
                        style: const TextStyle(
                          color: AppColors.ardoise,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${h['instant'] != null ? _formatInstant(h['instant'] as String) : ''} — ${h['corps'] ?? ''}',
                        style: TextStyle(
                          color: AppColors.grisSecondaire.withValues(alpha: 0.9),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _carteAlarme(BuildContext context, WidgetRef ref, AlarmeAffichee alarme) {
    final couleur = AppColors.depuisHex(alarme.couleurHex);
    final controleur = TextEditingController(text: alarme.prefs.message);

    return CarteCeleste(
      bordure: alarme.prefs.activee
          ? couleur.withValues(alpha: 0.45)
          : null,
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: couleur.withValues(alpha: 0.12),
                  border: Border.all(color: couleur.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  switch (alarme.type) {
                    TypeAlarme.rhemaMatin => Icons.wb_sunny_outlined,
                    TypeAlarme.preparationSoir => Icons.hourglass_top_outlined,
                    TypeAlarme.rhemaSoir => Icons.nightlight_outlined,
                  },
                  color: couleur,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarme.nom,
                      style: const TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      alarme.sousTitre,
                      style: const TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: alarme.prefs.activee,
                onChanged: (v) =>
                    ref.read(alarmsProvider.notifier).basculer(alarme, v),
                activeColor: couleur,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Prochain déclenchement calculé dynamiquement (§8).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alarme.prefs.activee
                  ? couleur.withValues(alpha: 0.07)
                  : AppColors.ardoisePastel.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: alarme.prefs.activee ? couleur : AppColors.grisSecondaire,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    alarme.prefs.activee && alarme.prochainInstant != null
                        ? 'Prochain déclenchement : '
                            '${dateLongueFrancais(alarme.prochainInstant!)} à '
                            '${heureCivilFormat(alarme.prochainInstant!)}'
                        : alarme.prefs.activee
                            ? 'Déclenchement calculé après le prochain coucher du soleil.'
                            : 'Alarme désactivée.',
                    style: TextStyle(
                      color: alarme.prefs.activee
                          ? AppColors.ardoise
                          : AppColors.grisSecondaire,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Horaire réglable (§8.4) : le RHEMA du matin sonne à l'heure
          //    choisie ; la Préparation du soir se règle en minutes avant
          //    le coucher ; le RHEMA du soir reste ancré au coucher réel
          //    (norme biblique — jamais une heure civile figée).
          if (alarme.type == TypeAlarme.rhemaMatin)
            _ligneHeure(context, ref, alarme, couleur),
          if (alarme.type == TypeAlarme.preparationSoir)
            _ligneDecalage(context, ref, alarme, couleur),
          if (alarme.type == TypeAlarme.rhemaSoir)
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                'Ancrée au coucher du soleil réel : la norme biblique ne '
                'fixe pas cette alarme à une heure civile.',
                style: TextStyle(
                    color: AppColors.grisSecondaire, fontSize: 11),
              ),
            ),
          if (alarme.type != TypeAlarme.rhemaSoir) const SizedBox(height: 6),
          // Message personnalisé (§8.4).
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controleur,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText: 'Message personnalisé…',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (v) {
                    ref
                        .read(alarmsProvider.notifier)
                        .changerMessage(alarme, v.trim());
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Vibration (§8.4).
              IconButton(
                tooltip: alarme.prefs.vibration ? 'Vibration activée' : 'Vibration désactivée',
                icon: Icon(
                  alarme.prefs.vibration
                      ? Icons.vibration
                      : Icons.phonelink_erase_outlined,
                  color: alarme.prefs.vibration ? couleur : AppColors.grisSecondaire,
                  size: 20,
                ),
                onPressed: () => ref
                    .read(alarmsProvider.notifier)
                    .changerPreferences(alarme, vibration: !alarme.prefs.vibration),
              ),
              // Son (§8.4) — menu de choix.
              PopupMenuButton<String>(
                tooltip: 'Son de l\u2019alarme',
                icon: Icon(
                  Icons.music_note_outlined,
                  color: alarme.prefs.son != 'silence' ? couleur : AppColors.grisSecondaire,
                  size: 20,
                ),
                onSelected: (son) => ref
                    .read(alarmsProvider.notifier)
                    .changerPreferences(alarme, son: son),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'shofar', child: Text('Shofar')),
                  PopupMenuItem(value: 'cloche', child: Text('Cloche')),
                  PopupMenuItem(value: 'harpe', child: Text('Harpe')),
                  PopupMenuItem(value: 'silence', child: Text('Silence (vibration seule)')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ligne « Heure de sonnerie » du RHEMA du matin — ouvre le sélecteur
  /// d'heure natif et reprogramme les alarmes (§8.4).
  Widget _ligneHeure(BuildContext context, WidgetRef ref,
      AlarmeAffichee alarme, Color couleur) =>
      Row(
        children: [
          Icon(Icons.alarm_outlined, size: 16, color: couleur),
          const SizedBox(width: 7),
          const Text('Heure de sonnerie',
              style: TextStyle(
                  color: AppColors.grisSecondaire, fontSize: 12)),
          const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final choisi = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: alarme.prefs.heure, minute: alarme.prefs.minute),
                helpText: 'Heure du RHEMA du matin',
              );
              if (choisi != null) {
                await ref
                    .read(alarmsProvider.notifier)
                    .changerHeure(alarme, choisi.hour, choisi.minute);
              }
            },
            icon: Icon(Icons.edit_outlined, size: 14, color: couleur),
            label: Text(
              '${_2(alarme.prefs.heure)} h ${_2(alarme.prefs.minute)}',
              style: const TextStyle(
                color: AppColors.ardoise,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );

  /// Ligne « Avant le coucher » de la Préparation du soir — choix du
  /// décalage en minutes, reprogrammation immédiate (§8.4).
  Widget _ligneDecalage(BuildContext context, WidgetRef ref,
      AlarmeAffichee alarme, Color couleur) =>
      Row(
        children: [
          Icon(Icons.hourglass_bottom, size: 16, color: couleur),
          const SizedBox(width: 7),
          const Text('Avant le coucher du soleil',
              style: TextStyle(
                  color: AppColors.grisSecondaire, fontSize: 12)),
          const Spacer(),
          PopupMenuButton<int>(
            tooltip: 'Minutes avant le coucher du soleil',
            onSelected: (m) => ref
                .read(alarmsProvider.notifier)
                .changerMinutesAvant(alarme, m),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('1 minute')),
              PopupMenuItem(value: 3, child: Text('3 minutes')),
              PopupMenuItem(value: 5, child: Text('5 minutes')),
              PopupMenuItem(value: 10, child: Text('10 minutes')),
              PopupMenuItem(value: 15, child: Text('15 minutes')),
              PopupMenuItem(value: 20, child: Text('20 minutes')),
              PopupMenuItem(value: 30, child: Text('30 minutes')),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${alarme.prefs.minutesAvant} min',
                      style: const TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      )),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 15, color: couleur),
                ],
              ),
            ),
          ),
        ],
      );

  String _formatInstant(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${_2(d.day)}/${_2(d.month)} à ${heureCivilFormat(d)}';
  }

  String _2(int n) => n.toString().padLeft(2, '0');
}
