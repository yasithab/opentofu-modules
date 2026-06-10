locals {
  enabled                     = var.enabled
  create_route53_records_only = var.create_route53_records_only

  # Get distinct list of domains and SANs. domain_name may be null in
  # records-only mode (create_route53_records_only with distinct_domain_names)
  all_domain_names = distinct(
    [for s in concat(var.domain_name != null ? [var.domain_name] : [], var.subject_alternative_names) : replace(s, "*.", "")]
  )
  distinct_domain_names = length(var.distinct_domain_names) > 0 ? var.distinct_domain_names : local.all_domain_names

  # Whether DNS validation records should be created in Route53
  create_validation_records = (local.enabled || local.create_route53_records_only) && var.validation_method == "DNS" && var.create_route53_records && (var.validate_certificate || local.create_route53_records_only)

  # Get the list of distinct domain_validation_options, with wildcard
  # domain names replaced by the domain name
  validation_domains = local.enabled || local.create_route53_records_only ? distinct(
    [for k, v in try(aws_acm_certificate.this.domain_validation_options, var.acm_certificate_domain_validation_options) : merge(
      tomap(v), { domain_name = replace(v.domain_name, "*.", "") }
    )]
  ) : []

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
    Region    = data.aws_region.current.region
  })
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  key_algorithm             = var.key_algorithm
  early_renewal_duration    = var.early_renewal_duration
  region                    = var.region

  certificate_authority_arn = var.private_authority_arn

  # For imported certificates
  private_key       = var.private_key
  certificate_body  = var.certificate_body
  certificate_chain = var.certificate_chain

  options {
    certificate_transparency_logging_preference = var.certificate_transparency_logging_preference ? "ENABLED" : "DISABLED"
    export                                      = try(var.certificate_export, null)
  }

  dynamic "validation_option" {
    for_each = var.validation_option

    content {
      domain_name       = coalesce(validation_option.value.domain_name, validation_option.key)
      validation_domain = validation_option.value.validation_domain
    }
  }

  tags = local.tags

  lifecycle {
    enabled               = local.enabled
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  # Keyed by the caller-supplied domain names so the keys are known at plan
  # time; the matching domain_validation_options entry resolves at apply.
  for_each = {
    for domain in local.distinct_domain_names : domain => domain
    if local.create_validation_records
  }

  zone_id = lookup(var.zones, each.value, var.zone_id)
  name    = [for o in local.validation_domains : o.resource_record_name if o.domain_name == each.value][0]
  type    = [for o in local.validation_domains : o.resource_record_type if o.domain_name == each.value][0]
  ttl     = var.dns_ttl

  records = [
    [for o in local.validation_domains : o.resource_record_value if o.domain_name == each.value][0]
  ]

  allow_overwrite = var.validation_allow_overwrite_records

  depends_on = [aws_acm_certificate.this]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  region          = var.region

  validation_record_fqdns = flatten([[for record in aws_route53_record.validation : record.fqdn], var.validation_record_fqdns])

  timeouts {
    create = var.validation_timeout
  }

  lifecycle {
    enabled = local.enabled && var.validation_method != null && var.validate_certificate && var.wait_for_validation
  }
}

data "aws_region" "current" {}
