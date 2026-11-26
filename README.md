# Horloge Céleste — Le temps de l'alliance de l'Éternel

**Yeshua Calendar** · Application mobile Flutter

Reproduction fidèle du **calendrier biblique de 364 jours** déjà implémenté
dans [Yeshua Connect Mobile](https://github.com/SenaDev007/yeshua-connect-mobile),
étendue d'un système complet de temps biblique : **horloge divine**, **trois
veilles de la nuit**, **douze heures saisonnières**, **quatre parties du jour**,
**alarmes spirituelles RHEMA** — avec l'identité visuelle lumineuse propre à
Horloge Céleste (bleu céleste `#3B82F6`, or solaire `#CFA63A`, ivoire `#F5F0E6`)
et, comme la page web `/calendrier-biblique` du
[Mouvement Christ Libère](https://github.com/SenaDev007/mouvement-Christ-Libere),
des **images de saison** (printemps, été, automne, hiver) sous voiles dégradés
pour embellir les écrans.

---

## 1. Ce qui a été fait

### PHASE 1 — Audit (compte rendu)
- Audit complet de `yeshua-connect-mobile` : Flutter / Dart ≥3.5, Riverpod,
  go_router, dio + cache JSON hors-ligne, calendrier via backend API
  (`/api/calendrier-biblique/{annee}`).
- **Rétro-ingénierie du moteur du calendrier 364 jours** depuis les données
  réelles de l'API (26 années échantillonnées 1900→2100) :
  1. année = **364 jours = 52 semaines exactes**, toujours débutant un **mercredi** ;
  2. début de l'année = **mercredi le plus proche de l'équinoxe de mars** (distance
     en jours entiers) — validé **26/26** contre l'API ;
  3. les semaines intercalaires émergent de la règle (écart de 8 jours :
     2022, 2028, 2033…) ;
  4. 12 mois — Aviv, Ziv, Sivan, Tammouz, Av, Éloul, Éthanim, Boul, Kislev,
     Tévet, Shevat, Adar — longueurs [30,30,31,30,30,31,30,30,31,30,30,31] ;
  5. jour de semaine 1 = Dimanche … 7 = Shabbat (Samedi), 52 Shabbats/an ;
  6. trimestres Printemps/Été/Automne/Hiver ;
  7. 10 fêtes de l'Éternel aux dates fixes avec les définitions exactes
     (noms français/hébreu, références, couleurs, travail interdit, durées).
- Découverte : les événements shofar du backend utilisent des **couchers de
  soleil saisonniers réels de Jérusalem** (jamais 18 h 00 fixes).

### PHASE 2 — Architecture
```
packages/horloge_celeste_engine/  ← moteur PUR DART, 0 dépendance, 0 réseau
  lib/src/solar_engine.dart          (A) SolarEngine — NOAA, polaire géré
  lib/src/time_engine.dart           (A) TimeEngine — ruptures temporelles §13
  lib/src/biblical_calendar_engine.dart (calendrier 364 j — règles conservées)
  lib/src/biblical_calendar_adapter.dart (D) transition au coucher réel §14
  lib/src/biblical_time_engine.dart  (C) veilles + heures + parties §3/§4
  lib/src/alarm_planner.dart         (E) planification des 3 alarmes §8
  test/                              ← 113 tests (dont parité API)
lib/                             ← application Flutter (Riverpod, 5 écrans)
  core/theme                         palette Horloge Céleste officielle §10.1
  services/                          localisation §9, notifications §8, store §13
  state/                             HorlogeController (tick 1 s, transitions §14)
  ui/screens                         Accueil, Horloge, Temps biblique,
                                     Calendrier, Alarmes, Paramètres
  ui/widgets                         horloge analogique, cadran des veilles,
                                     cadran solaire, cartes saisonnières…
```
Le moteur est un **package séparé testable indépendamment** (exigence §12) :
`dart test` ne nécessite même pas le SDK Flutter.

### PHASE 3 — Moteur astronomique
Algorithme NOAA embarqué (lever/coucher ±1-2 min), **100 % hors connexion**,
fuseau système, régions polaires → « indisponible » affiché, **jamais d'horaire
inventé** (§9.4). Vérifié contre des heures publiées (Cotonou, Paris,
Jérusalem/Tel Aviv) et contre les événements du backend.

### PHASE 4 — Temps biblique
- **Trois veilles** : la nuit réelle (coucher → lever suivant) divisée en
  **trois tiers égaux recalculés chaque jour** — jamais de tranches de 4 h.
- **Douze heures saisonnières** : durée du jour ÷ 12 (jour de 13 h → heures
  de 65 min) — jamais des heures civiles fixes.
- **Quatre parties du jour** : Matin / Approche du milieu du jour /
  Après-midi / Fin du jour (convention d'affichage §4.3), avec les repères
  scripturaires (3ᵉ, 6ᵉ, 9ᵉ, 11ᵉ heure).
- Cycle complet §5 : coucher → 3 veilles → lever → 4 parties → coucher.

### PHASE 5 — Synchronisation calendaire
- `BiblicalCalendarAdapter` : la date biblique change **au coucher du soleil
  réel local** — jamais à minuit, jamais à 18 h 00.
- Clé de transition persistée (année-jour) → **aucune double incrémentation** ;
  à la reprise, recalcul complet depuis l'heure réelle (§13/§14).
- Le moteur reproduit le calendrier existant **sans modifier ses règles** :
  parité prouvée par `test/calendar_parity_test.dart` (7 années golden ×
  364 jours + 70 fêtes, champ par champ = 100 %).

### PHASE 6 — Interface et embellissement
5 espaces exactement (§10.3) : Accueil, Horloge, Temps biblique, Calendrier,
Alarmes + Paramètres. Palette officielle uniquement, fond ivoire lumineux,
**aucun bleu nuit profond**. Horloge numérique (comptes à rebours, date
biblique, période en cours) ⇄ analogique (CustomPainter : aiguilles or
solaire, graduations, animation fluide 60 i/s) sans perte d'information.
Cadran circulaire des 3 veilles, cadran solaire des 12 heures, chronologies
avec états distincts (terminée / en cours / à venir), grille mensuelle
12 mois avec Shabbats dorés et fêtes colorées — comme l'app existante.

**Embellissement par images** (parité avec la page web `/calendrier-biblique`) :
les quatre paysages de saison du web (Unsplash, identifiés dans
`vue-aujourdhui.tsx` / `vue-mensuelle.tsx` / `vue-annuelle.tsx`) sont embarqués
dans `assets/images/` et habillent la carte du jour biblique (Accueil et
vue Aujourd'hui), la vue Mois et la vue Années, sous des voiles dégradés
adaptés à la palette (ardoise / bleu céleste / or). Les écrans restent
lisibles : texte blanc sur voile, liseré doré signature.

### PHASE 7 — Alarmes
- **RHEMA du matin** — 05 h 00 locales, répétition quotidienne.
- **Préparation du soir** — coucher réel **− 5 minutes** (one-shot replanifié).
- **RHEMA du soir** — **au coucher réel** exact (one-shot replanifié).
- Reprogrammation : au démarrage, après changement de position, à la reprise.
- Permissions Android 13+ / alarmes exactes Android 12+ avec replis ; canal
  dédié `alarmes_celestes`, son shofar intégré, vibration et messages
  personnalisables, historique persistant (§8.4).

### PHASE 8 — Validation
```bash
cd packages/horloge_celeste_engine && dart test
```
→ **113 tests passent (113/113)** :
- parité calendrier : 2 548 jours + 70 fêtes comparés champ par champ ;
- règle d'ancrage équinoxe : 24 débuts d'année vérifiés (2020-2100) ;
- veilles : tiers réels, couverture exacte, nuit de 11 h 30 → 3 h 50 ;
- heures : jour de 13 h → 65 min, jour de 11 h → 55 min, 12ᵉ heure = coucher ;
- transitions : coucher réel, minuit civil ignoré, pas de double transition,
  reprise après plusieurs heures ;
- alarmes : 05 h 00, coucher − 5 min, coucher exact, polaire sans horaire
  fictif, désactivations respectées ;
- ruptures temporelles : fuseau, saut, coucher dépassé.

Une **vérification statique de l'application** complète ce contrôle : tous les
imports résolvent, les 5 écrans sont montés dans la coquille de navigation,
toutes les classes de widgets utilisées sont définies, tous les assets
référencés existent et aucune couleur hors charte n'est utilisée.

## 2. Ce qui reste à faire sur appareil réel

Le sandbox n'exécute ni Flutter ni un émulateur Android — **aucune
fonctionnalité n'est présentée comme testée sur appareil** (§17) :

1. `flutter pub get` puis `flutter run` sur un appareil/émulateur ;
2. test des notifications natives (Android 13 : autorisation, Android 12 :
   alarmes exactes, écran verrouillé, app fermée) ;
3. test GPS réel + gestion du refus de permission ;
4. vérification du splash/écran sur iOS (fichiers iOS à générer par
   `flutter create --platforms=ios .` dans une session Flutter complète) ;
5. ~~remplacer le logo placeholder~~ — **fait** : le logo officiel
   **Horloge Céleste** (médaillon céleste doré — sablier, rouleaux de la
   Torah, fond étoilé) est intégré depuis le dépôt
   (`favicon_horloge-celeste/`) : il habille la barre et l'écran À propos
   (`assets/images/logo-horloge-celeste.png`) et sert de source aux icônes
   de lanceur Android — `ic_launcher`, `ic_launcher_round` et
   `ic_launcher_foreground` adaptatif sur les cinq densités, avec la couche
   de fond échantillonnée sur l'anneau du médaillon (`#7E5C1E`).

## 3. Lancer le projet

```bash
flutter pub get
flutter run                          # appareil connecté ou émulateur
cd packages/horloge_celeste_engine && dart test  # moteur : 113/113
```

Application **100 % hors connexion** : aucun appel réseau, aucun backend
requis — le calendrier embarque les règles éprouvées et les horaires solaires
sont calculés localement.

## 4. Palette officielle (§10.1)

| Couleur | Hex | Usage |
|---|---|---|
| Bleu céleste | `#3B82F6` | couleur principale : navigation, boutons, éléments actifs |
| Or solaire | `#CFA63A` | signature : cadran, aiguilles, repères du nouveau jour |
| Ivoire | `#F5F0E6` | fond principal |
| Blanc | `#FFFFFF` | cartes et surfaces |
| Ardoise | `#1E293B` | textes et contrastes |
| Gris secondaire | `#64748B` | textes atténués |


## Publication Google Play Store — dossier prêt

Tout ce qui pouvait être préparé avant le dépôt est en place :

- **Signature** : clé d'upload RSA 2048 (alias `upload`, valable jusqu'en 2054)
  câblée dans `android/app/build.gradle` via `android/key.properties`
  (hors dépôt Git — modèle sans secret dans `android/key.properties.example`).
  `flutter build appbundle --release` signe automatiquement. Sauvegarde du
  keystore + mot de passe livrée à part (`cles-play-store.zip`).
- **Version** : `1.0.0+1` (`pubspec.yaml`) — incrémenter le code à chaque dépôt.
- **Identifiant** : `com.yeshua.horlogeceleste` (aucun `com.example`), targetSdk 35.
- **Graphiques** (`play-store/`) : logo 512×512 **fond blanc**,
  affiche 1024×500 opaque, 4 rendus d'écrans 1080×1920 (maquettes fidèles au
  code — à remplacer par de vraies captures après premier `flutter run`).
- **Fiche** : textes prêts (`play-store/fiche-play-store.txt`) et réponses aux
  formulaires (`play-store/reponses-formulaires.md`).
- **Politique de confidentialité** : `docs/politique-confidentialite.html` —
  activer GitHub Pages puis coller l'URL dans la Console.
- **Guide pas à pas** : `Guide-Publication-PlayStore-HorlogeCeleste.docx`.
