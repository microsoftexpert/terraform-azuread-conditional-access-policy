variable "display_name" {
 description = "The friendly name for this Conditional Access policy. Shown in the Microsoft Entra admin center. Use a meaningful naming standard, e.g. \"CA001-AllUsers-Require-MFA\"."
 type = string

 validation {
 condition = length(trimspace(var.display_name)) > 0
 error_message = "display_name must be a non-empty string."
 }
}

variable "state" {
 description = <<EOT
Enforcement state of the policy.
 enabled = policy is live and enforced
 disabled = policy exists but is not evaluated
 enabledForReportingButNotEnforced = Report-only — evaluated and logged, NOT enforced

Secure-by-default: this module defaults to "enabledForReportingButNotEnforced" (Report-only).
NEVER promote a new policy straight to "enabled" — validate impact in Report-only first
using sign-in logs, then flip to "enabled".
EOT
 type = string
 default = "enabledForReportingButNotEnforced"

 validation {
 condition = contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], var.state)
 error_message = "state must be one of: enabled, disabled, enabledForReportingButNotEnforced."
 }
}

variable "conditions" {
 description = <<EOT
The signals that scope the policy. A policy applies only when ALL specified conditions match.
`applications`, `client_app_types`, and `users` are mandatory; everything else is optional.
{
 client_app_types = list(string) # REQUIRED — non-empty. One or more of: all, browser, mobileAppsAndDesktopClients, exchangeActiveSync, easSupported, other
 sign_in_risk_levels = optional(list(string)) # low, medium, high, hidden, none, unknownFutureValue (Identity Protection / P2)
 user_risk_levels = optional(list(string)) # low, medium, high, hidden, none, unknownFutureValue (Identity Protection / P2)
 service_principal_risk_levels = optional(list(string)) # low, medium, high, none, unknownFutureValue (Workload Identities Premium)
 insider_risk_levels = optional(string) # minor, moderate, elevated, unknownFutureValue (requires Insider Risk integration)
 authentication_flow_transfer_methods = optional(list(string)) # authenticationTransfer, deviceCodeFlow

 applications = object({ # REQUIRED block
 included_applications = optional(list(string)) # app (client) IDs, or "All" / "None" / "Office365". Mutually exclusive with included_user_actions
 excluded_applications = optional(list(string)) # app (client) IDs, or "Office365"
 included_user_actions = optional(list(string)) # urn:user:registerdevice, urn:user:registersecurityinfo. Mutually exclusive with included_applications
 filter = optional(object({ # requires the Attribute Definition Reader role
 mode = string # include | exclude
 rule = string
 }))
 })

 users = object({ # REQUIRED block — at least one included_* must be set
 included_users = optional(list(string)) # user object IDs, or "None" / "All" / "GuestsOrExternalUsers"
 excluded_users = optional(list(string)) # user object IDs (break-glass accounts are merged in via var.exclude_object_ids)
 included_groups = optional(list(string)) # group object IDs
 excluded_groups = optional(list(string)) # group object IDs (prefer excluding a break-glass GROUP here)
 included_roles = optional(list(string)) # directory role template IDs (built-in roles only)
 excluded_roles = optional(list(string)) # directory role template IDs
 included_guests_or_external_users = optional(object({
 guest_or_external_user_types = list(string) # b2bCollaborationGuest, b2bCollaborationMember, b2bDirectConnectUser, internalGuest, none, otherExternalUser, serviceProvider, unknownFutureValue
 external_tenants = optional(object({
 membership_kind = string # all | enumerated | unknownFutureValue
 members = optional(list(string)) # tenant IDs — only when membership_kind = "enumerated"
 }))
 }))
 excluded_guests_or_external_users = optional(object({
 guest_or_external_user_types = list(string)
 external_tenants = optional(object({
 membership_kind = string
 members = optional(list(string))
 }))
 }))
 })

 client_applications = optional(object({
 included_service_principals = optional(list(string)) # SP object IDs, or "ServicePrincipalsInMyTenant". Mandatory when excluded_service_principals is set
 excluded_service_principals = optional(list(string))
 filter = optional(object({
 mode = string # include | exclude
 rule = string
 }))
 }))

 devices = optional(object({ # IMMUTABLE removal — removing a previously-set devices block forces resource recreation
 filter = optional(object({
 mode = string # include | exclude
 rule = string
 }))
 }))

 locations = optional(object({
 included_locations = list(string) # named_location object IDs, or "All" / "AllTrusted". Named locations MUST exist first
 excluded_locations = optional(list(string)) # named_location object IDs, or "AllTrusted"
 }))

 platforms = optional(object({
 included_platforms = list(string) # all, android, iOS, linux, macOS, windows, windowsPhone, unknownFutureValue
 excluded_platforms = optional(list(string))
 }))
}
EOT
 type = object({
 client_app_types = list(string)
 sign_in_risk_levels = optional(list(string))
 user_risk_levels = optional(list(string))
 service_principal_risk_levels = optional(list(string))
 insider_risk_levels = optional(string)
 authentication_flow_transfer_methods = optional(list(string))

 applications = object({
 included_applications = optional(list(string))
 excluded_applications = optional(list(string))
 included_user_actions = optional(list(string))
 filter = optional(object({
 mode = string
 rule = string
 }))
 })

 users = object({
 included_users = optional(list(string))
 excluded_users = optional(list(string))
 included_groups = optional(list(string))
 excluded_groups = optional(list(string))
 included_roles = optional(list(string))
 excluded_roles = optional(list(string))
 included_guests_or_external_users = optional(object({
 guest_or_external_user_types = list(string)
 external_tenants = optional(object({
 membership_kind = string
 members = optional(list(string))
 }))
 }))
 excluded_guests_or_external_users = optional(object({
 guest_or_external_user_types = list(string)
 external_tenants = optional(object({
 membership_kind = string
 members = optional(list(string))
 }))
 }))
 })

 client_applications = optional(object({
 included_service_principals = optional(list(string))
 excluded_service_principals = optional(list(string))
 filter = optional(object({
 mode = string
 rule = string
 }))
 }))

 devices = optional(object({
 filter = optional(object({
 mode = string
 rule = string
 }))
 }))

 locations = optional(object({
 included_locations = list(string)
 excluded_locations = optional(list(string))
 }))

 platforms = optional(object({
 included_platforms = list(string)
 excluded_platforms = optional(list(string))
 }))
 })

 validation {
 condition = length(var.conditions.client_app_types) > 0 && alltrue([
 for t in var.conditions.client_app_types:
 contains(["all", "browser", "mobileAppsAndDesktopClients", "exchangeActiveSync", "easSupported", "other"], t)
 ])
 error_message = "conditions.client_app_types must be a non-empty list drawn from: all, browser, mobileAppsAndDesktopClients, exchangeActiveSync, easSupported, other."
 }

 validation {
 condition = (try(var.conditions.applications.included_applications, null) != null) != (try(var.conditions.applications.included_user_actions, null) != null)
 error_message = "conditions.applications: exactly one of included_applications or included_user_actions must be specified (they are mutually exclusive)."
 }

 validation {
 condition = anytrue([
 try(var.conditions.users.included_users, null) != null,
 try(var.conditions.users.included_groups, null) != null,
 try(var.conditions.users.included_roles, null) != null,
 try(var.conditions.users.included_guests_or_external_users, null) != null,
 ])
 error_message = "conditions.users must specify at least one of: included_users, included_groups, included_roles, included_guests_or_external_users."
 }

 validation {
 condition = alltrue([
 for r in(var.conditions.sign_in_risk_levels == null ? []: var.conditions.sign_in_risk_levels):
 contains(["low", "medium", "high", "hidden", "none", "unknownFutureValue"], r)
 ])
 error_message = "conditions.sign_in_risk_levels entries must each be one of: low, medium, high, hidden, none, unknownFutureValue."
 }

 validation {
 condition = alltrue([
 for r in(var.conditions.user_risk_levels == null ? []: var.conditions.user_risk_levels):
 contains(["low", "medium", "high", "hidden", "none", "unknownFutureValue"], r)
 ])
 error_message = "conditions.user_risk_levels entries must each be one of: low, medium, high, hidden, none, unknownFutureValue."
 }

 validation {
 condition = alltrue([
 for r in(var.conditions.service_principal_risk_levels == null ? []: var.conditions.service_principal_risk_levels):
 contains(["low", "medium", "high", "none", "unknownFutureValue"], r)
 ])
 error_message = "conditions.service_principal_risk_levels entries must each be one of: low, medium, high, none, unknownFutureValue."
 }

 validation {
 condition = var.conditions.insider_risk_levels == null || contains(["minor", "moderate", "elevated", "unknownFutureValue"], coalesce(var.conditions.insider_risk_levels, "minor"))
 error_message = "conditions.insider_risk_levels must be one of: minor, moderate, elevated, unknownFutureValue."
 }

 validation {
 condition = alltrue([
 for m in(var.conditions.authentication_flow_transfer_methods == null ? []: var.conditions.authentication_flow_transfer_methods):
 contains(["authenticationTransfer", "deviceCodeFlow"], m)
 ])
 error_message = "conditions.authentication_flow_transfer_methods entries must each be one of: authenticationTransfer, deviceCodeFlow."
 }

 validation {
 condition = alltrue([
 for p in concat(try(var.conditions.platforms.included_platforms, []),
 try(var.conditions.platforms.excluded_platforms, []),): contains(["all", "android", "iOS", "linux", "macOS", "windows", "windowsPhone", "unknownFutureValue"], p)
 ])
 error_message = "conditions.platforms.included_platforms / excluded_platforms entries must each be one of: all, android, iOS, linux, macOS, windows, windowsPhone, unknownFutureValue."
 }

 validation {
 condition = try(var.conditions.platforms, null) == null || length(try(var.conditions.platforms.included_platforms, [])) > 0
 error_message = "conditions.platforms.included_platforms is required and must be non-empty when a platforms block is supplied."
 }

 validation {
 condition = try(var.conditions.locations, null) == null || length(try(var.conditions.locations.included_locations, [])) > 0
 error_message = "conditions.locations.included_locations is required and must be non-empty when a locations block is supplied."
 }

 validation {
 condition = alltrue([
 for f in compact([
 try(var.conditions.applications.filter.mode, ""),
 try(var.conditions.client_applications.filter.mode, ""),
 try(var.conditions.devices.filter.mode, ""),
 ]): contains(["include", "exclude"], f)
 ])
 error_message = "Any filter.mode (applications / client_applications / devices) must be one of: include, exclude."
 }

 validation {
 condition = alltrue([
 for k in compact([
 try(var.conditions.users.included_guests_or_external_users.external_tenants.membership_kind, ""),
 try(var.conditions.users.excluded_guests_or_external_users.external_tenants.membership_kind, ""),
 ]): contains(["all", "enumerated", "unknownFutureValue"], k)
 ])
 error_message = "guests_or_external_users.external_tenants.membership_kind must be one of: all, enumerated, unknownFutureValue."
 }

 validation {
 condition = alltrue([
 for t in concat(try(var.conditions.users.included_guests_or_external_users.guest_or_external_user_types, []),
 try(var.conditions.users.excluded_guests_or_external_users.guest_or_external_user_types, []),): contains(["b2bCollaborationGuest", "b2bCollaborationMember", "b2bDirectConnectUser", "internalGuest", "none", "otherExternalUser", "serviceProvider", "unknownFutureValue"], t)
 ])
 error_message = "guests_or_external_users.guest_or_external_user_types entries must each be one of: b2bCollaborationGuest, b2bCollaborationMember, b2bDirectConnectUser, internalGuest, none, otherExternalUser, serviceProvider, unknownFutureValue."
 }
}

variable "exclude_object_ids" {
 description = <<EOT
Break-glass / emergency-access exclusions. A list of USER object IDs (GUIDs) that are merged
into conditions.users.excluded_users so they can never be locked out by this policy.

⚠️ BREAK-GLASS PATTERN — Microsoft and require that EVERY policy targeting broad scope
("All" users/apps) explicitly exclude at least one emergency-access account. A misconfigured
"All Users" policy with no exclusion can lock every administrator out of the tenant with no
recovery path short of a Microsoft support ticket.

Recommended practice:
 - Maintain 2+ cloud-only break-glass accounts (no MFA dependency on a single factor).
 - Put them in a dedicated break-glass GROUP and exclude that group via
 conditions.users.excluded_groups, OR pass their object IDs here.
 - Monitor sign-ins for these accounts with a dedicated alert.

Defaults to [] — but supplying break-glass exclusions is STRONGLY recommended for any
policy that includes "All" users or applications.
EOT
 type = list(string)
 default = []
}

variable "grant_controls" {
 description = <<EOT
Access controls enforced to GRANT access (e.g. require MFA, compliant device). Null = no grant controls.
At least one of `grant_controls` or `session_controls` must be supplied for a valid policy.
At least one of authentication_strength_policy_id, built_in_controls, or terms_of_use must be set within the block.
{
 operator = string # REQUIRED — "AND" (all controls) or "OR" (any control)
 built_in_controls = optional(list(string)) # block, mfa, approvedApplication, compliantApplication, compliantDevice, domainJoinedDevice, passwordChange, unknownFutureValue
 custom_authentication_factors = optional(list(string)) # custom control IDs
 terms_of_use = optional(list(string)) # terms-of-use agreement IDs
 authentication_strength_policy_id = optional(string) # auth strength policy ID (prefix hard-coded IDs with /policies/authenticationStrengthPolicies/)
}
NOTE: "block" cannot be combined with any other built-in control.
EOT
 type = object({
 operator = string
 built_in_controls = optional(list(string))
 custom_authentication_factors = optional(list(string))
 terms_of_use = optional(list(string))
 authentication_strength_policy_id = optional(string)
 })
 default = null

 validation {
 condition = var.grant_controls == null || contains(["AND", "OR"], try(var.grant_controls.operator, ""))
 error_message = "grant_controls.operator must be one of: AND, OR."
 }

 validation {
 condition = alltrue([
 for c in(try(var.grant_controls.built_in_controls, null) == null ? []: var.grant_controls.built_in_controls):
 contains(["block", "mfa", "approvedApplication", "compliantApplication", "compliantDevice", "domainJoinedDevice", "passwordChange", "unknownFutureValue"], c)
 ])
 error_message = "grant_controls.built_in_controls entries must each be one of: block, mfa, approvedApplication, compliantApplication, compliantDevice, domainJoinedDevice, passwordChange, unknownFutureValue."
 }

 validation {
 condition = var.grant_controls == null || anytrue([
 try(var.grant_controls.built_in_controls, null) != null,
 try(var.grant_controls.terms_of_use, null) != null,
 try(var.grant_controls.custom_authentication_factors, null) != null,
 try(var.grant_controls.authentication_strength_policy_id, null) != null,
 ])
 error_message = "grant_controls requires at least one of: built_in_controls, terms_of_use, custom_authentication_factors, authentication_strength_policy_id."
 }
}

variable "session_controls" {
 description = <<EOT
Controls applied to the session AFTER sign-in (sign-in frequency, persistent browser, etc.).
Null = no session controls. At least one of `grant_controls` or `session_controls` must be supplied.
{
 application_enforced_restrictions_enabled = optional(bool, false) # Office365/Exchange/SharePoint only
 cloud_app_security_policy = optional(string) # blockDownloads, mcasConfigured, monitorOnly, unknownFutureValue
 disable_resilience_defaults = optional(bool, false) # true = block sign-ins during an Entra outage (no resilience fallback)
 persistent_browser_mode = optional(string) # always | never
 sign_in_frequency = optional(number) # count of sign_in_frequency_period; requires P1/P2
 sign_in_frequency_authentication_type = optional(string, "primaryAndSecondaryAuthentication") # primaryAndSecondaryAuthentication | secondaryAuthentication
 sign_in_frequency_interval = optional(string, "timeBased") # timeBased | everyTime
 sign_in_frequency_period = optional(string) # hours | days; required when sign_in_frequency is set
}
NOTE: sign-in frequency and persistent browser session controls require Entra ID P1 or P2 licensing.
EOT
 type = object({
 application_enforced_restrictions_enabled = optional(bool, false)
 cloud_app_security_policy = optional(string)
 disable_resilience_defaults = optional(bool, false)
 persistent_browser_mode = optional(string)
 sign_in_frequency = optional(number)
 sign_in_frequency_authentication_type = optional(string, "primaryAndSecondaryAuthentication")
 sign_in_frequency_interval = optional(string, "timeBased")
 sign_in_frequency_period = optional(string)
 })
 default = null

 validation {
 condition = var.grant_controls != null || var.session_controls != null
 error_message = "At least one of grant_controls or session_controls must be specified — a Conditional Access policy with neither is invalid."
 }

 validation {
 condition = var.session_controls == null || try(var.session_controls.cloud_app_security_policy, null) == null || contains(["blockDownloads", "mcasConfigured", "monitorOnly", "unknownFutureValue"], coalesce(try(var.session_controls.cloud_app_security_policy, null), "monitorOnly"))
 error_message = "session_controls.cloud_app_security_policy must be one of: blockDownloads, mcasConfigured, monitorOnly, unknownFutureValue."
 }

 validation {
 condition = var.session_controls == null || try(var.session_controls.persistent_browser_mode, null) == null || contains(["always", "never"], coalesce(try(var.session_controls.persistent_browser_mode, null), "never"))
 error_message = "session_controls.persistent_browser_mode must be one of: always, never."
 }

 validation {
 condition = var.session_controls == null || contains(["primaryAndSecondaryAuthentication", "secondaryAuthentication"], try(var.session_controls.sign_in_frequency_authentication_type, "primaryAndSecondaryAuthentication"))
 error_message = "session_controls.sign_in_frequency_authentication_type must be one of: primaryAndSecondaryAuthentication, secondaryAuthentication."
 }

 validation {
 condition = var.session_controls == null || contains(["timeBased", "everyTime"], try(var.session_controls.sign_in_frequency_interval, "timeBased"))
 error_message = "session_controls.sign_in_frequency_interval must be one of: timeBased, everyTime."
 }

 validation {
 condition = var.session_controls == null || try(var.session_controls.sign_in_frequency_period, null) == null || contains(["hours", "days"], coalesce(try(var.session_controls.sign_in_frequency_period, null), "hours"))
 error_message = "session_controls.sign_in_frequency_period must be one of: hours, days."
 }

 validation {
 condition = var.session_controls == null || try(var.session_controls.sign_in_frequency, null) == null || try(var.session_controls.sign_in_frequency_period, null) != null
 error_message = "session_controls.sign_in_frequency_period is required when session_controls.sign_in_frequency is set."
 }
}

variable "timeouts" {
 description = "Optional Terraform operation timeouts for this resource (e.g. \"5m\")."
 type = object({
 create = optional(string)
 read = optional(string)
 update = optional(string)
 delete = optional(string)
 })
 default = {}
}
