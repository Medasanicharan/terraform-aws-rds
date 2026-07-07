## master credentials ##
## manage_master_user_password = true delegates password generation,
## storage, and rotation entirely to a Secrets Manager secret that AWS
## creates and owns. No credential of any kind is ever in Terraform state
## or a .tf file.

resource "aws_db_instance" "this" {
  identifier     = "${local.resource_name}-db"
  engine         = var.engine == "postgres" ? "postgres" : "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username
  port     = local.port

  manage_master_user_password = true

  db_subnet_group_name   = var.database_subnet_group_name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false # must only be reachable from ECS/Fargate SG

  multi_az                  = var.multi_az
  backup_retention_period    = var.backup_retention_period
  backup_window              = "03:00-04:00"
  maintenance_window          = "mon:04:30-mon:05:30"
  deletion_protection          = var.deletion_protection
  skip_final_snapshot           = !var.deletion_protection
  final_snapshot_identifier      = var.deletion_protection ? "${local.resource_name}-final-snapshot" : null
  copy_tags_to_snapshot            = true

  performance_insights_enabled = true

  ## Enhanced monitoring (OS-level metrics) — Performance Insights alone
  ## only covers database-level metrics.
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = var.engine == "postgres" ? ["postgresql"] : ["error", "slowquery"]

  tags = merge(
    var.common_tags,
    var.rds_tags,
    {
      Name = "${local.resource_name}-db"
    }
  )
}

## enhanced monitoring IAM role - only created when monitoring is enabled ##

data "aws_iam_policy_document" "rds_monitoring_assume" {
  count = var.monitoring_interval > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  count              = var.monitoring_interval > 0 ? 1 : 0
  name               = "${local.resource_name}-rds-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume[0].json
  tags               = merge(var.common_tags, var.rds_tags)
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

## Basic CloudWatch alarms so storage exhaustion / CPU saturation doesn't
## go unnoticed. Actions only fire if an SNS topic is supplied; otherwise
## the alarms still exist and are visible in the console/CLI.

resource "aws_cloudwatch_metric_alarm" "free_storage_low" {
  alarm_name          = "${local.resource_name}-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2 GiB
  alarm_description   = "RDS free storage below 2GiB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  tags          = merge(var.common_tags, var.rds_tags)
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.resource_name}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU above 80% for 15 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  alarm_actions = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != null ? [var.alarm_sns_topic_arn] : []
  tags          = merge(var.common_tags, var.rds_tags)
}
