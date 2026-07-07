output "db_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "db_address" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_instance_id" {
  value = aws_db_instance.this.id
}

# Points at the AWS-managed master-user secret (created via
# manage_master_user_password = true) rather than a hand-rolled one, so no
# credential of any kind is ever written into Terraform state or a .tf file.
output "secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}
