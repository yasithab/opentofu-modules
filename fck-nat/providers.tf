terraform {
  required_version = "1.11.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0"
    }
  }
}
