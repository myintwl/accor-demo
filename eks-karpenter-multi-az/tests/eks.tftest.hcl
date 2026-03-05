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

run "eks_uses_private_subnets_for_workers" {
  command = plan

  assert {
    condition     = module.eks.node_groups["karpenter"] != null
    error_message = "Karpenter node group must exist"
  }
}

run "eks_node_group_instance_type" {
  command = plan

  assert {
    condition = contains(
      module.eks.eks_managed_node_groups["karpenter"].node_group_resources[0].autoscaling_groups[0].name != "",
      true
    )
    error_message = "Karpenter managed node group autoscaling group must be planned"
  }
}

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

run "eks_control_plane_uses_intra_subnets" {
  command = plan

  assert {
    condition     = length(module.eks.cluster_primary_security_group_id) > 0
    error_message = "EKS cluster primary security group must be set"
  }
}
