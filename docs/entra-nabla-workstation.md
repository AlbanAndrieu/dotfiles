# Personal Entra Nabla — workstation login via YubiKey

Nabla IaC is in [nabla-compose](https://github.com/AlbanAndrieu/nabla-compose/tree/master/terraform/entra).
This repository only owns the **interactive workstation client** and
read-only Microsoft Graph helper. Do not store account email, tenant ID,
PIN, key serial, client secrets or tokens in this public repository.

The operator has reported a personal Entra ID Free Workforce tenant and
two YubiKeys enrolled. This is **user-reported, not remotely attested**.

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
