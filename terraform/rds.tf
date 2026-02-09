# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.app_name}-db-subnet-group"
    Environment = var.environment
  }
}

# RDS Database Instance
resource "aws_db_instance" "main" {
  identifier           = "${var.app_name}-db"
  engine               = var.db_engine
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot       = true
  publicly_accessible       = false
  multi_az                  = false
  backup_retention_period   = 7
  backup_window             = "03:00-04:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  parameter_group_name      = aws_db_parameter_group.main.name
  deletion_protection       = false

  tags = {
    Name        = "${var.app_name}-db"
    Environment = var.environment
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  # Use a current parameter group family for PostgreSQL (postgres17)
  family = var.db_engine == "postgres" ? "postgres17" : "mysql8.0"
  name   = "${var.app_name}-db-params"

  tags = {
    Name        = "${var.app_name}-db-params"
    Environment = var.environment
  }
}
