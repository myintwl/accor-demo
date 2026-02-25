# Redemption Service Architecture Proposal

Author: Lead SRE  
Objective: Zero downtime financial-grade infrastructure  

---

# 1. Business Context

The Redemption service processes global hotel loyalty point deductions.

Failure impact:
- Direct revenue loss
- Customer dissatisfaction
- Brand damage

Availability Target: 99.99%+

---

# 2. High-Level Architecture

Traffic Flow:

Route 53  
↓  
WAF + Shield  
↓  
ALB  
↓  
EKS (Multi-AZ)  
↓  
RDS (Multi-AZ) + Redis Cluster  

---

# 3. Compute Architecture

- Amazon EKS (3 AZ)
- Managed node groups
- Karpenter autoscaling
- Horizontal Pod Autoscaler
- PodDisruptionBudgets
- TopologySpreadConstraints

Flash Sale Handling:
- 30% idle baseline capacity
- Rapid node provisioning
- Redis for burst buffering
- SQS fallback queue

---

# 4. Data Layer

## RDS

- Multi-AZ
- Automated backups
- Encryption enabled
- Performance Insights

## Redis

- Cluster mode
- Multi-AZ replication
- Encrypted in transit

Purpose:
- Idempotency keys
- Rate limiting
- Burst absorption

---

# 5. Security Architecture

- Private subnets for workloads
- Isolated subnets for DB
- IRSA for pod identity
- No public DB access
- WAF managed rule sets
- Encryption everywhere

Defense in depth applied at:

- Network
- IAM
- Application
- Infrastructure
- Observability

---

# 6. Scalability Strategy

Application Scaling:
- HPA (CPU + custom metrics)
- Scale to 10x baseline

Infrastructure Scaling:
- Karpenter dynamic provisioning
- Spot + On-Demand mix
- Pre-warmed capacity

Database Strategy:
- Read replicas if needed
- Consider Aurora for faster failover

---

# 7. Reliability Strategy

Failure Scenarios Covered:

AZ Failure:
- Multi-AZ cluster
- Automatic pod redistribution
- RDS failover

Node Failure:
- Kubernetes rescheduling

Bad Deployment:
- GitOps
- Canary rollout
- Automatic rollback

---

# 8. Observability Model

Golden Signals:

- Latency
- Traffic
- Errors
- Saturation

Tooling:

- Prometheus
- Grafana
- CloudWatch
- X-Ray
- Structured logging

Alerting:

- SLO-based alerts
- Burn-rate alerts

---

# 9. Operational Model

Day 2 Strategy:

- Everything as Code
- CI/CD enforced
- Drift detection
- Chaos testing
- Load test before flash sale
- Backup validation quarterly

---

# 10. Future Enhancements

- Multi-region active-active
- Aurora Global DB
- Service Mesh with mTLS
- Automated game days
- Cost optimization layer

---

# Architecture Summary

This design ensures:

- Zero downtime
- Flash sale readiness
- Financial integrity
- Secure data handling
- Enterprise-grade reliability
- Minimal operational toil