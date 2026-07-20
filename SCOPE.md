# SCOPE — terraform-azuread-conditional-access-policy

## In scope
- `azuread_conditional_access_policy.this`

## Data sources used
- None. (Earlier design notes referenced `data.azuread_named_location`, `data.azuread_service_principal`,
  and `data.azuread_group` lookups, but this module consumes object IDs passed in by the caller — the
  resolving data sources, if any, live in the upstream `terraform-azuread-named-location`,
  `terraform-azuread-service-principal`, and `terraform-azuread-group` modules. Keeping the boundary at "IDs in"
  avoids duplicate lookups and keeps this module a pure single-resource wrapper.)

## Graph API permissions required
| Permission | Type | Required for |
|---|---|---|
| `Policy.Read.All` | Application | Reading Conditional Access policies during plan/refresh |
| `Policy.ReadWrite.ConditionalAccess` | Application | Creating, updating, and deleting the policy |

Both require **admin consent**. Per the Microsoft Graph known-issues list, the *create* call may
additionally require consent to read scopes for the objects the policy references —
`Application.Read.All`, `Group.Read.All`, `User.Read.All`, `RoleManagement.Read.Directory`,
`Agreement.Read.All` — or it returns `403 Forbidden`. Grant these to the Terraform SP when the policy
references apps, groups, roles, users, or terms-of-use by ID. Device/app **filters** additionally
require the **Attribute Definition Reader** role.

## Emits
| Output | Description | Typically consumed by |
|---|---|---|
| `object_id` | Object ID (GUID) of the Conditional Access policy — for this resource `id` IS the object ID | Audit/coverage reporting, policy references, role-assignment / access-package resource associations |
| `id` | Identical to `object_id`; for callers that key on `id` | Callers expecting an `id` attribute |
| `display_name` | Policy display name | Logging, audit, sign-in log correlation |
| `state` | Enforcement state (`enabled` / `disabled` / `enabledForReportingButNotEnforced`) | Drift / compliance checks |

No output is `sensitive` or write-only — this resource exposes no credential material.

## Provider notes / gotchas (validated during authoring, 2026-06-18, azuread v3.x)
- **Secure default state.** `state` defaults to `enabledForReportingButNotEnforced` (Report-only).
  Validate impact in sign-in logs before promoting to `enabled`. Flipping `enabled` → Report-only
  *disables* enforcement.
- **`grant_controls` OR `session_controls` is mandatory.** A policy with neither is invalid — enforced
  by a cross-variable `validation {}` block, not just by the provider.
- **Break-glass is first-class.** `exclude_object_ids` (user object IDs) is merged into
  `conditions.users.excluded_users` via `distinct(concat(...))`. A broad "All users" policy with no
  exclusion can lock out every administrator — HIGH RISK. Prefer also excluding a dedicated break-glass
  group via `conditions.users.excluded_groups`.
- **`conditions.applications`: exactly one of `included_applications` / `included_user_actions`** —
  mutually exclusive (validated with an XOR condition).
- **`conditions.users` requires at least one included target** (users, groups, roles, or
  guests_or_external_users) — validated.
- **`devices` block removal is IMMUTABLE.** Adding a `devices` block to an existing policy is fine;
  removing a previously-set one forces resource recreation.
- **Built-in roles only.** `included_roles` / `excluded_roles` accept built-in directory role template
  IDs; custom and administrative-unit-scoped roles are not evaluated by Conditional Access.
- **Workload identities are separate.** User-scoped policies do not block service principals; use
  `conditions.client_applications` (Workload Identities Premium).
- **Licensing gates.** Sign-in frequency / persistent browser need P1; `sign_in_risk_levels` /
  `user_risk_levels` need P2 / Identity Protection; `service_principal_risk_levels` needs Workload
  Identities Premium.
- **Named locations must exist first.** `conditions.locations` references named-location object IDs.
- **Replication delay.** Policy and group-membership changes propagate to resource providers (Exchange
  Online, SharePoint Online) within ~2 hours (optimized) and up to ~24 hours otherwise; revoke refresh
  tokens to force immediate effect. No dry-run beyond Report-only mode.
- **Resource exclusion behavior change.** Microsoft is changing "All resources" policy exclusion
  behavior for low-privilege scopes in phases starting March 2026 — review before relying on app
  exclusions on broad policies.

## Design decisions
- **Single-resource wrapper, IDs in.** The module manages exactly one `azuread_conditional_access_policy`
  and takes all referenced principals/locations/apps as caller-supplied object IDs rather than resolving
  them via data sources — keeping the boundary clean and avoiding duplicate Graph lookups.
- **`state` modeled as optional with a secure default** rather than the provider's `Required`, to make
  the empty/typical call land in Report-only.
- **Outputs named `object_id` first** to match the azuread house standard, even though the underlying
  resource exports only `id` (which is the policy object ID); `id` is also emitted for convenience.

## Validation harness (offline gate passed)
- `terraform init -backend=false` ✅
- `terraform validate` ✅
- `terraform fmt -check` ✅
- Two-policy test harness (break-glass + nested guests/external_tenants + filters + grant + session)
  passed type-checking, all `validation {}` blocks, and `dynamic` rendering through `plan` — failing
  only at provider authentication (expected; requires live tenant credentials).
