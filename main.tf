provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "bucket-name"
    key    = "key-name"
    region = "us-east-1"
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "your-subnet-group-name"
  subnet_ids = ["subnet-12345678", "subnet-23456789"]
}

resource "aws_security_group" "postgres" {
  name_prefix = "your-sg-name-prefix"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_cluster_parameter_group" "postgres" {
  name        = "your-cluster-pg-name"
  family      = "postgres12"
  description = "Parameter group for your RDS cluster"
  
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_cluster_snapshot_identifier" "postgres" {
  identifier_prefix = "your-snapshot-identifier-prefix"
}

resource "aws_rds_cluster" "postgres" {
  cluster_identifier            = "your-cluster-identifier"
  engine                        = "aurora-postgresql"
  engine_version                = "12.6"
  database_name                 = "your-db-name"
  master_username               = "your-db-username"
  master_password               = var.your-db-password
  db_subnet_group_name          = aws_db_subnet_group.postgres.name
  vpc_security_group_ids        = [aws_security_group.postgres.id]
  db_cluster_parameter_group_name = aws_db_cluster_parameter_group.postgres.name
  snapshot_identifier           = aws_db_cluster_snapshot_identifier.postgres.id

  scaling_configuration {
    auto_pause                = true
    max_capacity              = 4
    min_capacity              = 2
    seconds_until_auto_pause  = 300
    timeout_action            = "ForceApplyCapacityChange"
  }

  tags = {
    Name = "your-cluster-name"
  }
}

resource "aws_rds_cluster_instance" "postgres" {
  count                 = 2
  identifier            = "your-instance-identifier-${count.index}"
  db_subnet_group_name  = aws_db_subnet_group.postgres.name
  cluster_identifier    = aws_rds_cluster.postgres.id
  instance_class        = "db.r5.large"
  engine                = "aurora-postgresql"
  engine_version        = "12.6"
  publicly_accessible   = false
  db_parameter_group_name = aws_db_cluster_parameter_group.postgres.name
}

output "rds_cluster_endpoint" {
  value = aws_rds_cluster.postgres.endpoint
}
