# Contrat de responsabilité — workstation Ubuntu (Option A)

**Décision acceptée le 27 octobre 2026.** Voir l'[ADR inter-dépôts](https://github.com/AlbanAndrieu/nabla-compose/blob/master/docs/adr/adr-workstation-option-a.md).

## Mission du dépôt

Le checkout Git de `dotfiles` est directement `$HOME`. Il est la **source de vérité de la configuration utilisateur souhaitée**, et non une sauvegarde complète du compte ou du système Ubuntu.

| Reste dans dotfiles | N'est pas stocké ici |
| --- | --- |
| `.bashrc`, Starship, Terminator, Git utilisateur, aliases et snippets | `/etc`, unités système, PAM, pare-feu, DNS effectif |
| Fichiers déclaratifs `~/.config/systemd/user/*.service` sans secrets | Copie brute de `/var`, journaux système, inventaire matériel nominatif |
| Tests de démarrage Bash et contrats d'intégration locale | Clés SSH/GPG/PIV, OTP, tokens, PIN/PUK, coffre et escrow |
| Raccourcis vers l'audit système Ansible | Copies non chiffrées de configuration système, snapshots datés |

Les `mise.toml`, `uv.lock` et `package-lock.json` restent au dépôt du **projet qui les consomme**, pas tous dans `dotfiles`.

## Flux Option A

1. **Décrire** : Git conserve les fichiers déclaratifs utilisateur.
2. **Observer** : `ansible-workstation` audite l'OS ; son inventaire redigé ne contient ni adresse ni secret.
3. **Comparer** : un rapport daté de dérive est conservé **hors du dépôt Git**, dans un emplacement privé, avec rétention.
4. **Sauvegarder** : Restic chiffre les configurations et données nécessaires à la reprise ; les credentials Restic sont stockés hors Git ; une copie reste indépendante de la workstation et du NAS principal.
5. **Restaurer** : restaurer et tester d'abord dans un emplacement isolé. Ne pas réinjecter aveuglément `/etc`, PAM, DNS ou les clés.

Les scripts existants `bin/inspect-workstation-system.py` et `bin/test-workstation-system-inventory.py` restent compatibles **pendant la migration**. La collecte système canonique sera transférée à `ansible-workstation`, sans supprimer ces scripts avant équivalence testée. Le raccourci utilisateur pourra ensuite les invoquer dans le checkout Ansible ; ne pas faire une seconde implémentation.

## Frontière YubiKey

`dotfiles` peut posséder les options **publiques** des clients GPG/SSH et le paramétrage de l'agent utilisateur, sans données d'enrôlement ou identifiants sensibles. `nabla-compose` est propriétaire des diagnostics et transactions matérielles YubiKey (OTP2, PIV, FIDO2, OpenPGP, age, escrow). `ansible-workstation` ne doit pas manipuler les cartes ni modifier PAM automatiquement.

## Validation sans écriture système

```bash
bash "$HOME/bin/check-terminal-config"
python3 -B "$HOME/bin/inspect-workstation-system.py"
```

Les résultats publiés sont des *observations*, jamais une preuve de conformité globale. Une version Git n'atteste pas d'un état actif. Pas de CI GitHub payante, pas d'automerge et pas de mutation sans intervention explicite.
