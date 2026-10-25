# Bash prompt integration: mise, Starship, Direnv

Scope: Ubuntu workstation shell startup. Keep prompt initialization offline,
non-destructive and independent of Git remotes or Vaultwarden availability.

## Ownership and order

1. `~/.bashrc` initializes the interactive shell and may source Nabla's
   `env/home/dev.env.sh`.
2. Nabla configures mise and Starship and removes only complete, obsolete
   prompt commands. The Nabla implementation is in PR #68.
3. At the **end** of `~/.bashrc`, source `bin/repair-bash-prompt-hooks`
   to correct the known invalid token `_mise_hookhistory`. Keep valid
   `history -a`, `_mise_hook_prompt_command`, Starship and other entries.
4. Initialize or restore the official `direnv hook bash` last. Never blindly
   replace `PROMPT_COMMAND` or install the hook on every prompt.

The original operator error was `_mise_hookhistory: command not found`.
The exact earlier `PROMPT_COMMAND` has not been provided, so the mechanism
that concatenated the strings is not fully established. The code only fixes
the known invalid token, including when it occurs as a semicolon-separated
prompt command.

A Direnv export normally happens **when Bash next draws its prompt**.
Therefore `VIRTUAL_ENV` can be absent when a command prints diagnostics
and become set immediately afterward. Check again after the prompt returns.

## Offline contract tests

```bash
cd "$HOME"
bash bin/check-terminal-config
python3 bin/test-repair-bash-prompt-hooks.py
python3 bin/test-reconcile-bashrc-direnv
```

These checks do not source the full Nabla runtime, unlock secrets, run
network probes, install tools, or apply Ansible.

## Final verification in a new terminal

```bash
cd /workspace/users/albandrieu30/ansible-workstation
source scripts/diagnose-direnv-shell.sh

# Run after the prompt has returned, not in the same multi-command paste.
printf 'VIRTUAL_ENV=%s\n' "${VIRTUAL_ENV:-unset}"
type -P python
type -P ansible
```

Expected: the diagnostic reports an installed `_direnv_hook`, its presence
in `PROMPT_COMMAND`, and **no invalid mise/history token**. Python and
Ansible must resolve to this project's `.venv/bin`. No `uv sync` is
necessary merely to repair the shell integration.

Do not disclose the entire `PROMPT_COMMAND` to public CI logs: its contents
may include custom shell commands or local paths. The diagnostic reports
only known hook names and statuses.
