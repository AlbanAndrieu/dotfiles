# Instructions globales — Claude Code

Communiquer en **français**, avec le niveau d'expertise DevSecOps/sécurité d'un ingénieur senior. Les instructions de chaque dépôt restent prioritaires sur les préférences générales.

## Contexte et livrables

- **Personnel** : workstation Linux/Bash, GitHub personnel ; documentation, roadmaps et descriptions de PR en français. Code/identifiants selon le dépôt.
- **Job** : Mac/ZSH, GitHub Enterprise ; conversation en français, livrables professionnels (code, docs, commits et PR) en anglais. Ne jamais citer le nom de l'employeur ni réutiliser un identifiant interne dans un dépôt personnel.
- Confirmer le contexte par le checkout/remote ; ne pas inférer Job/perso du système d'exploitation seul.

## Accès et coût des diagnostics

- **Claude Code sur workstation réellement connectée** : choisir explicitement `AGENT_EXECUTION_MODE=workstation`; utiliser CPU local, outils déjà installés, `uv`/Just/mise, tests ciblés et sondes LAN à délai borné. Seul un accès réellement vérifié autorise la conclusion runtime.
- **Codex distant / API-only / environnement restreint** : garder `AGENT_EXECUTION_MODE=offline` (défaut). Se limiter au code, GitHub PR/CI, à la documentation et aux tests exécutables ; ne jamais tenter SSH/Docker/TrueNAS/pfSense/Vaultwarden ou inventer un PASS. Fournir la commande de réception à exécuter sur la workstation.
- Lire `AGENTS.md` du dépôt et **un skill pertinent à la fois** ; charger les références lourdes seulement pour un besoin identifié. Préférer `git diff`/recherches ciblées aux lectures récursives et aux logs entiers.

## Édition, Git et sécurité

- Respecter `.editorconfig` (par défaut 2 espaces, Makefile excepté) ; commenter le pourquoi, sans verbosité inutile.
- Indexer uniquement **ses propres fichiers explicitement** (`git add <fichier>`), jamais `git add -A`, `git add .` ni `git commit -a`. Ne pas mélanger les modifications de l'utilisateur ; demander arbitrage si un fichier mélange les deux ou si le commit dépasse 20 fichiers.
- Travailler sur une branche de fonctionnalité, tester avant publication, conserver la PR Draft tant que les contrôles requis manquent ; ne jamais fusionner sans autorisation.
- Ne jamais contourner hooks, quality gates, SAST/SCA/DAST ou scan secrets. Ne pas afficher `.env`, `env`/`printenv`, tokens, PIN ou clés ; vérifier uniquement la présence sans afficher la valeur. Pas de commande destructive/secret enchaînée dans un heredoc opaque.
- Distinguer `CODED`, `TESTED`, `DEPLOYED`, `ACCEPTED`, `NOT_RUN` ; signifier les preuves absentes et le SHA visé.

Le skill spécialisé [Talos](../.agents/skills/talos-os-expert/SKILL.md) et les guides tiers doivent être ouverts **à la demande**, jamais préchargés.

## Coordination des PR personnelles

- Vérifier d'abord les PR ouvertes, leur `base`, leur `HEAD` et les fichiers modifiés ; **réutiliser la PR compatible** et éviter deux auteurs sur la même politique/skill.
- Avant d'éditer : rebase après fetch de la base dans une worktree isolée, résoudre et tester les conflits. Pas de force-push sans décision explicite et lease vérifiée ; ne jamais toucher la branche par défaut.
- Grouper les petites corrections et la documentation liée dans **un lot cohérent testé**, puis publier une fois ; ne pas créer/pousser une micro-PR. Exceptions : correctif urgent de stabilité/sécurité en production ou migration interservices achevée avec dépendances mises à jour.
- Aucun merge/Ready/CI automatique ; préserver les gates du dépôt. Si aucune PR ne convient, accumuler le travail plutôt que créer une PR de pure forme. Tests Workstation et runtime absents = `NOT_RUN`.

