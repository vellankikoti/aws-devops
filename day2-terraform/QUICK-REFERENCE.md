# Day 2: Terraform Quick Reference

## Core Commands

| Command | Description |
|---------|-------------|
| `terraform init` | Initialize working directory |
| `terraform plan` | Preview changes (dry run) |
| `terraform apply` | Apply changes |
| `terraform destroy` | Destroy all resources |
| `terraform fmt` | Format code |
| `terraform validate` | Validate configuration |
| `terraform output` | Show outputs |
| `terraform state list` | List resources in state |
| `terraform state show <resource>` | Show resource details |
| `terraform import <resource> <id>` | Import existing resource |

## Workspace Commands

```bash
terraform workspace list          # List workspaces
terraform workspace new dev       # Create workspace
terraform workspace select dev    # Switch workspace
terraform workspace show          # Current workspace
terraform workspace delete staging # Delete workspace
```

## State Commands

```bash
terraform state list                    # List all resources
terraform state show aws_instance.app   # Show resource detail
terraform state mv old_name new_name    # Rename resource
terraform state rm aws_instance.app     # Remove from state (not AWS)
terraform force-unlock LOCK_ID          # Force unlock state
terraform state pull                    # Download remote state
```

## Common Patterns

### Data Sources
```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

### Conditional Resources
```hcl
resource "aws_nat_gateway" "main" {
  count = var.enable_nat ? 1 : 0
}
```

### Dynamic Blocks
```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port   = ingress.value.port
    to_port     = ingress.value.port
    protocol    = "tcp"
    cidr_blocks = ingress.value.cidrs
  }
}
```

## File Structure

```
environments/dev/
├── main.tf          # Module calls
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── terraform.tfvars # Variable values
└── backend.tf       # State configuration
```

## Debugging

```bash
TF_LOG=DEBUG terraform plan     # Debug logging
terraform plan -out=plan.tfplan # Save plan
terraform show plan.tfplan      # Review saved plan
terraform graph | dot -Tpng > graph.png  # Dependency graph
```
