/**
 * Locustワーカーモジュールの出力変数
 */

output "worker_security_group_id" {
  description = "LocustワーカーのセキュリティグループのID"
  value       = aws_security_group.worker.id
}

output "worker_task_definition_arn" {
  description = "Locustワーカーのタスク定義ARN"
  value       = aws_ecs_task_definition.worker.arn
}

output "worker_service_id" {
  description = "LocustワーカーのサービスのID"
  value       = aws_ecs_service.worker.id
}

output "service_name" {
  description = "Locustワーカーのサービスの名前"
  value       = aws_ecs_service.worker.name
}

output "worker_count" {
  description = "起動したLocustワーカーの数"
  value       = var.worker_count
}
