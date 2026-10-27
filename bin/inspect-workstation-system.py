#!/usr/bin/env python3
"""Read-only Ubuntu inventory beyond HOME; print only, no secrets or IDs."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess

SCHEMA = "workstation-system-inventory/v1"
SERVICES = (
    "apparmor.service", "ufw.service", "nftables.service",
    "ssh.service", "fail2ban.service", "auditd.service",
    "unattended-upgrades.service", "fstrim.timer",
    "apt-daily.timer", "apt-daily-upgrade.timer",
)
PACKAGES = (
    "apparmor", "ufw", "nftables", "openssh-server", "fail2ban",
    "auditd", "unattended-upgrades", "cryptsetup", "fwupd",
    "intel-microcode", "amd64-microcode",
)
SYSCTLS = (
    "kernel.dmesg_restrict", "kernel.kptr_restrict",
    "kernel.yama.ptrace_scope", "kernel.unprivileged_bpf_disabled",
    "kernel.unprivileged_userns_clone", "fs.protected_hardlinks",
    "fs.protected_symlinks", "net.ipv4.ip_forward",
    "net.ipv4.conf.all.rp_filter",
)
MOUNTS = ("/", "/boot", "/boot/efi", "/workspace", "/data")
STATES = frozenset((
    "active", "inactive", "failed", "activating", "deactivating",
    "enabled", "disabled", "static", "masked", "indirect",
    "generated", "transient", "alias", "linked", "linked-runtime",
    "enabled-runtime",
))
COMMANDS = {
    "systemctl": "/usr/bin/systemctl",
    "dpkg-query": "/usr/bin/dpkg-query",
    "lsblk": "/usr/bin/lsblk",
    "mokutil": "/usr/bin/mokutil",
    "nvidia-smi": "/usr/bin/nvidia-smi",
}

def read(path, limit=4096):
    try:
        return Path(path).read_text(errors="replace")[:limit]
    except (OSError, ValueError):
        return ""

def execute(tool, *args):
    binary = COMMANDS[tool]
    if not Path(binary).is_file():
        return ""
    try:
        result = subprocess.run(
            [binary, *args], input="", capture_output=True,
            text=True, timeout=3, check=False,
            env={"PATH": "/usr/bin:/bin", "LC_ALL": "C"},
        )
        return result.stdout[:8192] if result.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""

def safe_label(value):
    # Only named hardware/model fields; never query serial/UUID/device IDs.
    return re.sub(r"[^a-zA-Z0-9 ._()+/-]", "", value.strip())[:100] or None

def os_release():
    allowed = {"PRETTY_NAME", "ID", "VERSION_ID"}
    result = {}
    for line in read("/etc/os-release").splitlines():
        key, sep, raw = line.partition("=")
        if sep and key in allowed:
            result[key.lower()] = safe_label(raw.strip().strip('"'))
    return result

def cpu_memory():
    cpu = None
    for line in read("/proc/cpuinfo", 8192).splitlines():
        if line.startswith("model name"):
            cpu = safe_label(line.partition(":")[2])
            break
    match = re.search(r"^MemTotal:\s+(\d+)\s+kB", read("/proc/meminfo"), re.M)
    memory_gib = round(int(match.group(1)) / 1048576, 1) if match else None
    return {"cpu_model": cpu, "memory_gib": memory_gib}

def service_state(unit):
    result = {}
    for action in ("is-active", "is-enabled"):
        value = execute("systemctl", action, unit).strip()
        result[action] = value if value in STATES else "unknown"
    return result

def package_version(package):
    value = execute("dpkg-query", "-W", "-f=${Version}", package).strip()
    return value[:64] if re.fullmatch(r"[a-zA-Z0-9.+:~_-]{1,64}", value) else None

def boot_and_storage():
    raw = execute("lsblk", "--json", "--output", "TYPE,FSTYPE,MOUNTPOINTS")
    mounts = set()
    luks, mapper = False, False
    def visit(items):
        nonlocal luks, mapper
        for item in items:
            if not isinstance(item, dict):
                continue
            luks |= item.get("fstype") == "crypto_LUKS"
            mapper |= item.get("type") == "crypt"
            for value in item.get("mountpoints") or []:
                if value in MOUNTS:
                    mounts.add(value)
            visit(item.get("children") or [])
    try:
        visit(json.loads(raw).get("blockdevices", []))
    except (ValueError, AttributeError, TypeError, RecursionError):
        pass
    secure = execute("mokutil", "--sb-state").lower()
    secure_boot = (
        "enabled" if "secureboot enabled" in secure
        else "disabled" if "secureboot disabled" in secure
        else "unknown"
    )
    return {
        "mounts_present": {m: m in mounts for m in MOUNTS},
        "luks_device_detected": luks,
        "dm_crypt_device_detected": mapper,
        "uefi_detected": Path("/sys/firmware/efi").is_dir(),
        "secure_boot": secure_boot,
        "tpm_device_detected": Path("/sys/class/tpm/tpm0").exists(),
    }

def security():
    sysctls = {}
    for key in SYSCTLS:
        raw = read("/proc/sys/" + key.replace(".", "/")).strip()
        sysctls[key] = raw if re.fullmatch(r"[0-9]{1,3}", raw) else None
    aa = read("/sys/module/apparmor/parameters/enabled").strip()
    return {
        "apparmor_kernel_enabled": aa == "Y" if aa in ("Y", "N") else None,
        "sysctls": sysctls,
        "unit_states": {unit: service_state(unit) for unit in SERVICES},
    }

def inventory():
    nvidia = execute(
        "nvidia-smi", "--query-gpu=name,driver_version",
        "--format=csv,noheader,nounits",
    ).splitlines()
    gpu = nvidia[0].split(",", 1) if nvidia else []
    return {
        "schema": SCHEMA,
        "system": {
            "os": os_release(),
            "kernel_release": safe_label(os.uname().release),
            "architecture": safe_label(os.uname().machine),
        },
        "hardware": {
            **cpu_memory(),
            "motherboard_model": safe_label(read("/sys/class/dmi/id/board_name")),
            "bios_version": safe_label(read("/sys/class/dmi/id/bios_version")),
            "bios_date": safe_label(read("/sys/class/dmi/id/bios_date")),
            "nvidia_gpu": safe_label(gpu[0]) if gpu else None,
            "nvidia_driver": safe_label(gpu[1]) if len(gpu) > 1 else None,
        },
        "storage_and_boot": boot_and_storage(),
        "security": security(),
        "packages": {name: package_version(name) for name in PACKAGES},
        "limitations": [
            "Observed locally without sudo; missing means unknown.",
            "Unit state does not prove firewall policy or SSH security.",
            "LUKS detection does not prove root filesystem encryption.",
            "No hostnames, users, IP/MAC, UUID, serial numbers or secrets.",
            "No data is written to disk by this script.",
        ],
    }

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--format", choices=("summary", "json"), default="summary")
    args = p.parse_args()
    data = inventory()
    if args.format == "json":
        print(json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False))
    else:
        print("WORKSTATION SYSTEM INVENTORY (read only, identifiers omitted)")
        for key in ("system", "hardware", "storage_and_boot", "security", "packages"):
            print("\n" + key.upper())
            print(json.dumps(data[key], indent=2, sort_keys=True, ensure_ascii=False))
        print("\nNOTES: no hostname, IP, MAC, UUID, serial or secrets. Unknown != fail.")

if __name__ == "__main__":
    main()
