resource "aws_db_instance" "prod" {
  identifier     = "sockshop-prod-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = true
  multi_az          = true

  db_name  = "socksdb"
  username = var.db_username
  password = var.db_password

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "sockshop-prod-final"

  tags = { Name = "sockshop-prod-db", Environment = "prod" }
}
