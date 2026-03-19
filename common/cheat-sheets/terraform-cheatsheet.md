# Terraform Cheat Sheet

## Commands
```bash
terraform init          # Initialize
terraform plan          # Preview changes
terraform apply         # Apply changes
terraform destroy       # Destroy all
terraform fmt           # Format code
terraform validate      # Check syntax
terraform output        # Show outputs
terraform state list    # List resources
terraform import RES ID # Import existing
terraform taint RES     # Mark for recreation
terraform workspace list/new/select
```

## HCL Patterns
```hcl
# Variable types
variable "name" { type = string; default = "value" }
variable "list" { type = list(string); default = ["a","b"] }
variable "map"  { type = map(string); default = { key = "val" } }

# Conditionals
count = var.enabled ? 1 : 0

# Loops
for_each = toset(["a", "b", "c"])

# Locals
locals { name = "${var.prefix}-${var.env}" }

# Data sources
data "aws_ami" "latest" { most_recent = true }
```
