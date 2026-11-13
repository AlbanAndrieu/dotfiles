---
name: roadmap-pass
description: How to run a pass over a homelab repository roadmap (nabla-compose, fastapi-sample, ansible-workstation, nabla-yubikey, nabla-openclaw) with little operator interaction - walk every item, park blockers in the dated runbook, ask all questions once at the end, then reconcile the roadmap. Use whenever the user asks to work through, continue or resume a roadmap, or a list of roadmap items (Q8, B12...).
---

# Roadmap pass

The operator wants progress without interruptions: walk the **whole**
roadmap, do everything that needs no decision, and come back **once**.

## Repositories

Checkouts live in `~/w/<repo>`; the default branch is `master`.

| Repository | Roadmap |
|---|---|
| nabla-compose | `docs/roadmap.md` |
| fastapi-sample | `docs/engineering-roadmap.md`, `docs/homelab-security-roadmap.md` |
| ansible-workstation | `docs/roadmap-workstation.md` |
| nabla-yubikey | `docs/roadmap.md`, `docs/roadmap-vault-pki.md`, `docs/roadmap-workstation-yubikey.md` |
| nabla-openclaw | `docs/roadmap.md` |

Parked blockers go in `docs/runbooks/<YYYY-MM-DD>-roadmap-pass-blockers.md`
of the repository being worked (create it when missing). An item that
belongs to another repository is done there, on that repository's branch.

## Before starting

- `git fetch origin`, then read `git log origin/master` and the newest
  `docs/runbooks/*-roadmap-pass-blockers.md` on `origin/master`. Other
  Claude sessions work the same roadmap (`ListAgents` shows them): drop
  what they already shipped.
- Reuse the open PR branch (`gh pr list --author @me --state open`). The
  checkout may be shared with another session: never switch branch, stash,
  stage or commit what it changed. A checkout another session has staged
  files in is off limits: park the change.

## During the pass

- Go item by item without stopping for questions. Do all the work that is
  autonomous: code, tests, docs, read-only checks (`--check`, plans,
  queries), and mutations the operator already approved **in this
  conversation**.
- Read-only first: run the `--check` or plan mode, then `--apply` only
  under an existing OK. An OK covers the plan that was shown; a new
  dependency found on the way (an NFS export, a client mount, more data)
  is a new question. "continue" is never an OK for a gated mutation.
- When blocked (decision, OK for a mutation, missing access, a classifier
  denial), record it in the dated runbook with the evidence and the exact
  command, and move on to the next item. Never work around a denial: hand
  the command over at the end.
- Secrets stay value-blind: pipe them, never print them, check by names,
  booleans, modes or hashes.
- TrueNAS: follow the `truenas-ops` skill. One App at a time, health
  checked after each. Long operations under `systemd-run` with a log in
  `/mnt/cpool/var/nabla/ops-logs/`, watched with one background wait
  instead of polling.
- One commit per item with its test, pre-commit on the changed files,
  never bypass a hook. Push to the open PR branch when a push was
  approved; if the gate is blocked by someone else's change, park it. If
  the PR was merged meanwhile (remote branch gone), redo the PR lookup
  instead of recreating the old branch.
- Every few steps, tell the operator in one short French line what you
  are doing.

## At the end of the pass

1. Reconcile without being asked: update the roadmap (statuses
   CODED / VERIFIED / PLANIFIED, dated evidence) and the runbook from
   what was done and observed; commit.
2. Ask every parked question **once**, in plain French text (not the
   AskUserQuestion popup), numbered, each with the exact command or plan,
   its impact and its rollback.
3. List the files created and modified, and the commands the operator
   must run themselves.
