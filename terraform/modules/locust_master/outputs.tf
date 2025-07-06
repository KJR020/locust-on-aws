/**
 * Locustマスターモジュールの出力
 */

output "service_discovery_namespace_id" {
  description = "Service Discovery namespace ID"
  value       = aws_service_discovery_private_dns_namespace.locust.id
}

output "service_discovery_service_arn" {
  description = "Service Discovery service ARN"
  value       = aws_service_discovery_service.master.arn
}

output "master_security_group_id" {
  description = "Master security group ID"
  value       = aws_security_group.master.id
}

output "ecs_service_name" {
  description = "ECS service name for getting public IP"
  value       = aws_ecs_service.master.name
}
