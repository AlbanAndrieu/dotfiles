#!/usr/bin/env python3
"""Synthetic offline contracts for the read-only system inventory."""
import importlib.util
import io
import json
from pathlib import Path
from contextlib import redirect_stdout
from unittest import TestCase, main, mock

SOURCE = Path(__file__).with_name("inspect-workstation-system.py")
spec = importlib.util.spec_from_file_location("workstation_system_inventory", SOURCE)
tool = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tool)


class SystemInventoryContract(TestCase):
    def test_only_explicit_system_commands_and_fields(self):
        code = SOURCE.read_text()
        for forbidden in (
            "shell=True", "sudo ", "hostnamectl", "ip addr", "ifconfig",
            "dmidecode", "serial_number", "by-uuid", "blkid",
            "os.environ", "write_text(", "open(", "ssh-key",
            "/etc/shadow", "/etc/ssh/", "/home/", "git push",
        ):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, code)
        self.assertEqual(
            set(tool.COMMANDS),
            {"systemctl", "dpkg-query", "lsblk", "mokutil", "nvidia-smi"},
        )
        self.assertTrue(all(x.startswith("/") for x in tool.COMMANDS.values()))

    def test_safe_hardware_labels_are_bounded(self):
        value = tool.safe_label("RTX 2060\nHOSTNAME=secret\x00" + "x" * 200)
        self.assertNotIn("\n", value)
        self.assertNotIn("=", value)
        self.assertLessEqual(len(value), 100)

    def test_disabled_and_inactive_are_not_misclassified(self):
        with mock.patch.object(tool, "execute", side_effect=["inactive", "disabled"]):
            state = tool.service_state("ufw.service")
        self.assertEqual(state["is-active"], "inactive")
        self.assertEqual(state["is-enabled"], "disabled")

    def test_storage_never_emits_device_identifiers_or_custom_mounts(self):
        devices = {"blockdevices": [
            {"type": "disk", "name": "sda", "serial": "NEVER_EXPORT",
             "fstype": "crypto_LUKS", "mountpoints": [None],
             "children": [{"type": "crypt", "name": "private-data",
                           "uuid": "NEVER_EXPORT", "fstype": "ext4",
                           "mountpoints": ["/workspace", "/sensitive/mount"]}]}
        ]}
        def fake_execute(cmd, *args):
            if cmd == "lsblk":
                return json.dumps(devices)
            if cmd == "mokutil":
                return "SecureBoot enabled"
            return ""
        with mock.patch.object(tool, "execute", side_effect=fake_execute), mock.patch.object(tool.Path, "is_dir", return_value=False), mock.patch.object(tool.Path, "exists", return_value=False):
            result = tool.boot_and_storage()
        self.assertTrue(result["luks_device_detected"])
        self.assertTrue(result["dm_crypt_device_detected"])
        self.assertTrue(result["mounts_present"]["/workspace"])
        self.assertNotIn("NEVER_EXPORT", json.dumps(result))
        self.assertNotIn("/sensitive/mount", json.dumps(result))

    def test_absence_is_unknown_not_false_secure_state(self):
        with mock.patch.object(tool, "execute", return_value=""):
            result = tool.service_state("ssh.service")
            storage = tool.boot_and_storage()
        self.assertEqual(result["is-active"], "unknown")
        self.assertEqual(storage["secure_boot"], "unknown")

    def test_json_output_is_valid_and_has_no_host_identity_fields(self):
        fixture = {
            "schema": tool.SCHEMA,
            "system": {"os": {"pretty_name": "Ubuntu 26.04"}},
            "hardware": {"cpu_model": "Intel"},
            "storage_and_boot": {"secure_boot": "unknown"},
            "security": {"sysctls": {}, "unit_states": {}},
            "packages": {},
            "limitations": [],
        }
        with mock.patch.object(tool, "inventory", return_value=fixture):
            with mock.patch("sys.argv", ["inventory", "--format", "json"]):
                output = io.StringIO()
                with redirect_stdout(output):
                    tool.main()
        self.assertEqual(json.loads(output.getvalue()), fixture)
        self.assertNotIn("hostname", output.getvalue().lower())
        self.assertNotIn("serial", output.getvalue().lower())


if __name__ == "__main__":
    main()
