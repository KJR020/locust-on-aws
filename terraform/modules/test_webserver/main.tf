/**
 * テスト対象となるWebサーバーモジュール
 * ECS Fargateを使用してオートスケーリング可能なWebサーバーを構築します
 */

# セキュリティグループ - ALB用
resource "aws_security_group" "alb" {
  name        = "${var.general_name}-test-alb-sg"
  description = "Security group for test webserver ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP connections"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.general_name}-test-alb-sg"
  }
}

# セキュリティグループ - ECSタスク用
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.general_name}-test-ecs-tasks-sg"
  description = "Security group for test webserver ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.alb.id]
    description     = "Allow traffic from ALB"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.general_name}-test-ecs-tasks-sg"
  }
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.general_name}-test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.general_name}-test-alb"
  }
}

# ALBターゲットグループ
resource "aws_lb_target_group" "app" {
  name        = "${var.general_name}-test-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 5
    path                = var.health_check_path
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.general_name}-test-tg"
  }
}

# ALBリスナー
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.id
  }
}

# CloudWatch Logs グループ
resource "aws_cloudwatch_log_group" "test_webserver" {
  name              = "/ecs/${var.general_name}-test-webserver"
  retention_in_days = 30

  tags = {
    Name = "${var.general_name}-test-webserver-logs"
  }
}

# ECSタスク定義
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.general_name}-test-webserver"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.general_name}-test-container"
      image     = var.app_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = tostring(var.container_port)
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.test_webserver.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.general_name}-test-webserver-task"
  }
}

# IAMロール - ECSタスク実行ロール
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.general_name}-test-ecs-task-execution-role"

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

  tags = {
    Name = "${var.general_name}-test-ecs-task-execution-role"
  }
}

# IAMロール - ECSタスクロール
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.general_name}-test-ecs-task-role"

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

  tags = {
    Name = "${var.general_name}-test-ecs-task-role"
  }
}

# IAMポリシーアタッチメント - ECSタスク実行ロール
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSサービス
resource "aws_ecs_service" "main" {
  name                               = "${var.general_name}-test-service"
  cluster                            = var.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.app.arn
  desired_count                      = var.app_count
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.id
    container_name   = "${var.general_name}-test-container"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Name = "${var.general_name}-test-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU使用率に基づくスケーリングポリシー
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.general_name}-test-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# リクエスト数に基づくスケーリングポリシー
resource "aws_appautoscaling_policy" "requests" {
  name               = "${var.general_name}-test-requests-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
    target_value       = var.request_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
