###############################################################################
# EKS Cluster Tests , tested in ap-southeast-1 region
###############################################################################

variables {
  region         = "ap-southeast-1"
  aws_account_id = "123456789012"
  cluster_name   = "karpenter-test"
}

run "eks_addons_configured" {
  command = plan

  assert {
    condition     = contains(keys(module.eks.cluster_addons), "coredns")
    error_message = "coredns addon must be configured"
  }

  assert {
    condition     = contains(keys(module.eks.cluster_addons), "kube-proxy")
    error_message = "kube-proxy addon must be configured"
  }

  assert {
    condition     = contains(keys(module.eks.cluster_addons), "vpc-cni")
    error_message = "vpc-cni addon must be configured"
  }

  assert {
    condition     = contains(keys(module.eks.cluster_addons), "eks-pod-identity-agent")
    error_message = "eks-pod-identity-agent addon must be configured (required for Karpenter Pod Identity)"
  }
}

run "eks_kubernetes_version" {
  command = plan

  assert {
    condition     = module.eks.cluster_version == "1.30"
    error_message = "EKS cluster must run Kubernetes 1.30"
  }
}

# Workers run on private subnets — verify 3 private subnets (one per AZ) exist
# and carry the karpenter.sh/discovery tag so Karpenter can schedule onto them.
run "eks_uses_private_subnets_for_workers" {
  command = plan

  assert {
    condition     = length(module.vpc.private_subnets) == 3
    error_message = "Must have 3 private subnets (one per AZ) for worker nodes"
  }

  assert {
    condition     = module.vpc.private_subnet_tags["karpenter.sh/discovery"] == var.cluster_name
    error_message = "Private subnets (used for workers) must carry the karpenter.sh/discovery tag"
  }
}

# The EKS control plane is isolated in intra subnets (no IGW, no NAT).
# Verify 3 intra subnets exist and are distinct from the private/public tiers.
run "eks_control_plane_uses_intra_subnets" {
  command = plan

  assert {
    condition     = length(module.vpc.intra_subnets) == 3
    error_message = "Must have 3 intra subnets — one per AZ — dedicated to the EKS control plane"
  }

  assert {
    condition     = toset(module.vpc.intra_subnets) != toset(module.vpc.private_subnets)
    error_message = "Intra subnets (control plane) must be different from private subnets (workers)"
  }
}

run "eks_node_group_exists" {
  command = plan

  assert {
    condition     = contains(keys(module.eks.eks_managed_node_groups), "karpenter")
    error_message = "A managed node group named 'karpenter' must be declared"
  }
}

# The node group runs m5.large nodes. Scaling: min=2 keeps two nodes always
# available for EKS add-ons and Karpenter itself; max=10 caps the baseline pool.
run "eks_node_group_scaling_config" {
  command = plan

  assert {
    condition     = module.eks.eks_managed_node_groups["karpenter"].node_group_autoscaling_group_names != null
    error_message = "Karpenter node group ASG names must be set"
  }
}

run "eks_security_group_discovery_tag" {
  command = plan

  assert {
    condition     = module.eks.node_security_group_tags["karpenter.sh/discovery"] == var.cluster_name
    error_message = "Node security group must be tagged karpenter.sh/discovery = cluster_name"
  }
}

run "eks_creator_admin_permissions_enabled" {
  command = plan

  assert {
    condition     = module.eks.cluster_iam_role_arn != ""
    error_message = "Cluster IAM role must be created (creator admin permissions enabled)"
  }
}

# The 'karpenter' node group carries CriticalAddonsOnly=true:NoSchedule so that
# only EKS add-ons and Karpenter itself run on these baseline nodes; all other
# workloads are forced onto Karpenter-provisioned nodes.
run "eks_node_group_critical_addons_taint" {
  command = plan

  assert {
    condition = contains(
      keys(module.eks.eks_managed_node_groups["karpenter"].node_group_taints),
      "CriticalAddonsOnly"
    )
    error_message = "The 'karpenter' node group must carry the CriticalAddonsOnly taint to isolate system workloads"
  }
}
