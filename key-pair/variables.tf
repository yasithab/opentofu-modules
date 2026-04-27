
variable "enabled" {
  description = "Determines whether resources will be created (affects all resources)"
  type        = bool
  default     = true
}


variable "name" {
  description = "Name to use for the key pair. If not provided, a name will be generated using `name_prefix`."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Name prefix to use for the key pair when `name` is not provided."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Key Pair
################################################################################

variable "public_key" {
  description = "The public key material. Required unless `create_private_key` is true."
  type        = string
  default     = null
}

variable "create_private_key" {
  description = "Whether to create a TLS private key and derive the public key automatically."
  type        = bool
  default     = false
}

variable "private_key_algorithm" {
  description = "Algorithm to use for the TLS private key. Valid values: `RSA`, `ED25519`."
  type        = string
  default     = "RSA"
}

variable "private_key_rsa_bits" {
  description = "Number of bits for the RSA private key. Only used when `private_key_algorithm` is `RSA`."
  type        = number
  default     = 4096
}

