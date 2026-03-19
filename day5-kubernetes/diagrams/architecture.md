# Day 5: Kubernetes Architecture

```
Internet → ALB Ingress Controller → front-end (x2)
                                       ↓
              ┌────────────────────────────────────────┐
              │            Internal Services            │
              │  catalogue → catalogue-db (MySQL)       │
              │  carts     → carts-db (MongoDB)         │
              │  orders    → orders-db (MongoDB)        │
              │  payment                                │
              │  shipping  → rabbitmq → queue-master    │
              │  user      → user-db                    │
              └────────────────────────────────────────┘

HPA watches CPU/Memory → scales pods automatically
Cluster Autoscaler → adds/removes nodes as needed
```
