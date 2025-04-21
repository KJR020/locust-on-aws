/**
 * Terraformの出力変数定義ファイル
 */

output "locust_web_ui_url" {
  description = "Locust Web UIのURL"
  value       = module.locust_master.locust_web_ui_url
}

output "vpc_id" {
  description = "作成されたVPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "パブリックサブネットのID"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "プライベートサブネットのID"
  value       = module.network.private_subnet_ids
}

output "ecs_cluster_id" {
  description = "ECSクラスターのID"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "ECSクラスターの名前"
  value       = module.ecs_cluster.cluster_name
}

output "master_service_name" {
  description = "Locustマスターサービスの名前"
  value       = module.locust_master.service_name
}

output "worker_service_name" {
  description = "Locustワーカーサービスの名前"
  value       = module.locust_worker.service_name
}
