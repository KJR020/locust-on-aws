output "repository_urls" {
  description = "ECRリポジトリのURL"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "repository_arns" {
  description = "ECRリポジトリのARN"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.arn }
}

output "repository_names" {
  description = "ECRリポジトリの名前"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.name }
}

output "registry_id" {
  description = "ECRレジストリID"
  value       = data.aws_caller_identity.current.account_id
}

output "repository_registry_ids" {
  description = "各リポジトリのレジストリID"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.registry_id }
}
