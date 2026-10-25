#!/usr/bin/env python3
"""Offline Bash contracts: preserve prompt integrations and fix a known typo."""
from pathlib import Path
import os
import subprocess
import unittest

HELPER = Path(__file__).with_name("repair-bash-prompt-hooks")


class BashPromptHookTest(unittest.TestCase):
    def run_bash(self, statements: str):
        result = subprocess.run(
            ["/bin/bash", "--noprofile", "--norc", "-c",
             'set -e\n' + statements, "_", str(HELPER)],
            env={**os.environ, "BASH_ENV": "/dev/null"},
            text=True,
            capture_output=True,
            timeout=5,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("command not found", result.stderr)
        return result.stdout

    def test_scalar_mise_history_corruption(self):
        for value in ("_mise_hookhistory", "_mise_hookhistory -a",
                      "_direnv_hook;_mise_hookhistory -a;__starship_prompt_command"):
            with self.subTest(value=value):
                run = subprocess.run(
                    ["/bin/bash", "--noprofile", "--norc", "-c",
                     '''set -e
PROMPT_COMMAND="$HOOK_TEST_INPUT"
source "$1"
[[ "$PROMPT_COMMAND" != *'_mise_hookhistory'* ]]
[[ "$PROMPT_COMMAND" == *'history -a'* || "$PROMPT_COMMAND" == 'history -a' ]]
printf 'PASS\\n'
''', "_", str(HELPER)],
                    env={**os.environ, "BASH_ENV": "/dev/null",
                         "HOOK_TEST_INPUT": value},
                    text=True, capture_output=True, timeout=5, check=False,
                )
                self.assertEqual(run.returncode, 0, run.stderr)
                self.assertIn("PASS", run.stdout)

    def test_array_preserves_legitimate_prompt_hooks(self):
        self.run_bash('''
PROMPT_COMMAND=('history -a' '_mise_hookhistory' '_mise_hook_prompt_command' '__starship_prompt_command' '_direnv_hook')
source "$1"
[[ "${PROMPT_COMMAND[1]}" == 'history -a' ]]
[[ "${PROMPT_COMMAND[2]}" == '_mise_hook_prompt_command' ]]
[[ "${PROMPT_COMMAND[3]}" == '__starship_prompt_command' ]]
[[ "${PROMPT_COMMAND[4]}" == '_direnv_hook' ]]
''')

    def test_does_not_rewrite_quoted_history_mentions(self):
        self.run_bash('''
PROMPT_COMMAND='printf "_mise_hookhistory in a log";history -a'
source "$1"
[[ "$PROMPT_COMMAND" == 'printf "_mise_hookhistory in a log";history -a' ]]
PROMPT_COMMAND='printf "quoted;_mise_hookhistory;value";history -a'
source "$1"
[[ "$PROMPT_COMMAND" == 'printf "quoted;_mise_hookhistory;value";history -a' ]]
''')

    def test_restores_only_previously_enabled_mise_hook(self):
        self.run_bash('''
__MISE_HOOK_ENABLED=1
_mise_hook_prompt_command() { :; }
_mise_add_prompt_command() {
  case ";$PROMPT_COMMAND;" in
    *";_mise_hook_prompt_command;"*) ;;
    *) PROMPT_COMMAND="_mise_hook_prompt_command;$PROMPT_COMMAND" ;;
  esac
}
PROMPT_COMMAND='_mise_hookhistory -a'
source "$1"
[[ "$PROMPT_COMMAND" == '_mise_hook_prompt_command;history -a' ]]
source "$1"
[[ "$PROMPT_COMMAND" == '_mise_hook_prompt_command;history -a' ]]
''')

    def test_idempotent_and_does_not_execute_prompt_on_source(self):
        self.run_bash('''
PROMPT_COMMAND='_mise_hookhistory -a'
source "$1"
first="$PROMPT_COMMAND"
source "$1"
[[ "$PROMPT_COMMAND" == "$first" ]]
[[ "$PROMPT_COMMAND" == 'history -a' ]]
''')


if __name__ == "__main__":
    unittest.main()
