/**
 * ECSクラスターとアプリケーションのデプロイ用Terraform設定ファイル
 * 段階的デプロイの第2段階：ECRにイメージがプッシュされた後にECSサービスを立ち上げる
 * 
 * 使用方法：
 * 1. 先にecr-only.tfでECRリポジトリを作成
 * 2. DockerイメージをECRにプッシュ
 * 3. このファイルを使用してECSクラスターとサービスをデプロイ
 */

# DataソースでECRリポジトリの情報を取得
data "aws_ecr_repository" "webserver" {
  name = "test-webserver"
}

data "aws_ecr_repository" "locust" {
  name = "locust-custom"
}

provider "aws" {
  region = var.aws_region
}

/**
 * ネットワークリソースの作成
 */
module "network" {
  source = "./modules/network"

  general_name = var.general_name
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
}

/**
 * ECSクラスターの作成
 */
module "ecs_cluster" {
  source = "./modules/ecs_cluster"

  general_name = var.general_name
}

/**
 * テスト対象のWebサーバーの設定
 */
module "test_webserver" {
  source = "./modules/test_webserver"

  general_name         = "${var.general_name}-target"
  aws_region           = var.aws_region
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  private_subnet_ids   = module.network.private_subnet_ids
  ecs_cluster_id       = module.ecs_cluster.cluster_id
  ecs_cluster_name     = module.ecs_cluster.cluster_name
  fargate_cpu          = var.fargate_cpu
  fargate_memory       = var.fargate_memory
  app_image            = "${data.aws_ecr_repository.webserver.repository_url}:latest"
  container_port       = var.test_container_port
  app_count            = var.test_app_count
  min_capacity         = var.test_min_capacity
  max_capacity         = var.test_max_capacity
  cpu_target_value     = var.test_cpu_target_value
  request_target_value = var.test_request_target_value
}

/**
 * Locustマスターの設定
 */
module "locust_master" {
  source = "./modules/locust_master"

  general_name      = var.general_name
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  ecs_cluster_id    = module.ecs_cluster.cluster_id
  fargate_cpu       = var.fargate_cpu
  fargate_memory    = var.fargate_memory
  locust_image      = "${data.aws_ecr_repository.locust.repository_url}:latest"
  target_host       = "http://${module.test_webserver.alb_hostname}"
  locust_file_path  = var.locust_file_path

  # WebUIへのアクセスを特定のIPアドレスのみに制限
  allowed_cidr_blocks = ["111.96.237.208/32"]

  # HTTPSを有効にする場合は以下をコメント解除
  enable_https = true
}

/**
 * Locustワーカーの設定
 */
module "locust_worker" {
  source = "./modules/locust_worker"

  general_name       = var.general_name
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  ecs_cluster_id     = module.ecs_cluster.cluster_id
  fargate_cpu        = var.fargate_cpu
  fargate_memory     = var.fargate_memory
  locust_image       = "${data.aws_ecr_repository.locust.repository_url}:latest"
  master_host        = module.locust_master.master_host
  worker_count       = var.worker_count
  target_host        = "http://${module.test_webserver.alb_hostname}"
  locust_file_path   = var.locust_file_path
}