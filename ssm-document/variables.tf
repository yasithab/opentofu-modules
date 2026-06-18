variable "enabled" {
  description = "Set to false to prevent the module from creating any resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the SSM document. 3-128 chars; letters, digits, and _ . - only; must not start with the reserved prefixes aws, amazon, or amzn."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,128}$", var.name))
    error_message = "name must be 3-128 characters: letters, digits, and _ . - only."
  }
  validation {
    condition     = !can(regex("(?i)^(aws|amazon|amzn)", var.name))
    error_message = "name must not start with the reserved prefixes aws, amazon, or amzn."
  }
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "content" {
  description = "Content of the SSM document, in the format set by document_format (JSON, YAML or TEXT). Build it with jsonencode()/yamlencode() or templatefile(). Required when enabled."
  type        = string
  default     = null

  validation {
    condition     = !var.enabled || (can(trimspace(var.content)) && trimspace(var.content) != "")
    error_message = "content must be a non-empty document body when enabled = true."
  }
}

variable "document_type" {
  description = "Type of the document. Valid values: Command, Policy, Automation, Session, Package, ChangeCalendar, CloudFormation, ConformancePackTemplate, DeploymentStrategy, ProblemAnalysis, ProblemAnalysisTemplate, QuickSetup."
  type        = string
  default     = "Command"

  validation {
    condition = contains([
      "Command", "Policy", "Automation", "Session", "Package", "ChangeCalendar",
      "CloudFormation", "ConformancePackTemplate", "DeploymentStrategy",
      "ProblemAnalysis", "ProblemAnalysisTemplate", "QuickSetup",
    ], var.document_type)
    error_message = "document_type must be a valid SSM document type."
  }
}

variable "document_format" {
  description = "Format of the document content. Valid values: JSON, YAML, TEXT."
  type        = string
  default     = "JSON"

  validation {
    condition     = contains(["JSON", "YAML", "TEXT"], var.document_format)
    error_message = "document_format must be one of JSON, YAML, TEXT."
  }
}

variable "version_name" {
  description = "Friendly name of the document version. Can be set when creating or updating the document."
  type        = string
  default     = null
}

variable "target_type" {
  description = "Types of resources the document can run on, e.g. /AWS::EC2::Instance, or / for all resource types."
  type        = string
  default     = null
}

variable "attachments_source" {
  description = "Attachment sources for the document (e.g. ZIP packages, scripts). Each entry: key (SourceUrl | S3FileUrl | AttachmentReference), values (list), and an optional name."
  type = list(object({
    key    = string
    values = list(string)
    name   = optional(string)
  }))
  default = []
}

variable "permissions" {
  description = "Sharing permissions for the document. Map with keys `type` (\"Share\") and `account_ids` (comma-separated account IDs, or \"all\"). Null keeps the document private."
  type        = map(string)
  default     = null
}
