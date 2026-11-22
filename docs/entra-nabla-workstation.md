# Personal Entra Nabla — workstation login via YubiKey

Nabla IaC is in [nabla-compose](https://github.com/AlbanAndrieu/nabla-compose/tree/master/terraform/entra).
This repository only owns the **interactive workstation client** and
read-only Microsoft Graph helper. Do not store account email, tenant ID,
PIN, key serial, client secrets or tokens in this public repository.

The operator has reported a personal Entra ID Free Workforce tenant and
two YubiKeys enrolled. This is **user-reported, not remotely attested**.

## Azure CLI startup errors (mise/uv/Python 3.14)

If the CLI reports `ai-examples: No module named 'pkg_resources'`,
`No module named 'rpds.rpds'` or tries to install an experimental
`account` extension, **do not interpret the warning as an Entra MFA
failure**. The global dev Python was 3.14 while Azure CLI 2.91.0 had
been installed into an interpreter-specific uv environment, and some
extensions install native wheels that may be incompatible with it.

This PR pins **only Azure CLI** to Python **3.12** (mise's PyPI-tool
`python` option), leaving global Python 3.14 unchanged. On a connected
workstation **after reviewing and merging the PR**:

```bash
mise install --force azure-cli
az version
# Optional: see installed extensions, not a tenant check.
az extension list --output table
```

`mise` needs a release supporting the per-tool `python` option.
If unsupported, update mise through the normal workstation process;
do **not** globally downgrade Python. If mise uses a lockfile, refresh
and commit it in the local PR workflow before relying on the new runtime.

The Nabla helper uses its own `AZURE_CONFIG_DIR`, which avoids
loading the optional extensions stored in the general
`~/.azure/cliextensions`. In the original profile, only if needed
and after confirming they are unused, review
`az extension remove --name ai-examples` and
`az extension remove --name account`.
Do not delete credentials or reinstall extensions indiscriminately.

For the tenant check, use `az account show --query tenantId -o tsv`
(**core CLI**), not the experimental `az account tenant list`
(which may trigger a dependency-install prompt).
`SyntaxWarning` under `azure/batch/models/_models.py` is a
non-fatal Python warning, not an authentication error.

## Bootstrap service principals (not yet authorized to provision)

After the tenant check succeeds, first create two **Entra app registrations**
(`entra-nabla-plan` and `entra-nabla-apply`) with **GitHub federated
credentials**, matching the respective protected environments in the
[nabla-compose runbook](https://github.com/AlbanAndrieu/nabla-compose/blob/master/docs/runbooks/entra-tenant-and-test-user.md).
In a single tenant, each registration has a corresponding service
principal (enterprise application); verify whether it already exists
before creating anything manually. **Never** use
`az ad sp create-for-rbac` with default Contributor scope or generate
a client secret. Review Microsoft Graph least privilege and admin consent
before approving any workload write. Hardware YubiKey touch is
required for the human-signed Terraform apply, not for each unattended
GitHub runner token exchange.

## Manual operator procedure

In a trusted terminal, supply the personal tenant GUID from the Entra
admin center (do not replace it with a company tenant):

```bash
export ENTRA_NABLA_TENANT_ID="<personal-tenant-GUID>"
mise run entra:login
mise run entra:verify-tenant
mise run entra:graph:me
mise run entra:graph:apps
```

`entra:login` opens the browser via Azure CLI; **select physical YubiKey
FIDO2/passkey**, enter its PIN/touch when requested. Repeat with the
secondary YubiKey to prove independent recovery. Register the keys on
the actual Entra identity's [Security info](https://mysignins.microsoft.com/security-info),
not just on the underlying personal Microsoft account.

The helper isolates Azure CLI's credential cache under
`~/.local/state/nabla-entra/azure-cli`, verifies the active tenant and
does not print access tokens. The `apps` command may be forbidden if
the signed-in identity lacks Graph application read permissions; that
is not evidence of a failed FIDO2 sign-in. Entra Free Security Defaults
can require MFA, but **forcing FIDO2-only via Conditional Access requires
Entra ID P1**.

For CI, continue to use **GitHub OIDC** and a separate human-signed
YubiKey SSH-FIDO2 Terraform approval; unattended CI runners cannot
perform browser FIDO2 touch.

References:
- https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively
- https://learn.microsoft.com/en-us/entra/identity/authentication/how-to-register-passkey-with-security-key
- https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust
