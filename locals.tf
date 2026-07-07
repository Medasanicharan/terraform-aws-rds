locals {
  resource_name = "${var.project_name}-${var.environment}"
  port          = var.engine == "postgres" ? 5432 : 3306
}
