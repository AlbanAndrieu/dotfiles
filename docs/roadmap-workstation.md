# Roadmap dotfiles — profil workstation Ubuntu

**Périmètre :** uniquement `AlbanAndrieu/dotfiles`. Architecture acceptée : [contrat Option A](workstation-ownership.md). Les opérations système relèvent d'[ansible-workstation](https://github.com/AlbanAndrieu/ansible-workstation/blob/master/docs/roadmap-workstation.md) et les YubiKey de [nabla-compose](https://github.com/AlbanAndrieu/nabla-compose/blob/master/docs/roadmap-workstation-yubikey.md).

| Priorité | Action unique | Critère de fin | État au 27/10/2026 |
| --- | --- | --- | --- |
| P0 | Maintenir `.bashrc`, Starship, Terminator, OpenClaw completions sécurisés | Démarrage interactif sans erreur, 7/7 contrats Bash et 4/4 PTY | Tests déjà observés PASS ; terminal neuf reste à confirmer |
| P0 | Conserver la PR dotfiles #1 fusionnée comme référence, sans régression | `main` contient les réparations Direnv/mise sans état utilisateur perdu | Fusion vérifiée |
| P1 | Extraire l'inventaire système canonique vers Ansible puis transformer l'ancien collecteur en wrapper | Un seul format JSON v1 et un seul collecteur actif ; comparaison des sorties | À faire dans le dépôt Ansible d'abord |
| P1 | Inventorier les unités `systemd --user` et leurs dépendances | Unités versionnées sans secret, activation opt-in documentée | À faire |
| P1 | Décrire un bootstrap utilisateur post-réinstallation, offline-first | Rejeu idempotent sur un `HOME` temporaire, sans écrasement | À faire |
| P2 | Séparer les fichiers sensibles des dotfiles suivis | Tests d'ignore et absence de credentials dans Git | À faire |
| P2 | Ajouter des preuves locales de démarrage et de latence du prompt | Sans scan complet de `$HOME`, sans CI payante | À faire |

**Hors périmètre :** gestion PAM, Secure Boot, règles Docker/nftables, DNS de l'OS, sauvegardes Restic, transactions de cartes YubiKey.

**Règles :** exécution locale des tests ; commits `[skip ci]` ; PR Draft ; aucune fusion automatique ; aucune mutation de secrets.
