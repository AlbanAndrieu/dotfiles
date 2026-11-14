---
name: talos-os-expert
description: Talos Linux / Kubernetes immutable nodes, CSI/NFS, security and diagnostics; use on explicit Talos tasks, with live operations only from a connected workstation.
---

# Talos OS expert — minimal task router

Read the project `AGENTS.md` and verify the **installed** Talos/Kubernetes versions, network, CSI driver and current cluster state before selecting any example.

## Execution mode

- **Codex offline / API-only:** inspect versioned `machineconfig`, manifests, Helm and test contracts; run available static checks and propose a targeted workstation acceptance procedure. Never attempt `talosctl`/LAN/secret commands or assert node health.
- **Claude Code on a connected workstation:** explicit `AGENT_EXECUTION_MODE=workstation`; use installed `talosctl`, `kubectl` and local CPU for scoped read-only preflight, bounded by node/namespace/timeouts. A live mutation needs the project authorization, impact/recovery plan and rollback proof.
- Talos has **no SSH/host apt**. Confirm etcd backup, API/RBAC, CNI, DNS, storage class, reclaim and multi-worker RWX before moving stateful workloads. Never silently replace the actual TrueNAS CSI driver with a historical `democratic-csi` reference.
- Do not apply old default versions, disk paths, IPs or secrets from examples. Security and integrity are mandatory, even when homelab downtime is acceptable.

## Routing

| Task | Read only the matching section of the reference |
| --- | --- |
| Bootstrap, nodes, machine config | Cluster provisioning and machine configuration |
| Storage migration | CSI, NFS, PVC, data durability and reclaim |
| Network/ingress | CNI, NetworkPolicy, API reachability, DNS |
| Upgrade/security | Talos release compatibility, encryption, etcd snapshots, rollback |
| Troubleshooting | Specific node health, logs and bounded diagnostics |

Extended material: [Talos operational examples and reference](references/talos-guide.md). Many legacy examples predate the installed cluster: treat them as **illustrations requiring current-version validation**, not copy/paste instructions.
