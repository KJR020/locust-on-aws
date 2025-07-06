/**
 * テスト対象となるWebサーバーモジュールの出力変数
 */

output "alb_hostname" {
  description = "テスト用WebサーバーのALBのホスト名"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "テスト用WebサーバーのALBのARN"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "テスト用WebサーバーのターゲットグループのARN"
  value       = aws_lb_target_group.app.arn
}

output "service_name" {
  description = "テスト用WebサーバーのECSサービス名"
  value       = aws_ecs_service.main.name
}

output "service_id" {
  description = "テスト用WebサーバーのECSサービスID"
  value       = aws_ecs_service.main.id
}

output "task_definition_arn" {
  description = "テスト用WebサーバーのECSタスク定義ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "alb_security_group_id" {
  description = "テスト用WebサーバーのALBセキュリティグループID"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "テスト用WebサーバーのECSタスクセキュリティグループID"
  value       = aws_security_group.ecs_tasks.id
}

output "alb_url" {
  description = "テスト用WebサーバーのURL"
  value       = "http://${aws_lb.main.dns_name}"
}
