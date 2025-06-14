# chatbot_app

Application Client pour effectuer des requêtes auprès de notre chatbot dans le cadre d'un projet de quatrième année.
L'application a deux versions disponibles : un exécutable pour Windows et un installeur apk pour Android.

Pour toutes requêtes, l'application contacte l'API du serveur sur l'adresse ```192.168.100.1:8000```. 
Cette adresse est modifiable dans le fichier "variables.dart" dans le répertoire "lib".

## Fonctionnalités
### Recherche
La principale fonctionnalité est l'envoi de question, limitée à 25000 caractères, à une IA et la réception d'une réponse.
Les réponses sont traitées au format du markdown.
Cette fonctionnalité dispose de plusieurs modes :
- Recherche simple : mode par défaut où l'IA génère une réponse uniquement basée sur la question.
- Recherche web : mode avancé activable en cliquant sur le bouton en forme de globe et qui indique à l'IA d'utiliser du web scrapping pour améliorer sa réponse.
- Fichiers : l'utilisateur peut ajouter jusqu'à 4 fichiers, pouvant chacun faire 24 Mo, qui seront analysés par l'IA.

L'ajout de fichiers et la recherche web sont incompatibles, donc activer l'une de ces fonctionnalités bloquera l'autre.

Dans tous les cas, l'IA dispose d'un RAG concernant des informations sur la politique de cybersécurité de l'UPHF.

### Autres

D'autres fonctions sont implémentées :
- Inscription / Connexion / Déconnexion d'un utilisateur
- Speech-to-text (/!\ uniquement pour Android /!\) pour écrire les prompts en parlant
- Accès à des anciennes conversations
- Suppression d'anciennes conversations

## Exécuter
Pour lancer l'application, vous pouvez accéder à la section **Releases** de ce GitHub. Vous y trouverez un fichier ZIP à extraire pour obtenir l'exécutable Windows (à exécuter dans le dossier où il a été extrait), ainsi qu'un fichier APK à lancer sur un appareil Android pour télécharger l'application.

Pour regénérer ces fichiers d'installation à partir du projet, il suffit d'exécuter les commandes :
- ```flutter build windows``` pour Windows,
- ```flutter build apk``` pour Android.

