/**
 * Terraformの出力変数定義ファイル
 * 各モジュールから必要な出力値を集約し、外部からアクセス可能にします
 */

# =============================================================================
# Locust関連の出力
# =============================================================================

output "locust_web_ui_access_info" {
  description = "Locust Web UIへのアクセス情報"
  value = {
    ecs_service_name = module.locust_master.ecs_service_name
    cluster_name     = module.ecs_cluster.cluster_name
    port            = "8089"
    access_note     = "ECSコンソールでタスクのパブリックIPを確認してアクセスしてください"
    url_format      = "http://<MASTER_PUBLIC_IP>:8089"
  }
}

output "locust_master_host" {
  description = "Locustマスターホスト"
  value       = "master.locust.internal"
}

output "locust_master_service_name" {
  description = "Locustマスターサービスの名前"
  value       = module.locust_master.ecs_service_name
}

output "locust_worker_service_name" {
  description = "Locustワーカーサービスの名前"
  value       = module.locust_worker.service_name
}

output "locust_worker_count" {
  description = "起動したLocustワーカーの数"
  value       = module.locust_worker.worker_count
}

# =============================================================================
# テスト対象Webサーバー関連の出力
# =============================================================================

output "test_webserver_url" {
  description = "テスト対象WebサーバーのURL"
  value       = module.test_webserver.alb_url
}

output "test_webserver_hostname" {
  description = "テスト対象WebサーバーのALBホスト名"
  value       = module.test_webserver.alb_hostname
}

output "test_webserver_service_name" {
  description = "テスト対象WebサーバーのECSサービス名"
  value       = module.test_webserver.service_name
}

# =============================================================================
# ネットワーク関連の出力
# =============================================================================

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

# =============================================================================
# ECS関連の出力
# =============================================================================

output "ecs_cluster_id" {
  description = "ECSクラスターのID"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_name" {
  description = "ECSクラスターの名前"
  value       = module.ecs_cluster.cluster_name
}

# =============================================================================
# ECR関連の出力
# =============================================================================

output "ecr_repository_urls" {
  description = "ECRリポジトリのURL"
  value       = module.ecr.repository_urls
}

output "ecr_repository_names" {
  description = "ECRリポジトリの名前"
  value       = module.ecr.repository_names
}

output "ecr_repository_arns" {
  description = "ECRリポジトリのARN"
  value       = module.ecr.repository_arns
}

output "ecr_registry_id" {
  description = "ECRレジストリID"
  value       = module.ecr.registry_id
}

# =============================================================================
# 便利な組み合わせ出力
# =============================================================================

output "deployment_summary" {
  description = "デプロイメント概要"
  value = {
    locust_web_ui_info = "ECSコンソールでパブリックIPを確認: http://<IP>:8089"
    target_app_url     = module.test_webserver.alb_url
    worker_count       = module.locust_worker.worker_count
    ecs_cluster        = module.ecs_cluster.cluster_name
    vpc_id            = module.network.vpc_id
  }
}

output "container_images" {
  description = "使用されるコンテナイメージ"
  value = {
    locust    = "${module.ecr.repository_urls["locust"]}:latest"
    webserver = "${module.ecr.repository_urls["webserver"]}:latest"
  }
}
