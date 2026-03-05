###############################################################################
# VPC Tests
###############################################################################

variables {
  region         = "ap-southeast-1"
  aws_account_id = "123456789012"
  cluster_name   = "karpenter-test"
}

run "vpc_name_includes_cluster_name" {
  command = plan

  assert {
    condition     = module.vpc.name == "${var.cluster_name}-vpc"
    error_message = "VPC name must be '<cluster_name>-vpc'"
  }
}

run "private_subnet_cidrs" {
  command = plan

  assert {
    condition = toset(module.vpc.private_subnets_cidr_blocks) == toset([
      "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"
    ])
    error_message = "Private subnet CIDRs must be 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24"
  }
}

run "public_subnet_cidrs" {
  command = plan

  assert {
    condition = toset(module.vpc.public_subnets_cidr_blocks) == toset([
      "10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"
    ])
    error_message = "Public subnet CIDRs must be 10.0.101.0/24-103.0/24"
  }
}

run "intra_subnet_cidrs" {
  command = plan

  assert {
    condition = toset(module.vpc.intra_subnets_cidr_blocks) == toset([
      "10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"
    ])
    error_message = "Intra subnet CIDRs must be 10.0.104.0/24-106.0/24"
  }
}

run "single_nat_gateway" {
  command = plan

  assert {
    condition     = length(module.vpc.natgw_ids) == 1
    error_message = "Must use a single NAT gateway (single_nat_gateway = true)"
  }
}

run "public_subnets_elb_tag" {
  command = plan

  assert {
    condition     = module.vpc.public_subnet_tags["kubernetes.io/role/elb"] == "1"
    error_message = "Public subnets must be tagged kubernetes.io/role/elb = 1"
  }
}

run "private_subnets_internal_elb_tag" {
  command = plan

  assert {
    condition     = module.vpc.private_subnet_tags["kubernetes.io/role/internal-elb"] == "1"
    error_message = "Private subnets must be tagged kubernetes.io/role/internal-elb = 1"
  }
}

run "azs_derived_from_region" {
  command = plan

  assert {
    condition = toset(module.vpc.azs) == toset([
      "${var.region}a", "${var.region}b", "${var.region}c"
    ])
    error_message = "AZs must be the three AZs of the configured region"
  }
}
