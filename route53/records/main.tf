locals {
  enabled = var.enabled

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
  })
}

locals {
  # Terragrunt users have to provide `records_jsonencoded` as jsonencode()'d string.
  # See details: https://github.com/gruntwork-io/terragrunt/issues/1211
  records = concat(var.records, try(jsondecode(var.records_jsonencoded), []))

  # Convert `records` from list to map with unique keys
  recordsets = { for rs in local.records : try(rs.key, join(" ", compact(["${rs.name} ${rs.type}", try(rs.set_identifier, "")]))) => rs }
}

data "aws_route53_zone" "default" {
  count = local.enabled && (var.zone_id != null || var.zone_name != null) ? 1 : 0

  zone_id      = var.zone_id
  name         = var.zone_name
  private_zone = var.private_zone
}

resource "aws_route53_record" "default" {
  for_each = { for k, v in local.recordsets : k => v if local.enabled && (var.zone_id != null || var.zone_name != null) }

  zone_id = try(var.zone_id, data.aws_route53_zone.default[0].zone_id)

  name                             = each.value.name != "" ? (lookup(each.value, "full_name_override", false) ? each.value.name : "${each.value.name}.${data.aws_route53_zone.default[0].name}") : data.aws_route53_zone.default[0].name
  type                             = each.value.type
  ttl                              = lookup(each.value, "ttl", null)
  records                          = try(each.value.records, null)
  set_identifier                   = lookup(each.value, "set_identifier", null)
  health_check_id                  = lookup(each.value, "health_check_id", null)
  multivalue_answer_routing_policy = lookup(each.value, "multivalue_answer_routing_policy", null)
  allow_overwrite                  = lookup(each.value, "allow_overwrite", false)

  dynamic "alias" {
    for_each = length(keys(lookup(each.value, "alias", {}))) == 0 ? [] : [true]

    content {
      name                   = each.value.alias.name
      zone_id                = try(each.value.alias.zone_id, data.aws_route53_zone.default[0].zone_id)
      evaluate_target_health = lookup(each.value.alias, "evaluate_target_health", false)
    }
  }

  dynamic "failover_routing_policy" {
    for_each = length(keys(lookup(each.value, "failover_routing_policy", {}))) == 0 ? [] : [true]

    content {
      type = each.value.failover_routing_policy.type
    }
  }

  dynamic "latency_routing_policy" {
    for_each = length(keys(lookup(each.value, "latency_routing_policy", {}))) == 0 ? [] : [true]

    content {
      region = each.value.latency_routing_policy.region
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = length(keys(lookup(each.value, "weighted_routing_policy", {}))) == 0 ? [] : [true]

    content {
      weight = each.value.weighted_routing_policy.weight
    }
  }

  dynamic "cidr_routing_policy" {
    for_each = length(keys(lookup(each.value, "cidr_routing_policy", {}))) == 0 ? [] : [true]

    content {
      collection_id = each.value.cidr_routing_policy.collection_id
      location_name = each.value.cidr_routing_policy.location_name
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = length(keys(lookup(each.value, "geolocation_routing_policy", {}))) == 0 ? [] : [true]

    content {
      continent   = lookup(each.value.geolocation_routing_policy, "continent", null)
      country     = lookup(each.value.geolocation_routing_policy, "country", null)
      subdivision = lookup(each.value.geolocation_routing_policy, "subdivision", null)
    }
  }

  dynamic "geoproximity_routing_policy" {
    for_each = length(keys(lookup(each.value, "geoproximity_routing_policy", {}))) == 0 ? [] : [true]

    content {
      aws_region       = lookup(each.value.geoproximity_routing_policy, "aws_region", null)
      bias             = lookup(each.value.geoproximity_routing_policy, "bias", null)
      local_zone_group = lookup(each.value.geoproximity_routing_policy, "local_zone_group", null)

      dynamic "coordinates" {
        for_each = lookup(each.value.geoproximity_routing_policy, "coordinates", null) == null ? [] : [lookup(each.value.geoproximity_routing_policy, "coordinates", null)]

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
