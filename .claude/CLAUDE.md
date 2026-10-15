# Instructions globales

## Style de code

- Respecter le `.editorconfig` du projet (et `~/.editorconfig` à défaut)
  avant d'écrire un fichier.
- Indentation : 2 espaces. Jamais de tabulations, sauf dans les `Makefile`.

## Commandes Bash

Pour éviter les demandes de confirmation inutiles du hook `rm-recursive-guard.py`
(« Recursive rm guard: could not parse the command, confirm it ») :

- Séparer les modifications, la validation (lint, tests, pre-commit) et la
  création de PR en commandes distinctes.
- Modifier les fichiers avec les outils Edit/Write plutôt qu'avec un heredoc
  Python ou `sed` complexe.
- Éviter de chaîner trop d'opérations (`&&`, `;`, `|`) dans une seule commande.
