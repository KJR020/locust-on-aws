/**
 * Locustマスターモジュール
 * Locustマスターノードを実行するためのECSサービスとタスク定義を作成します
 */

/**
 * Locustマスター用のセキュリティグループ
 */
resource "aws_security_group" "master" {
  name        = "${var.general_name}-master-sg"
  description = "Security group for Locust master node"
  vpc_id      = var.vpc_id


  ingress {
    protocol    = "tcp"
    from_port   = 8089
    to_port     = 8089
    cidr_blocks = var.allowed_cidr_blocks
    description = "Locust Web UI"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5557
    to_port     = 5558
    cidr_blocks = ["10.0.0.0/8"]
    description = "Locust worker communication"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.general_name}-master-sg"
  }
}

/**
 * Locustマスター用のECSタスク実行ロール
 */
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.general_name}-master-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

/**
 * ECSタスク実行ロールへのポリシーアタッチ
 */
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

/**
 * Locustマスター用のECSタスク定義
 */
resource "aws_ecs_task_definition" "master" {
  family                   = "${var.general_name}-master"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.general_name}-master"
      image     = var.locust_image
      essential = true
      command   = ["--master", "-f", var.locust_file_path, "--host", var.target_host]

      portMappings = [
        {
          containerPort = 8089
          hostPort      = 8089
          protocol      = "tcp"
        },
        {
          containerPort = 5557
          hostPort      = 5557
          protocol      = "tcp"
        },
        {
          containerPort = 5558
          hostPort      = 5558
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.master.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "locust-master"
        }
      }
    }
  ])

  tags = {
    Name = "${var.general_name}-master-task"
  }
}

/**
 * Locustマスター用のCloudWatchロググループ
 */
resource "aws_cloudwatch_log_group" "master" {
  name              = "/ecs/${var.general_name}-master"
  retention_in_days = 30

  tags = {
    Name = "${var.general_name}-master-logs"
  }
}



/**
 * Locustマスター用のECSサービス
 */
resource "aws_ecs_service" "master" {
  name            = "${var.general_name}-master-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.master.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.master.id]
    subnets          = var.public_subnet_ids
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.master.arn
  }
  tags = {
    Name = "${var.general_name}-master-service"
  }
}

resource "aws_service_discovery_private_dns_namespace" "locust" {
  name        = "locust.internal"
  description = "Locust service discovery namespace"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "master" {
  name = "master"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.locust.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

}

/**
 * 現在のAWSリージョンの取得
 */
data "aws_region" "current" {}
