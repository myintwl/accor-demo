# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Terraform project that provisions a production-ready Amazon EKS cluster with Karpenter autoscaling across multiple availability zones in `ap-southeast-2`. The target AWS account ID and cluster name are configured in `terraform.tfvars`.

## Terraform Commands

```bash
# Initialize (downloads providers and modules)
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

Before applying, update `terraform.tfvars` with the real `aws_account_id` and the S3 backend bucket name in `main.tf` (currently placeholder `XXXXXXXXXXXX`).

## Architecture

The infrastructure is defined entirely in `main.tf` and organized into these layers:

1. **S3 Backend** — Remote state stored in `ap-southeast-2`. Bucket name must be updated before use.

2. **VPC** (`terraform-aws-modules/vpc/aws` v5.13.0) — Three-tier subnet layout:
   - Public subnets: tagged for external ELBs
   - Private subnets: tagged `karpenter.sh/discovery` for Karpenter node provisioning
   - Intra subnets: EKS control plane only

3. **EKS** (`terraform-aws-modules/eks/aws` v20.24.0) — Kubernetes 1.30, AL2023. A single managed node group (m5.large, min 2) runs with a `CriticalAddonsOnly=true:NoSchedule` taint to reserve it exclusively for EKS add-ons and Karpenter itself. All workloads go to Karpenter-provisioned nodes.

4. **Karpenter module** — Uses EKS Pod Identity (not IRSA). Creates IAM role, SQS interruption queue, and EventBridge rules.

5. **Karpenter Helm release** — Deployed to `kube-system`, version 1.0.0 from `oci://public.ecr.aws/karpenter`. Requires ECR public auth token fetched from `us-east-1`.

6. **Karpenter CRDs** (via `gavinbunney/kubectl` provider):
   - `EC2NodeClass` (default) — uses AL2023 AMI, discovers subnets/SGs via `karpenter.sh/discovery` tag
   - `NodePool` (default) — targets c/m/r instance families, 4–32 vCPUs, Nitro hypervisor, generation > 2; consolidates on empty nodes after 30s

7. **Inflate deployment** — A sample workload (`pause` container, 1 CPU request, 0 replicas) for testing Karpenter scaling.

## Prerequisites

- AWS CLI with credentials configured
- `kubectl`
- Terraform >= 1.x
- Helm

## Post-deploy: Authenticate and Test

```bash
# Configure kubectl
aws eks update-kubeconfig --region ap-southeast-2 --name karpenter

# Verify Karpenter pods
kubectl get pods -n kube-system

# Test autoscaling with the inflate deployment
kubectl scale deployment inflate --replicas=5
kubectl get pods -w
kubectl delete deployment inflate
```
