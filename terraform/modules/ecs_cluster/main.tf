/**
 * ECSクラスターモジュール
 * Locustを実行するためのECSクラスターを作成します
 */

/**
 * ECSクラスターの作成
 */
resource "aws_ecs_cluster" "main" {
  name = "${var.general_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.general_name}-cluster"
  }
}

/**
 * ECSクラスターの容量プロバイダーの作成
 */
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}
