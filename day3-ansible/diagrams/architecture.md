# Day 3: Ansible Architecture

```
┌─────────────────────────────────────────────────────┐
│              Ansible Control Node                   │
│                                                     │
│  ansible.cfg → inventory → playbooks → roles        │
│       │            │           │          │          │
│       ▼            ▼           ▼          ▼          │
│  [Settings]  [Host List]  [Tasks]   [Reusable]      │
│                                     [Packages]      │
└──────────────────────┬──────────────────────────────┘
                       │ SSH
          ┌────────────┼────────────────┐
          ▼            ▼                ▼
    ┌──────────┐ ┌──────────┐    ┌──────────┐
    │  EC2 #1  │ │  EC2 #2  │    │  EC2 #N  │
    │  Docker  │ │  Docker  │    │  Docker  │
    │ SockShop │ │ SockShop │    │ SockShop │
    │ CW Agent │ │ CW Agent │    │ CW Agent │
    └──────────┘ └──────────┘    └──────────┘
```

## Execution Flow

```
site.yml
  ├── setup-docker.yml     → Installs Docker runtime
  ├── deploy-sockshop.yml  → Deploys application
  └── configure-monitoring.yml → Sets up CloudWatch
```
