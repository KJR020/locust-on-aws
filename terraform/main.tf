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
 * ECSクラスターの作成
 */
module "ecs_cluster" {
  source = "./modules/ecs_cluster"

  general_name = var.general_name
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
  locust_image      = var.locust_image
  target_host       = var.target_host
  locust_file_path  = var.locust_file_path
}

/**
 * Locustワーカーの設定
 */
module "locust_worker" {
  source = "./modules/locust_worker"

  general_name      = var.general_name
  vpc_id            = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  ecs_cluster_id    = module.ecs_cluster.cluster_id
  fargate_cpu       = var.fargate_cpu
  fargate_memory    = var.fargate_memory
  locust_image      = var.locust_image
  master_host       = module.locust_master.master_host
  worker_count      = var.worker_count
  target_host       = var.target_host
  locust_file_path  = var.locust_file_path
}
