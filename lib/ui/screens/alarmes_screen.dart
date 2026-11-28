/// ⭐ ÉCRAN ALARMES (§8, §8.5) — les trois alarmes spirituelles :
/// RHEMA du matin (heure réglable), Préparation du soir (coucher − n min)
/// et RHEMA du soir (au coucher du soleil réel), PLUS les alarmes
/// personnalisées à heure et tâche libres.
///
/// Corrections apportées (demande utilisateur) :
///   • interrupteurs NETTEMENT visibles (piste et pouce colorés, même à
///     l'état inactif) — plus de bleu ciel confondu avec le fond ;
///   • chaque changement (bascule, heure, son, message) met l'interface à
///     jour IMMÉDIATEMENT — plus besoin de fermer et rouvrir l'app ;
///   • taper sur un mode de sonnerie (shofar / cloche / harpe) l'ENTEND
///     aussitôt ; « silence » et l'icône vibration PROVOQUENT une vraie
///     vibration, perceptible même téléphone en silencieux ;
///   • bouton « Tester la sonnerie » : déclenche une notification réelle
///     avec le son choisi (vérification instantanée de la chaîne complète) ;
///   • création d'alarmes PERSONNALISÉES pour n'importe quelle heure et
///     n'importe quelle tâche ;
///   • bandeau d'avertissement si les alarmes exactes ne sont pas
///     autorisées (Android 12+) avec ouverture directe des réglages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horloge_celeste_engine/horloge_celeste_engine.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/formatters.dart';
import '../../services/apercu_sonore.dart';
import '../../services/notification_service.dart';
import '../../state/alarms_controller.dart';
import '../widgets/cartes.dart';

class AlarmesScreen extends ConsumerStatefulWidget {
  const AlarmesScreen({super.key});

  @override
  ConsumerState<AlarmesScreen> createState() => _AlarmesScreenState();
}

class _AlarmesScreenState extends ConsumerState<AlarmesScreen> {
  bool _exactAutorisees = true;

  @override
  void initState() {
    super.initState();
    _exactAutorisees = NotificationService.instance.exactAlarmsAutorisees;
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Text(
                      'Alarmes spirituelles',
                      style: TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Trois rendez-vous avec l\u2019Éternel dans la journée biblique '
                '+ vos alarmes personnalisées. Les alarmes du soir suivent le '
                'coucher du soleil RÉEL de votre position — jamais une heure '
                'fixe. Elles fonctionnent même quand l\u2019application est '
                'fermée, et vibrent même téléphone en silencieux.',
                style: const TextStyle(
                  color: AppColors.grisSecondaire,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              // ── Tests immédiats : la chaîne de sonnerie complète ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.volume_up_outlined, size: 17),
                      label: const Text('Tester la sonnerie',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bleuCielFonce,
                        side: BorderSide(
                            color: AppColors.bleuCiel.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        await NotificationService.instance
                            .testerSonnerie(son: 'shofar', vibration: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Notification de test envoyée — le shofar '
                                  'retentit comme à l\u2019heure de l\u2019alarme.')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.vibration, size: 17),
                      label: const Text('Tester la vibration',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bleuCielFonce,
                        side: BorderSide(
                            color: AppColors.bleuCiel.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => ApercuiSonore.instance.vibrer(),
                    ),
                  ),
                ],
              ),
              // ── Bandeau : alarmes exactes non autorisées (Android 12+) ──
              if (!_exactAutorisees) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.orSolaire.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.orSolaire.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 17, color: AppColors.orFonce),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alarmes exactes non autorisées',
                              style: TextStyle(
                                color: AppColors.orFonce,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vos alarmes sonneront quand même, mais avec un léger '
                        'décalage possible. Pour une précision à la seconde, '
                        'autorisez « Alarmes et rappels » dans les réglages '
                        'système, et désactivez l\u2019optimisation de '
                        'batterie pour Horloge Céleste.',
                        style: TextStyle(
                          color:
                              AppColors.grisSecondaire.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.open_in_new, size: 15),
                          label: const Text('Autoriser'),
                          onPressed: () async {
                            await NotificationService.instance
                                .ouvrirParametresAlarmesExactes();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final alarme in etat.alarmes) ...[
          _carteAlarme(context, ref, alarme),
          const SizedBox(height: 10),
        ],

        // ── Alarmes PERSONNALISÉES (§8.5) ──
        TitreSection(
          'Alarmes personnalisées',
          icone: Icons.add_alarm_outlined,
        ),
        CarteCeleste(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          enfant: Row(
            children: [
              Expanded(
                child: Text(
                  'Créez une alarme pour n\u2019importe quelle heure et '
                  'n\u2019importe quelle tâche — elle sonnera chaque jour '
                  'à l\u2019heure choisie, application fermée comprise.',
                  style: TextStyle(
                    color: AppColors.grisSecondaire.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.bleuCiel,
                  foregroundColor: AppColors.blanc,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () => _dialogueNouvelleAlarme(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (etat.personnalisees.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Aucune alarme personnalisée pour l\u2019instant.',
              style: TextStyle(
                color: AppColors.grisSecondaire.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
        for (final p in etat.personnalisees) ...[
          _cartePersonnalisee(context, ref, p),
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
                          color:
                              AppColors.grisSecondaire.withValues(alpha: 0.9),
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

  // ── Carte d'un RHEMA ──────────────────────────────────────────────────

  Widget _carteAlarme(
      BuildContext context, WidgetRef ref, AlarmeAffichee alarme) {
    final couleur = AppColors.depuisHex(alarme.couleurHex);
    final controleur = TextEditingController(text: alarme.prefs.message);

    return CarteCeleste(
      bordure: alarme.prefs.activee ? couleur.withValues(alpha: 0.45) : null,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Interrupteur NETTEMENT visible (§8.4) : piste et
                  //    pouce colorés dès l'état inactif — plus de bleu
                  //    ciel confondu avec le fond.
                  Transform.scale(
                    scale: 1.1,
                    child: Switch(
                      value: alarme.prefs.activee,
                      onChanged: (v) =>
                          ref.read(alarmsProvider.notifier).basculer(alarme, v),
                      activeColor: couleur,
                      activeTrackColor: couleur.withValues(alpha: 0.55),
                      inactiveThumbColor: AppColors.blanc,
                      inactiveTrackColor: AppColors.grisSecondaire,
                    ),
                  ),
                  Text(
                    alarme.prefs.activee ? 'Activée' : 'Désactivée',
                    style: TextStyle(
                      color: alarme.prefs.activee
                          ? couleur
                          : AppColors.grisSecondaire,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
                  color:
                      alarme.prefs.activee ? couleur : AppColors.grisSecondaire,
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
                style: TextStyle(color: AppColors.grisSecondaire, fontSize: 11),
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
              // Vibration (§8.4) — un appui PROVOQUE la vibration réelle.
              IconButton(
                tooltip: alarme.prefs.vibration
                    ? 'Vibration activée — appuyez pour la sentir'
                    : 'Vibration désactivée — appuyez pour activer',
                icon: Icon(
                  alarme.prefs.vibration
                      ? Icons.vibration
                      : Icons.phonelink_erase_outlined,
                  color: alarme.prefs.vibration
                      ? couleur
                      : AppColors.grisSecondaire,
                  size: 20,
                ),
                onPressed: () async {
                  // Aperçu immédiat : l'utilisateur SENT la vibration.
                  await ApercuiSonore.instance.vibrer();
                  await ref.read(alarmsProvider.notifier).changerPreferences(
                      alarme,
                      vibration: !alarme.prefs.vibration);
                },
              ),
              // Son (§8.4) — menu de choix avec APERÇU immédiat.
              PopupMenuButton<String>(
                tooltip:
                    'Son de l\u2019alarme — choisissez pour l\u2019entendre',
                icon: Icon(
                  Icons.music_note_outlined,
                  color: alarme.prefs.son != 'silence'
                      ? couleur
                      : AppColors.grisSecondaire,
                  size: 20,
                ),
                onSelected: (son) async {
                  // APERÇU : entendre (ou sentir) avant de valider.
                  if (son == 'silence') {
                    await ApercuiSonore.instance.stopper();
                    await ApercuiSonore.instance.vibrer();
                  } else {
                    await ApercuiSonore.instance.jouer(son);
                  }
                  await ref
                      .read(alarmsProvider.notifier)
                      .changerPreferences(alarme, son: son);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'shofar', child: Text('Shofar')),
                  PopupMenuItem(value: 'cloche', child: Text('Cloche')),
                  PopupMenuItem(value: 'harpe', child: Text('Harpe')),
                  PopupMenuItem(
                      value: 'silence',
                      child: Text('Silence (vibration seule)')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Carte d'une alarme PERSONNALISÉE (§8.5) ───────────────────────────

  Widget _cartePersonnalisee(
      BuildContext context, WidgetRef ref, PersonnaliseeAffichee alarme) {
    const couleur = AppColors.bleuCielFonce;
    return CarteCeleste(
      bordure: alarme.prefs.activee
          ? couleur.withValues(alpha: 0.45)
          : AppColors.grisSecondaire.withValues(alpha: 0.3),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: couleur.withValues(alpha: 0.12),
                  border: Border.all(color: couleur.withValues(alpha: 0.5)),
                ),
                const Align(
                  child:
                      Icon(Icons.add_alarm_outlined, color: couleur, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarme.libelle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ardoise,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      'Quotidienne · '
                      '${_2(alarme.prefs.heure)} h ${_2(alarme.prefs.minute)}'
                      '${alarme.prochainInstant != null && alarme.prefs.activee ? ' — dans ${dureeFormat(alarme.prochainInstant!.difference(DateTime.now()))}' : ''}',
                      style: const TextStyle(
                        color: AppColors.grisSecondaire,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: alarme.prefs.activee,
                  onChanged: (v) => ref
                      .read(alarmsProvider.notifier)
                      .basculerPersonnalisee(alarme.id, v),
                  activeColor: couleur,
                  activeTrackColor: couleur.withValues(alpha: 0.55),
                  inactiveThumbColor: AppColors.blanc,
                  inactiveTrackColor: AppColors.grisSecondaire,
                ),
              ),
              IconButton(
                tooltip: 'Supprimer cette alarme',
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.grisSecondaire, size: 20),
                onPressed: () => ref
                    .read(alarmsProvider.notifier)
                    .supprimerPersonnalisee(alarme.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Heure réglable.
              TextButton.icon(
                onPressed: () async {
                  final choisi = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: alarme.prefs.heure, minute: alarme.prefs.minute),
                    helpText: 'Heure de l\u2019alarme',
                  );
                  if (choisi != null) {
                    await ref
                        .read(alarmsProvider.notifier)
                        .changerHeurePersonnalisee(
                            alarme.id, choisi.hour, choisi.minute);
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 14, color: couleur),
                label: Text(
                  '${_2(alarme.prefs.heure)} h ${_2(alarme.prefs.minute)}',
                  style: const TextStyle(
                    color: AppColors.ardoise,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              // Aperçu sonore direct.
              IconButton(
                tooltip: 'Écouter ce son',
                icon: const Icon(Icons.volume_up_outlined,
                    color: couleur, size: 19),
                onPressed: () => alarme.prefs.son == 'silence'
                    ? ApercuiSonore.instance.vibrer()
                    : ApercuiSonore.instance.jouer(alarme.prefs.son),
              ),
              Text(
                _nomSon(alarme.prefs.son),
                style: const TextStyle(
                    color: AppColors.grisSecondaire, fontSize: 11.5),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: alarme.prefs.vibration
                    ? 'Vibration activée — appuyez pour la sentir'
                    : 'Vibration désactivée',
                icon: Icon(
                  alarme.prefs.vibration
                      ? Icons.vibration
                      : Icons.phonelink_erase_outlined,
                  color: alarme.prefs.vibration
                      ? couleur
                      : AppColors.grisSecondaire,
                  size: 19,
                ),
                onPressed: () async {
                  // Sentir la vibration immédiatement puis basculer.
                  await ApercuiSonore.instance.vibrer();
                  await ref
                      .read(alarmsProvider.notifier)
                      .changerVibrationPersonnalisee(
                          alarme.id, !alarme.prefs.vibration);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _nomSon(String son) => switch (son) {
        'shofar' => 'Shofar',
        'cloche' => 'Cloche',
        'harpe' => 'Harpe',
        _ => 'Vibration seule',
      };

  // ── Dialogue de CRÉATION d'une alarme personnalisée (§8.5) ────────────

  Future<void> _dialogueNouvelleAlarme(
      BuildContext context, WidgetRef ref) async {
    final champLibelle = TextEditingController();
    var heure = TimeOfDay.now();
    var son = 'shofar';
    var vibration = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialogue) => AlertDialog(
          backgroundColor: AppColors.blanc,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.orSolaire.withValues(alpha: 0.5)),
          ),
          title: const Text(
            'Nouvelle alarme',
            style: TextStyle(
                color: AppColors.ardoise,
                fontWeight: FontWeight.w800,
                fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: champLibelle,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Tâche (ex. : Prière de midi, Réveil formation…)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.alarm_outlined,
                      size: 17, color: AppColors.bleuCiel),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Heure de sonnerie',
                        style: TextStyle(
                            color: AppColors.grisSecondaire, fontSize: 12.5)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final choisi = await showTimePicker(
                        context: context,
                        initialTime: heure,
                        helpText: 'Heure de sonnerie',
                      );
                      if (choisi != null) {
                        setStateDialogue(() => heure = choisi);
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: Text('${_2(heure.hour)} h ${_2(heure.minute)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  for (final s in const [
                    ('shofar', 'Shofar'),
                    ('cloche', 'Cloche'),
                    ('harpe', 'Harpe'),
                    ('silence', 'Vibration'),
                  ])
                    ChoiceChip(
                      label: Text(s.$2, style: const TextStyle(fontSize: 11.5)),
                      selected: son == s.$1,
                      selectedColor: AppColors.bleuCiel.withValues(alpha: 0.35),
                      onSelected: (_) async {
                        setStateDialogue(() => son = s.$1);
                        // Aperçu immédiat au tap du chip.
                        if (s.$1 == 'silence') {
                          await ApercuiSonore.instance.vibrer();
                        } else {
                          await ApercuiSonore.instance.jouer(s.$1);
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.vibration,
                      size: 17, color: AppColors.bleuCiel),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Vibrer aussi',
                        style: TextStyle(
                            color: AppColors.grisSecondaire, fontSize: 12.5)),
                  ),
                  Switch(
                    value: vibration,
                    onChanged: (v) => setStateDialogue(() => vibration = v),
                    activeColor: AppColors.bleuCiel,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.bleuCiel,
                foregroundColor: AppColors.blanc,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(alarmsProvider.notifier).ajouterPersonnalisee(
                      libelle: champLibelle.text.trim(),
                      heure: heure.hour,
                      minute: heure.minute,
                      son: son,
                      vibration: vibration,
                    );
                await ApercuiSonore.instance.stopper();
              },
              child: const Text('Créer l\u2019alarme'),
            ),
          ],
        ),
      ),
    );
  }

  /// Ligne « Heure de sonnerie » du RHEMA du matin — ouvre le sélecteur
  /// d'heure natif et reprogramme les alarmes (§8.4).
  Widget _ligneHeure(BuildContext context, WidgetRef ref, AlarmeAffichee alarme,
          Color couleur) =>
      Row(
        children: [
          Icon(Icons.alarm_outlined, size: 16, color: couleur),
          const SizedBox(width: 7),
          // Flexible : la ligne ne déborde jamais sur les petits écrans.
          const Flexible(
            child: Text('Heure de sonnerie',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(color: AppColors.grisSecondaire, fontSize: 12)),
          ),
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
          // Flexible : la ligne ne déborde jamais sur les petits écrans.
          const Flexible(
            child: Text('Avant le coucher du soleil',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(color: AppColors.grisSecondaire, fontSize: 12)),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
