# Redemption Service Architecture Proposal

Author: Lead SRE  
Objective: Zero downtime financial-grade infrastructure  

# Architecture Summary

This design ensures:

- Zero downtime
- Flash sale readiness
- Financial integrity
- Secure data handling
- Enterprise-grade reliability
- Minimal operational toil

<img width="1217" height="871" alt="image" src="https://github.com/user-attachments/assets/ebcae9dd-f4d2-4229-b74d-b8ecf0f20cd5" />


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
# 4. Operation Model
Day 2 Strategy:
- Everything as Code
- CI/CD enforced
- Drift detection
- Chaos testing
- Load test before flash sale
- Backup validation quarterly

---
# 5. Data Layer
Day 2 Strategy:Cont
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
# 6. Observability Model
Day 2 Strategy:Cont
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

# 7. Future Enhancements
Day 2 Strategy:Cont

- Multi-region active-active or active-passive 
- Aurora Global DB
- Service Mesh with mTLS
- Automated game days
- Cost optimization layer
- DR to multicloud 

                ┌──────────────────────────┐
                │        Route 53          │
                │  Health Check + Failover │
                └─────────────┬────────────┘
                              │
              ┌───────────────┴────────────────┐
              │                                │
        Primary (AWS)                    DR (Azure)
