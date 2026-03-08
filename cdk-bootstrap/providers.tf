terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.34"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
