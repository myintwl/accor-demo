###############################################################################
# Karpenter Module, Helm, NodePool & EC2NodeClass Tests
###############################################################################

variables {
  region         = "ap-southeast-1"
  aws_account_id = "123456789012"
  cluster_name   = "karpenter-test"
}

###############################################################################
# Karpenter Module (IAM / SQS)
###############################################################################
run "karpenter_v1_permissions_enabled" {
  command = plan

  assert {
    condition     = module.karpenter.node_iam_role_arn != ""
    error_message = "Karpenter node IAM role ARN must be set (v1 permissions enabled)"
  }
}

run "karpenter_ssm_policy_attached" {
  command = plan

  # AmazonSSMManagedInstanceCore must be in the additional policies map
  assert {
    condition = contains(
      values(module.karpenter.node_iam_role_policy_arns),
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    )
    error_message = "AmazonSSMManagedInstanceCore policy must be attached to Karpenter node role"
  }
}

run "karpenter_pod_identity_association_created" {
  command = plan

  assert {
    condition     = module.karpenter.pod_identity_association_arn != ""
    error_message = "Pod Identity association must be created"
  }
}

###############################################################################
# Karpenter Helm Release
###############################################################################
run "karpenter_helm_namespace" {
  command = plan

  assert {
    condition     = helm_release.karpenter.namespace == "kube-system"
    error_message = "Karpenter Helm release must be deployed in kube-system"
  }
}

run "karpenter_helm_chart_version" {
  command = plan

  assert {
    condition     = helm_release.karpenter.version == "1.0.0"
    error_message = "Karpenter Helm chart version must be 1.0.0"
  }
}

run "karpenter_helm_repository" {
  command = plan

  assert {
    condition     = helm_release.karpenter.repository == "oci://public.ecr.aws/karpenter"
    error_message = "Karpenter Helm chart must be sourced from oci://public.ecr.aws/karpenter"
  }
}

###############################################################################
# NodePool (kubectl_manifest)
###############################################################################
run "karpenter_node_pool_cpu_limit" {
  command = plan

  assert {
    condition     = can(regex("cpu: 1000", kubectl_manifest.karpenter_node_pool.yaml_body))
    error_message = "NodePool must set a CPU limit of 1000"
  }
}

run "karpenter_node_pool_instance_categories" {
  command = plan

  assert {
    condition = can(regex(
      "values: \\[\"c\", \"m\", \"r\"\\]",
      kubectl_manifest.karpenter_node_pool.yaml_body
    ))
    error_message = "NodePool must allow instance categories c, m, r"
  }
}

run "karpenter_node_pool_nitro_hypervisor" {
  command = plan

  assert {
    condition     = can(regex("nitro", kubectl_manifest.karpenter_node_pool.yaml_body))
    error_message = "NodePool must require Nitro hypervisor"
  }
}

run "karpenter_node_pool_consolidation_policy" {
  command = plan

  assert {
    condition     = can(regex("WhenEmpty", kubectl_manifest.karpenter_node_pool.yaml_body))
    error_message = "NodePool consolidationPolicy must be WhenEmpty"
  }
}

run "karpenter_node_pool_consolidate_after" {
  command = plan

  assert {
    condition     = can(regex("consolidateAfter: 30s", kubectl_manifest.karpenter_node_pool.yaml_body))
    error_message = "NodePool must consolidate after 30s"
  }
}

###############################################################################
# EC2NodeClass (kubectl_manifest)
###############################################################################
run "karpenter_node_class_ami_family" {
  command = plan

  assert {
    condition     = can(regex("amiFamily: AL2023", kubectl_manifest.karpenter_node_class.yaml_body))
    error_message = "EC2NodeClass amiFamily must be AL2023"
  }
}

run "karpenter_node_class_subnet_selector" {
  command = plan

  assert {
    condition = can(regex(
      "karpenter.sh/discovery: ${var.cluster_name}",
      kubectl_manifest.karpenter_node_class.yaml_body
    ))
    error_message = "EC2NodeClass subnet selector must use karpenter.sh/discovery tag matching cluster name"
  }
}

###############################################################################
# Inflate Deployment
###############################################################################
run "inflate_deployment_zero_replicas" {
  command = plan

  assert {
    condition     = can(regex("replicas: 0", kubectl_manifest.karpenter_example_deployment.yaml_body))
    error_message = "Inflate deployment must start with 0 replicas"
  }
}

run "inflate_deployment_cpu_request" {
  command = plan

  assert {
    condition     = can(regex("cpu: 1", kubectl_manifest.karpenter_example_deployment.yaml_body))
    error_message = "Inflate deployment container must request 1 CPU"
  }
}

run "inflate_deployment_pause_image" {
  command = plan

  assert {
    condition = can(regex(
      "public.ecr.aws/eks-distro/kubernetes/pause:3.7",
      kubectl_manifest.karpenter_example_deployment.yaml_body
    ))
    error_message = "Inflate deployment must use the pause:3.7 image"
  }
}
