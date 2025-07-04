/**
 * Locustワーカーモジュール
 * Locustワーカーノードを実行するためのECSサービスとタスク定義を作成します
 */

/**
 * Locustワーカー用のセキュリティグループ
 */
resource "aws_security_group" "worker" {
  name        = "${var.general_name}-worker-sg"
  description = "Security group for Locust worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 5557
    to_port     = 5558
    cidr_blocks = ["10.0.0.0/16"]  // VPCのCIDRブロックに合わせて設定
    description = "Locust master communication"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.general_name}-worker-sg"
  }
}

/**
 * Locustワーカー用のECSタスク実行ロール
 */
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.general_name}-worker-execution-role"

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
 * Locustワーカー用のECSタスク定義
 */
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.general_name}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.general_name}-worker"
      image     = var.locust_image
      essential = true
      command   = ["--worker", "--master-host", var.master_host, "-f", var.locust_file_path, "--host", var.target_host]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "locust-worker"
        }
      }
    }
  ])

  tags = {
    Name = "${var.general_name}-worker-task"
  }
}

/**
 * Locustワーカー用のCloudWatchロググループ
 */
resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.general_name}-worker"
  retention_in_days = 30

  tags = {
    Name = "${var.general_name}-worker-logs"
  }
}

/**
 * Locustワーカー用のECSサービス
 */
resource "aws_ecs_service" "worker" {
  name            = "${var.general_name}-worker-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.worker.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  tags = {
    Name = "${var.general_name}-worker-service"
  }
}

/**
 * 現在のAWSリージョンの取得
 */
data "aws_region" "current" {}
