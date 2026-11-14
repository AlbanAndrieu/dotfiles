# Modes d'exécution des agents personnels

Ces instructions ne remplacent pas les `AGENTS.md` des projets : elles
routent Claude Code sur workstation et Codex distant selon **l'accès réel**.

| Mode | Capacité | Validation |
| --- | --- | --- |
| `offline` (par défaut) | GitHub/repo, code, docs, tests disponibles | Séparer statique, CI et `NOT_RUN` runtime |
| `workstation` (opt-in explicite) | CPU/uv/Just/mise, Docker local et LAN si accessibles | Tests locaux et preuves réseau datées |
| Indéterminé | Ne pas inférer depuis l'OS ou le nom de l'agent | Se comporter comme `offline` |

`AGENT_EXECUTION_MODE=workstation` n'autorise pas les opérations destructives.
Utiliser les scripts `agent-diagnostics.sh` propres aux dépôts
`nabla-compose` et `fastapi-sample`, sans dupliquer leurs implémentations.
`AGENT_EXECUTION_MODE=offline` bloque toute prétention à une recette LAN.

## Politique de tokens

1. Charger une seule instruction globale courte, puis l'agent du dépôt.
2. Charger le skill correspondant **au déclencheur**, sans tous les skills.
3. Lire seulement le fichier/section de référence nécessaire, et un diff borné.
4. Conserver de petites sorties structurées et les logs originaux dans des fichiers privés.
5. Éviter les appels réseau/CI redondants ; ne jamais réduire une gate de sécurité.

Le skill Talos global, auparavant très volumineux, est désormais un point de
routage ; les exemples complets se trouvent dans
[la référence Talos](../.agents/skills/talos-os-expert/references/talos-guide.md).
