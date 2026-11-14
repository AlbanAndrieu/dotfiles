#!/usr/bin/env python3
"""Offline, value-blind contracts for compact global agent instructions."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    paths = {
        "claude": root / ".claude/CLAUDE.md",
        "codex": root / ".codex/AGENTS.md",
        "talos": root / ".agents/skills/talos-os-expert/SKILL.md",
        "reference": root / ".agents/skills/talos-os-expert/references/talos-guide.md",
    }
    for key, path in paths.items():
        if not path.is_file():
            errors.append(f"missing {key} instruction")
    if errors:
        return errors
    for key in ("claude", "codex", "talos"):
        source = paths[key].read_text(encoding="utf-8")
        if "AGENT_EXECUTION_MODE=offline" not in source:
            errors.append(f"{key}: missing offline mode")
        if "AGENT_EXECUTION_MODE=workstation" not in source:
            errors.append(f"{key}: missing workstation opt-in")
        if len(source.splitlines()) > 65:
            errors.append(f"{key}: excessive always-loaded instructions")
    skill = paths["talos"].read_text(encoding="utf-8")
    if "references/talos-guide.md" not in skill:
        errors.append("talos: missing progressive disclosure link")
    if paths["reference"].stat().st_size < 10000:
        errors.append("talos: extended reference may be truncated")
    return errors


if __name__ == "__main__":
    problems = validate()
    print("\n".join(problems) if problems else "PASS agent global modes and progressive disclosure")
    raise SystemExit(bool(problems))
