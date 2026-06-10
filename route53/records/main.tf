locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

locals {
  # Terragrunt users have to provide `records_jsonencoded` as jsonencode()'d string.
  # See details: https://github.com/gruntwork-io/terragrunt/issues/1211
  # Normalize JSON-decoded records to the same shape as the typed `records` variable.
  records_json = [
    for r in try(jsondecode(var.records_jsonencoded), []) : {
      key                              = try(r.key, null)
      name                             = r.name
      type                             = r.type
      ttl                              = try(r.ttl, null)
      records                          = try(r.records, null)
      set_identifier                   = try(r.set_identifier, null)
      health_check_id                  = try(r.health_check_id, null)
      multivalue_answer_routing_policy = try(r.multivalue_answer_routing_policy, null)
      allow_overwrite                  = try(r.allow_overwrite, false)
      full_name_override               = try(r.full_name_override, false)
      alias                            = try(r.alias, null)
      failover_routing_policy          = try(r.failover_routing_policy, null)
      latency_routing_policy           = try(r.latency_routing_policy, null)
      weighted_routing_policy          = try(r.weighted_routing_policy, null)
      cidr_routing_policy              = try(r.cidr_routing_policy, null)
      geolocation_routing_policy       = try(r.geolocation_routing_policy, null)
      geoproximity_routing_policy      = try(r.geoproximity_routing_policy, null)
    }
  ]

  records = concat(var.records, local.records_json)

  # Convert `records` from list to map with unique keys
  recordsets = { for rs in local.records : (rs.key != null ? rs.key : join(" ", compact(["${rs.name} ${rs.type}", rs.set_identifier]))) => rs }
}

# Zone lookup only when the caller gives a zone_name without a zone_id;
# passing both (or zone_id plus FQDN records) avoids any API lookup at plan.
data "aws_route53_zone" "default" {
  count = local.enabled && var.zone_id == null && var.zone_name != null ? 1 : 0

  name         = var.zone_name
  private_zone = var.private_zone
}

locals {
  zone_id   = var.zone_id != null ? var.zone_id : try(data.aws_route53_zone.default[0].zone_id, null)
  zone_name = var.zone_name != null ? var.zone_name : try(data.aws_route53_zone.default[0].name, null)
}

resource "aws_route53_record" "default" {
  for_each = { for k, v in local.recordsets : k => v if local.enabled && (var.zone_id != null || var.zone_name != null) }

  zone_id = local.zone_id

  name                             = each.value.name != "" ? (each.value.full_name_override ? each.value.name : "${each.value.name}.${local.zone_name}") : local.zone_name
  type                             = each.value.type
  ttl                              = each.value.ttl
  records                          = each.value.records
  set_identifier                   = each.value.set_identifier
  health_check_id                  = each.value.health_check_id
  multivalue_answer_routing_policy = each.value.multivalue_answer_routing_policy
  allow_overwrite                  = each.value.allow_overwrite

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []

    content {
      name                   = alias.value.name
      zone_id                = coalesce(try(alias.value.zone_id, null), local.zone_id)
      evaluate_target_health = try(alias.value.evaluate_target_health, false)
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []

    content {
      type = failover_routing_policy.value.type
    }
  }

  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []

    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []

    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  dynamic "cidr_routing_policy" {
    for_each = each.value.cidr_routing_policy != null ? [each.value.cidr_routing_policy] : []

    content {
      collection_id = cidr_routing_policy.value.collection_id
      location_name = cidr_routing_policy.value.location_name
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing_policy != null ? [each.value.geolocation_routing_policy] : []

    content {
      continent   = try(geolocation_routing_policy.value.continent, null)
      country     = try(geolocation_routing_policy.value.country, null)
      subdivision = try(geolocation_routing_policy.value.subdivision, null)
    }
  }

  dynamic "geoproximity_routing_policy" {
    for_each = each.value.geoproximity_routing_policy != null ? [each.value.geoproximity_routing_policy] : []

    content {
      aws_region       = try(geoproximity_routing_policy.value.aws_region, null)
      bias             = try(geoproximity_routing_policy.value.bias, null)
      local_zone_group = try(geoproximity_routing_policy.value.local_zone_group, null)

      dynamic "coordinates" {
        for_each = try(geoproximity_routing_policy.value.coordinates, null) != null ? [geoproximity_routing_policy.value.coordinates] : []

        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }
}

################################################################################
# Health Check(s)
################################################################################

resource "aws_route53_health_check" "default" {
  for_each = { for k, v in var.health_checks : k => v if local.enabled }

  type = each.value.type

  fqdn              = try(each.value.fqdn, null)
  ip_address        = try(each.value.ip_address, null)
  port              = try(each.value.port, null)
  resource_path     = try(each.value.resource_path, null)
  failure_threshold = try(each.value.failure_threshold, 3)
  request_interval  = try(each.value.request_interval, 30)

  regions            = try(each.value.regions, null)
  measure_latency    = try(each.value.measure_latency, false)
  invert_healthcheck = try(each.value.invert_healthcheck, false)
  disabled           = try(each.value.disabled, false)
  enable_sni         = try(each.value.enable_sni, null)
  reference_name     = try(each.value.reference_name, null)

  child_health_threshold = try(each.value.child_health_threshold, null)
  child_healthchecks     = try(each.value.child_healthchecks, null)

  cloudwatch_alarm_name           = try(each.value.cloudwatch_alarm_name, null)
  cloudwatch_alarm_region         = try(each.value.cloudwatch_alarm_region, null)
  insufficient_data_health_status = try(each.value.insufficient_data_health_status, null)

  search_string       = try(each.value.search_string, null)
  routing_control_arn = try(each.value.routing_control_arn, null)
  triggers            = try(each.value.triggers, null)

  tags = merge(local.tags, try(each.value.tags, {}))
}

data "aws_region" "current" {}
