/**
 * ECSクラスターモジュールの出力変数
 */

output "cluster_id" {
  description = "ECSクラスターのID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECSクラスターの名前"
  value       = aws_ecs_cluster.main.name
}
