# Uncomment after running scripts/setup-backend.sh
# terraform {
#   backend "s3" {
#     bucket         = "sockshop-terraform-state-ACCOUNT_ID"
#     key            = "prod/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
