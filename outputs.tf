output "object_id" {
 description = "The object ID (GUID) of the Conditional Access policy in Azure AD — the primary handle for this resource. For azuread_conditional_access_policy the resource `id` IS the policy object ID."
 value = azuread_conditional_access_policy.this.id
}

output "id" {
 description = "The ID of the Conditional Access policy (identical to object_id). Exposed for callers that key on `id`."
 value = azuread_conditional_access_policy.this.id
}

output "display_name" {
 description = "The display name of the Conditional Access policy."
 value = azuread_conditional_access_policy.this.display_name
}

output "state" {
 description = "The enforcement state of the policy: enabled, disabled, or enabledForReportingButNotEnforced (Report-only)."
 value = azuread_conditional_access_policy.this.state
}
