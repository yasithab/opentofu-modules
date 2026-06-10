variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}


variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "zone_id" {
  description = "ID of DNS zone"
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || length(var.zone_id) > 0
    error_message = "The zone_id must be null or a non-empty string."
  }
}

variable "zone_name" {
  description = "Name of DNS zone"
  type        = string
  default     = null
}

variable "private_zone" {
  description = "Whether Route53 zone is private or public"
  type        = bool
  default     = false
}

variable "records" {
  description = "List of objects of DNS records"
  type = list(object({
    key                              = optional(string)
    name                             = string
    type                             = string
    ttl                              = optional(number)
    records                          = optional(list(string))
    set_identifier                   = optional(string)
    health_check_id                  = optional(string)
    multivalue_answer_routing_policy = optional(bool)
    allow_overwrite                  = optional(bool, false)
    full_name_override               = optional(bool, false)
    alias = optional(object({
      name                   = string
      zone_id                = optional(string)
      evaluate_target_health = optional(bool, false)
    }))
    failover_routing_policy = optional(object({
      type = string
    }))
    latency_routing_policy = optional(object({
      region = string
    }))
    weighted_routing_policy = optional(object({
      weight = number
    }))
    cidr_routing_policy = optional(object({
      collection_id = string
      location_name = string
    }))
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    geoproximity_routing_policy = optional(object({
      aws_region       = optional(string)
      bias             = optional(number)
      local_zone_group = optional(string)
      coordinates = optional(object({
        latitude  = string
        longitude = string
      }))
    }))
  }))
  default = []
}

variable "records_jsonencoded" {
  description = "List of map of DNS records (stored as jsonencoded string, for terragrunt)"
  type        = string
  default     = null
}

variable "health_checks" {
  description = "Map of Route53 health checks to create"
  type = map(object({
    type                            = string
    fqdn                            = optional(string)
    ip_address                      = optional(string)
    port                            = optional(number)
    resource_path                   = optional(string)
    failure_threshold               = optional(number, 3)
    request_interval                = optional(number, 30)
    regions                         = optional(list(string))
    measure_latency                 = optional(bool, false)
    invert_healthcheck              = optional(bool, false)
    disabled                        = optional(bool, false)
    enable_sni                      = optional(bool)
    reference_name                  = optional(string)
    child_health_threshold          = optional(number)
    child_healthchecks              = optional(list(string))
    cloudwatch_alarm_name           = optional(string)
    cloudwatch_alarm_region         = optional(string)
    insufficient_data_health_status = optional(string)
    search_string                   = optional(string)
    routing_control_arn             = optional(string)
    triggers                        = optional(map(string))
    tags                            = optional(map(string), {})
  }))
  default = {}
}
