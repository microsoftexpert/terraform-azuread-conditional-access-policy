resource "azuread_conditional_access_policy" "this" {
 display_name = var.display_name
 state = var.state

 conditions {
 client_app_types = var.conditions.client_app_types
 authentication_flow_transfer_methods = try(var.conditions.authentication_flow_transfer_methods, null)
 insider_risk_levels = try(var.conditions.insider_risk_levels, null)
 service_principal_risk_levels = try(var.conditions.service_principal_risk_levels, null)
 sign_in_risk_levels = try(var.conditions.sign_in_risk_levels, null)
 user_risk_levels = try(var.conditions.user_risk_levels, null)

 applications {
 included_applications = try(var.conditions.applications.included_applications, null)
 excluded_applications = try(var.conditions.applications.excluded_applications, null)
 included_user_actions = try(var.conditions.applications.included_user_actions, null)

 dynamic "filter" {
 for_each = try(var.conditions.applications.filter, null) != null ? [var.conditions.applications.filter]: []
 content {
 mode = filter.value.mode
 rule = filter.value.rule
 }
 }
 }

 users {
 included_users = try(var.conditions.users.included_users, null)
 included_groups = try(var.conditions.users.included_groups, null)
 included_roles = try(var.conditions.users.included_roles, null)

 # Break-glass / emergency-access accounts (var.exclude_object_ids) are merged into the
 # excluded_users set so they can never be locked out by this policy.
 excluded_users = length(distinct(concat(try(var.conditions.users.excluded_users, []), var.exclude_object_ids))) > 0 ? distinct(concat(try(var.conditions.users.excluded_users, []), var.exclude_object_ids)): null
 excluded_groups = try(var.conditions.users.excluded_groups, null)
 excluded_roles = try(var.conditions.users.excluded_roles, null)

 dynamic "included_guests_or_external_users" {
 for_each = try(var.conditions.users.included_guests_or_external_users, null) != null ? [var.conditions.users.included_guests_or_external_users]: []
 content {
 guest_or_external_user_types = included_guests_or_external_users.value.guest_or_external_user_types

 dynamic "external_tenants" {
 for_each = try(included_guests_or_external_users.value.external_tenants, null) != null ? [included_guests_or_external_users.value.external_tenants]: []
 content {
 membership_kind = external_tenants.value.membership_kind
 members = try(external_tenants.value.members, null)
 }
 }
 }
 }

 dynamic "excluded_guests_or_external_users" {
 for_each = try(var.conditions.users.excluded_guests_or_external_users, null) != null ? [var.conditions.users.excluded_guests_or_external_users]: []
 content {
 guest_or_external_user_types = excluded_guests_or_external_users.value.guest_or_external_user_types

 dynamic "external_tenants" {
 for_each = try(excluded_guests_or_external_users.value.external_tenants, null) != null ? [excluded_guests_or_external_users.value.external_tenants]: []
 content {
 membership_kind = external_tenants.value.membership_kind
 members = try(external_tenants.value.members, null)
 }
 }
 }
 }
 }

 dynamic "client_applications" {
 for_each = try(var.conditions.client_applications, null) != null ? [var.conditions.client_applications]: []
 content {
 included_service_principals = try(client_applications.value.included_service_principals, null)
 excluded_service_principals = try(client_applications.value.excluded_service_principals, null)

 dynamic "filter" {
 for_each = try(client_applications.value.filter, null) != null ? [client_applications.value.filter]: []
 content {
 mode = filter.value.mode
 rule = filter.value.rule
 }
 }
 }
 }

 dynamic "devices" {
 for_each = try(var.conditions.devices, null) != null ? [var.conditions.devices]: []
 content {
 dynamic "filter" {
 for_each = try(devices.value.filter, null) != null ? [devices.value.filter]: []
 content {
 mode = filter.value.mode
 rule = filter.value.rule
 }
 }
 }
 }

 dynamic "locations" {
 for_each = try(var.conditions.locations, null) != null ? [var.conditions.locations]: []
 content {
 included_locations = locations.value.included_locations
 excluded_locations = try(locations.value.excluded_locations, null)
 }
 }

 dynamic "platforms" {
 for_each = try(var.conditions.platforms, null) != null ? [var.conditions.platforms]: []
 content {
 included_platforms = platforms.value.included_platforms
 excluded_platforms = try(platforms.value.excluded_platforms, null)
 }
 }
 }

 dynamic "grant_controls" {
 for_each = var.grant_controls != null ? [var.grant_controls]: []
 content {
 operator = grant_controls.value.operator
 built_in_controls = try(grant_controls.value.built_in_controls, null)
 custom_authentication_factors = try(grant_controls.value.custom_authentication_factors, null)
 terms_of_use = try(grant_controls.value.terms_of_use, null)
 authentication_strength_policy_id = try(grant_controls.value.authentication_strength_policy_id, null)
 }
 }

 dynamic "session_controls" {
 for_each = var.session_controls != null ? [var.session_controls]: []
 content {
 application_enforced_restrictions_enabled = try(session_controls.value.application_enforced_restrictions_enabled, null)
 cloud_app_security_policy = try(session_controls.value.cloud_app_security_policy, null)
 disable_resilience_defaults = try(session_controls.value.disable_resilience_defaults, null)
 persistent_browser_mode = try(session_controls.value.persistent_browser_mode, null)
 sign_in_frequency = try(session_controls.value.sign_in_frequency, null)
 sign_in_frequency_authentication_type = try(session_controls.value.sign_in_frequency_authentication_type, null)
 sign_in_frequency_interval = try(session_controls.value.sign_in_frequency_interval, null)
 sign_in_frequency_period = try(session_controls.value.sign_in_frequency_period, null)
 }
 }

 dynamic "timeouts" {
 for_each = length([for v in var.timeouts: v if v != null]) > 0 ? [1]: []
 content {
 create = try(var.timeouts.create, null)
 read = try(var.timeouts.read, null)
 update = try(var.timeouts.update, null)
 delete = try(var.timeouts.delete, null)
 }
 }
}
