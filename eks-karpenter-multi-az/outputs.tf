###############################################################################
# EKS Cluster
###############################################################################
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint for the EKS cluster (used to configure kubectl)"
  value       = module.eks.cluster_endpoint
}

###############################################################################
# Networking
###############################################################################
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

###############################################################################
# Karpenter
###############################################################################
output "karpenter_node_iam_role_arn" {
  description = "ARN of the IAM role assigned to Karpenter-provisioned nodes"
  value       = module.karpenter.node_iam_role_arn
}

output "karpenter_queue_name" {
  description = "Name of the SQS queue used by Karpenter for spot interruption handling"
  value       = module.karpenter.queue_name
}
