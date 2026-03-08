locals {
  create                      = var.enabled
  create_route53_records_only = var.create_route53_records_only

  # Get distinct list of domains and SANs
  distinct_domain_names = coalescelist(var.distinct_domain_names, distinct(
    [for s in concat([var.domain_name], var.subject_alternative_names) : replace(s, "*.", "")]
  ))

  # Get the list of distinct domain_validation_options, with wildcard
  # domain names replaced by the domain name
  validation_domains = local.create || local.create_route53_records_only ? distinct(
    [for k, v in try(aws_acm_certificate.this.domain_validation_options, var.acm_certificate_domain_validation_options) : merge(
      tomap(v), { domain_name = replace(v.domain_name, "*.", "") }
    )]
  ) : []

  tags = merge(var.tags, {
    ManagedBy = "opentofu"
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
      domain_name       = try(validation_option.value["domain_name"], validation_option.key)
      validation_domain = validation_option.value["validation_domain"]
    }
  }

  tags = local.tags

  lifecycle {
    enabled               = local.create
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  count = (local.create || local.create_route53_records_only) && var.validation_method == "DNS" && var.create_route53_records && (var.validate_certificate || local.create_route53_records_only) ? length(local.distinct_domain_names) : 0

  zone_id = lookup(var.zones, element(local.validation_domains, count.index)["domain_name"], var.zone_id)
  name    = element(local.validation_domains, count.index)["resource_record_name"]
  type    = element(local.validation_domains, count.index)["resource_record_type"]
  ttl     = var.dns_ttl

  records = [
    element(local.validation_domains, count.index)["resource_record_value"]
  ]

  allow_overwrite = var.validation_allow_overwrite_records

  depends_on = [aws_acm_certificate.this]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
  region          = var.region

  validation_record_fqdns = flatten([aws_route53_record.validation[*].fqdn, var.validation_record_fqdns])

  timeouts {
    create = var.validation_timeout
  }

  lifecycle {
    enabled = local.create && var.validation_method != null && var.validate_certificate && var.wait_for_validation
  }
}
