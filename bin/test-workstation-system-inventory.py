#!/usr/bin/env python3
"""Offline contracts for the inventory wrapper; the collector's own contracts
live in ansible-workstation (tests/test_workstation_inventory_contract.py)."""

import importlib.util
import io
import os
from pathlib import Path
from contextlib import redirect_stderr
import sys
import tempfile
from unittest import TestCase, main, mock

SOURCE = Path(__file__).with_name("inspect-workstation-system.py")
spec = importlib.util.spec_from_file_location("workstation_system_inventory", SOURCE)
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


class InventoryWrapperContract(TestCase):
    def test_missing_checkout_fails_closed(self):
        with tempfile.TemporaryDirectory() as d:
            with mock.patch.dict(os.environ, {"ANSIBLE_WORKSTATION_DIR": d}):
                err = io.StringIO()
                with redirect_stderr(err), mock.patch.object(tool.os, "execv") as execv:
                    self.assertEqual(tool.main(["--format", "json"]), 2)
        execv.assert_not_called()
        self.assertIn("ANSIBLE_WORKSTATION_DIR", err.getvalue())

    def test_runs_the_canonical_collector_with_the_same_arguments(self):
        with tempfile.TemporaryDirectory() as d:
            script = Path(d) / tool.COLLECTOR
            script.parent.mkdir()
            script.write_text("")
            with mock.patch.dict(os.environ, {"ANSIBLE_WORKSTATION_DIR": d}):
                with mock.patch.object(tool.os, "execv") as execv:
                    tool.main(["--format", "json"])
        execv.assert_called_once_with(
            sys.executable,
            [sys.executable, "-B", str(script), "--format", "json"],
        )

    def test_keeps_no_second_implementation(self):
        code = SOURCE.read_text()
        for forbidden in ("subprocess", "shell=True", "sudo ", "lsblk", "dpkg-query"):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, code)


if __name__ == "__main__":
    main()
