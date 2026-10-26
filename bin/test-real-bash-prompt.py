#!/usr/bin/env python3
"""Test real Bash prompts in an isolated PTY without sourcing the user's home."""
import os
from pathlib import Path
import pty
import select
import subprocess
import tempfile
import time
import unittest

HELPER = Path(__file__).with_name("repair-bash-prompt-hooks")


class RealBashPromptContract(unittest.TestCase):
    def run_prompt(self, configuration: str, *, repair: bool = True) -> str:
        with tempfile.TemporaryDirectory(prefix="dotfiles-bash-pty-") as tmp:
            root = Path(tmp)
            rc = root / "controlled-rc"
            # Never source ~/.bashrc, ~/.profile, Nabla, real Starship or Direnv.
            # The helper's path is provided through the subprocess environment.
            rc.write_text(
                "PS1='SAFE_PROMPT> '\n"
                + configuration
                + ('\nsource "$TEST_PROMPT_HELPER"\n' if repair else "\n")
            )
            env = {
                "HOME": tmp,
                "PATH": "/usr/bin:/bin",
                "TERM": "dumb",
                "HISTFILE": "/dev/null",
                "HISTSIZE": "0",
                "BASH_ENV": "/dev/null",
                "TEST_PROMPT_HELPER": str(HELPER),
            }
            master, slave = pty.openpty()
            process = subprocess.Popen(
                ["/bin/bash", "--noprofile", "--rcfile", str(rc), "-i"],
                stdin=slave,
                stdout=slave,
                stderr=slave,
                env=env,
                start_new_session=True,
            )
            os.close(slave)
            output = bytearray()
            deadline = time.monotonic() + 7
            try:
                # No external commands are executed inside the test shell.
                os.write(master, b"printf 'SHELL_OK\\n'\nexit\n")
                while time.monotonic() < deadline:
                    readable, _, _ = select.select([master], [], [], 0.15)
                    if readable:
                        try:
                            block = os.read(master, 65536)
                        except OSError:
                            break
                        if not block:
                            break
                        output.extend(block)
                    if process.poll() is not None and not readable:
                        break
                if process.poll() is None:
                    process.kill()
                    self.fail("Bash prompt test exceeded the deadline")
                self.assertEqual(process.wait(timeout=2), 0)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=2)
                os.close(master)
            rendered = output.decode("utf-8", errors="replace")
            self.assertIn("SAFE_PROMPT>", rendered)
            self.assertIn("SHELL_OK", rendered)
            return rendered

    def test_harness_detects_unrepaired_prompt_error(self):
        output = self.run_prompt("PROMPT_COMMAND='_mise_hookhistory -a'", repair=False)
        self.assertIn("_mise_hookhistory: command not found", output)

    def test_repair_prevents_error_at_each_real_prompt(self):
        output = self.run_prompt("PROMPT_COMMAND='_mise_hookhistory -a'")
        self.assertNotIn("_mise_hookhistory: command not found", output)
        self.assertGreaterEqual(output.count("SAFE_PROMPT>"), 2)

    def test_repair_preserves_legitimate_mise_and_direnv_hooks(self):
        output = self.run_prompt(
            "_mise_hook_prompt_command() { :; }\n"
            "_direnv_hook() { :; }\n"
            "PROMPT_COMMAND='_mise_hook_prompt_command;_mise_hookhistory -a;_direnv_hook'"
        )
        self.assertNotIn("command not found", output)

    def test_duplicate_starship_hooks_execute_only_once_per_prompt(self):
        output = self.run_prompt(
            "starship_precmd() { printf 'STARSHIP_ONCE\\n'; }\n"
            "PROMPT_COMMAND=('starship_precmd' 'starship_precmd' '_mise_hookhistory')"
        )
        self.assertNotIn("_mise_hookhistory: command not found", output)
        self.assertEqual(output.count("STARSHIP_ONCE"), 2)


if __name__ == "__main__":
    unittest.main()
