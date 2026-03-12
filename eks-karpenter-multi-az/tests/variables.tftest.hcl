###############################################################################
# Variable & Input Validation Tests
###############################################################################

###############################################################################
# Valid baseline — all subsequent runs override one variable to test edge cases
###############################################################################
variables {
  region         = "ap-southeast-1"
  aws_account_id = "123456789012"
  cluster_name   = "karpenter-test"
}

run "valid_variables_plan_succeeds" {
  command = plan

  assert {
    condition     = var.region == "ap-southeast-1"
    error_message = "Region variable must be set correctly"
  }

  assert {
    condition     = var.cluster_name == "karpenter-test"
    error_message = "Cluster name variable must be set correctly"
  }

  assert {
    condition     = var.aws_account_id == "123456789012"
    error_message = "AWS account ID variable must be set correctly"
  }
}

run "cluster_name_used_in_vpc_name" {
  command = plan

  assert {
    condition     = module.vpc.name == "${var.cluster_name}-vpc"
    error_message = "cluster_name variable must flow through to VPC name"
  }
}

run "cluster_name_used_in_discovery_tags" {
  command = plan

  assert {
    condition     = module.vpc.private_subnet_tags["karpenter.sh/discovery"] == var.cluster_name
    error_message = "cluster_name variable must flow through to karpenter.sh/discovery subnet tag"
  }

  assert {
    condition     = module.eks.node_security_group_tags["karpenter.sh/discovery"] == var.cluster_name
    error_message = "cluster_name variable must flow through to karpenter.sh/discovery SG tag"
  }
}

run "region_used_in_azs" {
  command = plan

  assert {
    condition = toset(module.vpc.azs) == toset([
      "${var.region}a", "${var.region}b", "${var.region}c"
    ])
    error_message = "region variable must determine the AZs used by the VPC"
  }
}

run "alternate_cluster_name" {
  command = plan

  variables {
    cluster_name = "my-cluster"
  }

  assert {
    condition     = module.vpc.name == "my-cluster-vpc"
    error_message = "Changing cluster_name must update the VPC name"
  }

  assert {
    condition     = module.vpc.private_subnet_tags["karpenter.sh/discovery"] == "my-cluster"
    error_message = "Changing cluster_name must update karpenter.sh/discovery subnet tag"
  }
}

run "alternate_region" {
  command = plan

  variables {
    region = "ap-southeast-2"
  }

  assert {
    condition = toset(module.vpc.azs) == toset([
      "ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"
    ])
    error_message = "Changing region must update the VPC AZs"
  }
}

###############################################################################
# Negative Tests — invalid inputs must be rejected by validation rules
###############################################################################

run "invalid_aws_account_id_rejected" {
  command = plan

  variables {
    aws_account_id = "not-an-account"
  }

  expect_failures = [var.aws_account_id]
}

run "short_aws_account_id_rejected" {
  command = plan

  variables {
    aws_account_id = "12345"
  }

  expect_failures = [var.aws_account_id]
}

run "invalid_region_rejected" {
  command = plan

  variables {
    region = "invalid-region"
  }

  expect_failures = [var.region]
}

run "cluster_name_starting_with_digit_rejected" {
  command = plan

  variables {
    cluster_name = "1invalid-name"
  }

  expect_failures = [var.cluster_name]
}
