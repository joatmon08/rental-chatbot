
resource "aws_redshiftserverless_namespace" "rentals" {
  namespace_name = var.name
}

resource "aws_redshiftserverless_workgroup" "rentals" {
  namespace_name      = aws_redshiftserverless_namespace.rentals.namespace_name
  workgroup_name      = "bookings"
  base_capacity       = 8
  publicly_accessible = false

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.database.id]

  config_parameter {
    parameter_key   = "enable_case_sensitive_identifier"
    parameter_value = "true"
  }
}

resource "aws_rds_integration" "rentals_redshift" {
  integration_name = "${var.name}-bookings-redshift"
  source_arn       = aws_rds_cluster.postgresql.arn
  target_arn       = aws_redshiftserverless_namespace.rentals.arn
  data_filter      = "include: ${aws_rds_cluster.postgresql.database_name}.public.bookings"
}