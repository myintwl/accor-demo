###############################################################################
# Environment
###############################################################################
variable "region" {
    type = string
    validation {
      condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
      error_message = "region must be a valid AWS region format (e.g. ap-southeast-2, us-east-1, eu-west-1)."
    }
}

variable "aws_account_id" {
    type = string
    validation {
      condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
      error_message = "aws_account_id must be a 12-digit numeric AWS account number."
    }
}

###############################################################################
# Cluster
###############################################################################
variable "cluster_name" {
    type = string
    validation {
      condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,99}$", var.cluster_name))
      error_message = "cluster_name must start with a letter, contain only letters, numbers, and hyphens, and be at most 100 characters."
    }
}