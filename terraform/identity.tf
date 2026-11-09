data "aws_caller_identity" "current" {}

output "active_role_name" {
  description = "IAM role used by Terraform"
  value       = split("/", data.aws_caller_identity.current.arn)[1]
}

output "active_account_id" {
  description = "AWS account used by Terraform"
  value       = data.aws_caller_identity.current.account_id
  sensitive   = true
}