# Workstation system inventory outside `$HOME`

> **Architecture Option A (27 octobre 2026) :** voir [ownership](workstation-ownership.md) et [roadmap du dépôt](roadmap-workstation.md). Le script d'inventaire ici est transitoire ; la collecte système canonique appartient à `ansible-workstation` après validation d'équivalence.


## Purpose

The repository tracks the user's dotfiles in `$HOME`. It does **not** establish
the active Ubuntu machine configuration outside the home directory.

Use `bin/inspect-workstation-system.py` to inspect the *observed* host state
without root permissions. This complements rather than replaces the historical
[hardware baseline](https://github.com/AlbanAndrieu/ansible-workstation/blob/master/workstation-hardware-inventory.md),
last revised **2026-07-09**, or the declarative Ansible configuration.

The script intentionally collects *only* allowlisted, non-secret attributes
from `/etc/os-release`, `/proc`, `/sys`, `lsblk`, `systemctl`,
`dpkg-query`, `mokutil` and the NVIDIA query interface. All commands use
absolute paths and a timeout; it does not run `sudo`, execute arbitrary
shell commands or enumerate `$HOME`.

## Procedure

1. Fetch the **existing** Draft branch of `dotfiles`. Do not force-reset
   any modified dotfiles.
2. Run the offline checks.

```bash
cd "$HOME"
python3 -B bin/test-workstation-system-inventory.py
bash bin/check-terminal-config
```

3. View the concise inventory in your local terminal.

```bash
python3 -B "$HOME/bin/inspect-workstation-system.py"
```

4. If structured comparison is needed, select JSON. It is written **only
   to standard output**, not automatically uploaded or committed.

```bash
python3 -B "$HOME/bin/inspect-workstation-system.py" --format json
```

5. Review any output before sharing. The script deliberately omits hostnames,
   usernames, UID, domain names, addresses, MACs, serials, disk device names,
   UUIDs, environment variables, commands, secrets and the contents of `$HOME`.

Do **not** redirect the JSON into the tracked `$HOME` Git repository or
commit machine snapshots. A report in a private, ignored state directory
can be added later with an explicit retention policy if necessary.

## Coverage and interpretation

| Category | Observed signals | Not collected |
| --- | --- | --- |
| OS | release, architecture and kernel | hostname or user |
| Hardware | CPU model, RAM, board/BIOS versions, GPU model/driver when available | BIOS serial, PCI/USB serials |
| Storage | known mountpoint presence, LUKS/dm-crypt presence | device names, UUIDs, partition maps |
| Boot | UEFI, Secure Boot reported state, TPM presence | TPM keys, firmware measurements |
| Hardening | selected sysctl values and AppArmor kernel flag | arbitrary `/etc` files |
| Services | active/enabled states of 10 named systemd units | full service catalog, unit contents |
| Packages | versions of 11 specifically named security packages | complete package list or apt sources |

Treat missing information as **unknown**, not as a security failure. For example,
an enabled firewall unit does not prove that firewall rules are correct,
and the presence of an encrypted volume does not prove `/` is on LUKS.

The real system can drift from the July 2026 hardware inventory. Compare
the new observed values before updating it, and retain the observation date
and the provenance of each field. The collector does not make changes to
Ansible configuration or the operating system.

## Future separately approved work

A subsequent security audit may cover resolved DNS, NetworkManager, UFW/nft
rules, SSH hardening, installed kernels, unattended-upgrades policy and
Secure Boot verification, but **only** through purpose-built field allowlists.
Never use `sudo tar /etc`, a blanket upload of `/var`, `env`, `printenv`,
`lsblk -f` or `ip address` as an unattended report. Avoid private IPs and
configuration secrets by default.
