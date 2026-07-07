## project ##

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type    = map(any)
  default = {}
}

## rds ##

variable "database_subnet_group_name" {
  type = string
}

variable "rds_sg_id" {
  type = string
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "16.4"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "multi_az" {
  type = bool
}

variable "backup_retention_period" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

variable "db_name" {
  type    = string
  default = "bookings"
}

variable "master_username" {
  type    = string
  default = "app_admin"
}

## Both optional so this module still drops in anywhere the old one did
## without any other changes required. ##

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. 0 disables it (dev), 60 is typical for prod."
  type        = number
  default     = 0
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm actions. Leave null to create alarms without notification actions."
  type        = string
  default     = null
}

variable "rds_tags" {
  type    = map(any)
  default = {}
}
