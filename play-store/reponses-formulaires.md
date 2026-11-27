# Réponses aux formulaires Google Play Console

## Formulaire « Sécurité des données »

| Question | Réponse |
|---|---|
| L'application collecte-t-elle ou partage-t-elle des données requises ? | **Non** |
| Toutes les données collectées sont-elles transmises de manière chiffrée ? | Sans objet (aucune collecte) |
| Un mécanisme de suppression existe-t-il ? | Sans objet (aucune collecte) — la désinstallation efface tout |
| Données : position ? | **Non collectée** (traitée en mémoire sur l'appareil, jamais persistée ni transmise) |
| Données : activité/app, fichiers, identifiants ? | Non |

Justification Play : l'accès à la localisation sert uniquement au calcul
on-device des heures solaires ; aucune donnée ne quitte l'appareil et rien
n'est écrit hors préférences locales. Renvoyer vers la politique de
confidentialité : https://senadev007.github.io/Yeshoua-Calendar/politique-confidentialite.html

## Classification du contenu (IARC)

| Question | Réponse |
|---|---|
| Violence, sang, contenu sexuel, jurons, drogue | Non |
| Jeux d'argent, loteries, paris | Non |
| Achat en application, devise virtuelle | Non |
| Contenu généré par l'utilisateur (messagerie, partage) | Non — aucune interaction entre utilisateurs |
| Destination : enfants ? | Non (mais sans contenu nocif ; aucune collecte) |
| Catégorie | Lifestyle |

## Public cible & contenu

| Question | Réponse |
|---|---|
| Tranche d'âge visée | 13 ans et plus |
| Public : l'app attire-t-elle les enfants ? | Non (thématique religieuse adulte, sans mécanique de jeu) |
| Contenu de l'app | Application religieuse/calendrier, tout public |

## Identité de l'app

| Question | Réponse |
|---|---|
| L'app est-elle un journal d'actualités ? | Non |
| Application pour réseaux sociaux ? | Non |
| L'app présente-t-elle des services financiers ? | Non |
| Santé / téléconsultation ? | Non |
| Fonctionnalités IA génératives ? | Non — aucun modèle génératif intégré |

## Accès à l'app (examen Play)

Répondre « toutes les fonctionnalités sont disponibles sans restriction » ;
aucune identifiants de connexion à fournir. Si l'examen demande une
démonstration vidéo : montrer l'écran Aujourd'hui, activer une alarme
RHEMA, fermer l'app et laisser sonner — c'est le cœur de la démonstration.

## URL de la politique de confidentialité

https://senadev007.github.io/Yeshoua-Calendar/politique-confidentialite.html

✅ GitHub Pages est ACTIVÉ (source : branche `main`, dossier `/docs`,
configuré via l'API le 27/11/2026). La page répond HTTP 200 avec la
politique v1.1. La racine du site https://senadev007.github.io/Yeshoua-Calendar/
est une page d'accueil qui pointe vers la politique.
