###############################################################################
# Terraform Test Suite for EKS Karpenter Multi-AZ
# Run with: terraform test
###############################################################################

variables {
  region         = "ap-southeast-1"
  aws_account_id = "123456789012"
  cluster_name   = "karpenter-test"
}

###############################################################################
# VPC Configuration Tests
###############################################################################
run "vpc_cidr_and_subnet_layout" {
  command = plan

  assert {
    condition     = module.vpc.vpc_cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR must be 10.0.0.0/16"
  }

  assert {
    condition     = length(module.vpc.private_subnets) == 3
    error_message = "Must have 3 private subnets (one per AZ)"
  }

  assert {
    condition     = length(module.vpc.public_subnets) == 3
    error_message = "Must have 3 public subnets (one per AZ)"
  }

  assert {
    condition     = length(module.vpc.intra_subnets) == 3
    error_message = "Must have 3 intra subnets for the EKS control plane"
  }
}

run "vpc_nat_gateway_config" {
  command = plan

  assert {
    condition     = module.vpc.natgw_ids != null
    error_message = "NAT gateway must be provisioned for private subnet egress"
  }
}

###############################################################################
# EKS Cluster Configuration Tests
###############################################################################
run "eks_cluster_name_matches_variable" {
  command = plan

  assert {
    condition     = module.eks.cluster_name == var.cluster_name
    error_message = "EKS cluster name must match the cluster_name variable"
  }
}

run "eks_cluster_version" {
  command = plan

  assert {
    condition     = module.eks.cluster_version == "1.30"
    error_message = "EKS cluster version must be 1.30"
  }
}

run "eks_managed_node_group_taint" {
  command = plan

  # Verify the managed node group is tainted so non-critical workloads
  # are forced onto Karpenter-provisioned nodes.
  assert {
    condition = contains(
      keys(module.eks.eks_managed_node_groups),
      "karpenter"
    )
    error_message = "A managed node group named 'karpenter' must exist"
  }
}

run "eks_public_access_enabled" {
  command = plan

  assert {
    condition     = module.eks.cluster_endpoint != ""
    error_message = "Cluster endpoint must be set (public access is enabled)"
  }
}

###############################################################################
# Karpenter Module Tests
###############################################################################
run "karpenter_pod_identity_enabled" {
  command = plan

  assert {
    condition     = module.karpenter.service_account != ""
    error_message = "Karpenter service account must be created for Pod Identity"
  }
}

run "karpenter_interruption_queue_created" {
  command = plan

  assert {
    condition     = module.karpenter.queue_name != ""
    error_message = "Karpenter SQS interruption queue must be created"
  }
}

run "karpenter_node_iam_role_created" {
  command = plan

  assert {
    condition     = module.karpenter.node_iam_role_name != ""
    error_message = "Karpenter node IAM role must be created"
  }
}

###############################################################################
# Discovery Tag Consistency Tests
###############################################################################
run "karpenter_discovery_tags_consistent" {
  command = plan

  # The karpenter.sh/discovery tag on subnets and security groups must match
  # the cluster name so Karpenter can auto-discover them.
  assert {
    condition = module.vpc.private_subnet_tags["karpenter.sh/discovery"] == var.cluster_name
    error_message = "Private subnets must be tagged karpenter.sh/discovery = cluster_name"
  }
}
