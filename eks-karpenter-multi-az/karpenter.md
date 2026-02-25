# Karpenter: The Blueprint of Modern Cloud

## 1. Introduction: The Blueprint of Modern Cloud

Welcome to the exciting world of cloud architecture! If you have ever
wondered how massive global platforms handle millions of users without
breaking a sweat, the answer lies in orchestration and automation.

In this guide, we are going to explore how to build a production-ready
Kubernetes environment on Amazon Web Services (AWS) using Terraform.

Terraform is an Infrastructure as Code (IaC) tool that allows us to
write down our entire data center as a script — making it repeatable,
versioned, auditable, and organized.

Specifically, we are building an Amazon EKS (Elastic Kubernetes Service)
cluster paired with a revolutionary tool called Karpenter.

While standard scaling is like adding more of the same-sized bricks to a
wall, Karpenter is an intelligent builder that selects exactly the right
size brick for the job — exactly when it is needed.

------------------------------------------------------------------------

## 2. The Memory Bank: S3 and Terraform State

Before we build a single server, we need a State Bucket.

In Terraform, a state file is the source of truth — a map of everything
you have built. If you lose this map, Terraform loses its memory of the
infrastructure.

We use an Amazon S3 bucket as our secure, remote vault for this state.

### Key Features

-   Region locking (e.g., AP-Southeast-2)
-   Account ID restriction
-   Force destroy for demo cleanup
-   allowed_account_ids safety mechanism

------------------------------------------------------------------------

## 3. The Neighborhood: Networking with VPCs

A Virtual Private Cloud (VPC) is your private slice of AWS. It provides
networking and isolation for your cluster.

### Subnet Types

| Subnet Type | Purpose                        | Kubernetes Tags                     |
|-------------|--------------------------------|-------------------------------------|
| Public      | Internet-facing Load Balancers | kubernetes.io/role/elb = 1          |
| Private     | Application workloads          | kubernetes.io/role/internal-elb = 1 |
| Intra       | EKS Control Plane              | N/A                                 |

### NAT Gateway

Allows private workloads outbound internet access while blocking inbound
connections.

------------------------------------------------------------------------

## 4. The Command Center: Amazon EKS

Amazon EKS manages Kubernetes control plane operations.

### Configuration Checklist

-   Cluster Name: Carpenter
-   Version: 1.30
-   Public access enabled
-   Pod Identity enabled

### Taint Strategy

Initial managed node group is tainted to prevent resource starvation and
protect system components.

------------------------------------------------------------------------

## 5. The Intelligent Scaler: Karpenter

Karpenter bridges AWS infrastructure and Kubernetes workloads.

### AWS Side

-   IAM roles
-   SQS
-   EventBridge

### Kubernetes Side

-   NodePool
-   EC2NodeClass

------------------------------------------------------------------------

## 6. Operational Toolkit

### Authenticate

aws eks update-kubeconfig –region AP-Southeast-2 –name Carpenter

### Observe

kubectl get pods -n kube-system kubectl get sa -n kube-system \| grep
carpenter

### Scale Demo

kubectl scale deployment inflate –replicas=5 kubectl get pods -w kubectl
delete deployment inflate

------------------------------------------------------------------------

## 7. The Result

Karpenter intelligently provisions optimal instances (e.g., C7G.2xlarge
Graviton) to fit workload requirements instantly.

When workloads terminate, unused instances are immediately removed to
optimize cost.

------------------------------------------------------------------------

This architecture demonstrates modern cloud-native autoscaling, cost
optimization, and production-ready DevOps practices.
