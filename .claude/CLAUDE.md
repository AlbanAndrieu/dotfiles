# Instructions globales

## Langue

- Répondre à l'utilisateur en français (résumés, explications, questions).
  Le code, les identifiants et les messages de commit suivent les conventions
  du dépôt.

## Contexte perso / Job

- **Job** : MacBook Pro (macOS), shell ZSH, remotes GitHub Enterprise.
  Livrables (code, docs, commits, PR) en anglais.
- **Perso** : workstation Linux, Bash, remotes `github.com/AlbanAndrieu`.
  Documentation et PR en français, sauf convention contraire du dépôt.
- Ne jamais écrire le nom de l'employeur : écrire *Job*, *Office* ou *Mac*.
  Dans un dépôt perso, aucune référence interne au Job (organisation, dépôt,
  ticket ou URL GitHub Enterprise), y compris dans les commits, PR et CHANGELOG.

## Style de code

- Respecter le `.editorconfig` du projet (et `~/.editorconfig` à défaut)
  avant d'écrire un fichier.
- Indentation : 2 espaces. Jamais de tabulations, sauf dans les `Makefile`.
- Commenter seulement le pourquoi que le code ne peut pas montrer, en une
  ligne (règle de ponytail).

## Commandes Bash

Pour éviter les demandes de confirmation inutiles du hook `rm-recursive-guard.py`
(« Recursive rm guard: could not parse the command, confirm it ») :

- Séparer les modifications, la validation (lint, tests, pre-commit) et la
  création de PR en commandes distinctes.
- Modifier les fichiers avec les outils Edit/Write plutôt qu'avec un heredoc
  Python ou `sed` complexe.
- Éviter de chaîner trop d'opérations (`&&`, `;`, `|`) dans une seule commande.

## Git

L'utilisateur relit le diff en local et indexe lui-même ce qu'il veut commiter :

- Ne jamais indexer de fichiers : pas de `git add`, `git commit -a`,
  `git commit <fichiers>`, `git stage` ni `git rm --cached`. Laisser les
  changements non indexés.
- Quand l'utilisateur demande un commit, commiter uniquement ce qu'il a déjà
  indexé (`git commit` seul). Si rien n'est indexé, ou si un fichier modifié
  semble manquer, le signaler et lui demander d'indexer plutôt que de le faire.
- En fin de tâche, lister les fichiers modifiés et créés, pour qu'il sache quoi
  relire (`git diff` ne montre pas les nouveaux fichiers non suivis).

## Garde-fous

Appliqués par les hooks de `~/.claude/hooks/` (`guard-quality-gates.sh`,
`guard-secret-exposure.sh`, `scan-output-for-secrets.sh`) :

- Ne jamais contourner un hook git ou un quality gate (`--no-verify`,
  `git commit -n`, variables lefthook ou `SKIP_*`, `core.hooksPath`) : corriger
  le problème, ou signaler le check cassé à l'utilisateur, seul à décider de
  le sauter.
- Ne jamais afficher un secret (`echo` d'une variable `*_TOKEN`, `*_API_KEY`,
  `*_SECRET`, `env`, `printenv`, un fichier `.env`, `az keyvault secret show`,
  `gh auth token`…) : vérifier qu'il est défini (`[ -n "${VAR:-}" ]`) ou le
  capturer dans `$(…)`. Un secret affiché doit être révoqué : le dire à
  l'utilisateur.
