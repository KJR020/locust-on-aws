/**
 * メインTerraform設定ファイル
 * AWS ECS Fargate上にLocustクラスターを構築します
 */

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
 * ECRリポジトリの作成
 */
module "ecr" {
  source = "./modules/ecr"

  general_name = var.general_name
  repositories = {
    webserver = {
      name                 = "test-webserver"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      lifecycle_policy = {
        untagged_expire_days = 1
        tagged_expire_days   = 7
        max_image_count      = 30
      }
    }
    locust = {
      name                 = "locust-custom"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
      lifecycle_policy = {
        untagged_expire_days = 1
        tagged_expire_days   = 7
        max_image_count      = 20
      }
    }
  }

  tags = {
    Project     = "locust-on-aws"
    Environment = var.general_name
    ManagedBy   = "terraform"
  }
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
  app_image            = "${module.ecr.repository_urls["webserver"]}:latest"
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
  vpc_cidr          = var.vpc_cidr
  public_subnet_ids = module.network.public_subnet_ids
  ecs_cluster_id    = module.ecs_cluster.cluster_id
  fargate_cpu       = var.fargate_cpu
  fargate_memory    = var.fargate_memory
  locust_image      = "${module.ecr.repository_urls["locust"]}:latest"
  target_host       = "http://${module.test_webserver.alb_hostname}"
  locust_file_path  = var.locust_file_path

  # WebUIへのアクセスを制限（terraform.tfvarsで設定）
  allowed_cidr_blocks = var.allowed_cidr_blocks
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
  locust_image       = "${module.ecr.repository_urls["locust"]}:latest"
  master_host        = "master.locust.internal"
  worker_count       = var.worker_count
  target_host        = "http://${module.test_webserver.alb_hostname}"
  locust_file_path   = var.locust_file_path
}
