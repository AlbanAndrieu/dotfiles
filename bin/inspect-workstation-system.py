#!/usr/bin/env python3
"""Run the canonical read-only inventory from the ansible-workstation checkout.

The collector moved there (scripts/audit-workstation-inventory.py, same JSON v1
plus provenance): this wrapper keeps the old command without a second copy.
"""

import os
from pathlib import Path
import sys

COLLECTOR = "scripts/audit-workstation-inventory.py"


def checkout():
    default = Path.home() / "w/ansible-workstation"
    return Path(os.environ.get("ANSIBLE_WORKSTATION_DIR") or default)


def main(argv):
    script = checkout() / COLLECTOR
    if not script.is_file():
        print(
            f"inventory collector not found: {script} (clone ansible-workstation or set ANSIBLE_WORKSTATION_DIR)",
            file=sys.stderr,
        )
        return 2
    os.execv(sys.executable, [sys.executable, "-B", str(script), *argv])


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
