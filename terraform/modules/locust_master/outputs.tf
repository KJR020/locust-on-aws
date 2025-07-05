/**
 * Locustマスターモジュールの出力変数
 */

output "service_name" {
  description = "Locustマスターサービスの名前"
  value       = aws_ecs_service.master.name
}

output "master_host" {
  description = "Locustマスターホスト"
  value       = aws_lb.master.dns_name
}

output "locust_web_ui_url" {
  description = "Locust Web UIのURL"
  value       = "http://${aws_lb.master.dns_name}"
}

output "service_discovery_name" {
  description = "Locustマスターのサービスディスカバリー名"
  value       = "master.locust.internal"
}
