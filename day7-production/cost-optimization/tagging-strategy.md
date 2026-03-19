# Resource Tagging Strategy

## Required Tags (All Resources)

| Tag Key | Description | Example Values |
|---------|-------------|----------------|
| `Project` | Project name | SockShop |
| `Environment` | Deployment env | dev, staging, prod |
| `Owner` | Team/person | devops-team |
| `ManagedBy` | Management tool | Terraform, Manual |
| `CostCenter` | Billing group | engineering |

## Optional Tags

| Tag Key | Description |
|---------|-------------|
| `Application` | Specific service |
| `Version` | App version |
| `CreatedDate` | Resource creation date |
| `ExpiryDate` | Auto-cleanup date |

## Enforcement

- Terraform `default_tags` block enforces tags automatically
- AWS Config rule `required-tags` for compliance
- Monthly audit of untagged resources
