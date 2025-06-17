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
    from_port   = 80
    to_port     = 80
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTP for ALB"
  }
  
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTPS for ALB"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8089
    to_port     = 8089
    cidr_blocks = ["0.0.0.0/0"]
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
 * Locustマスター用のALB
 */
resource "aws_lb" "master" {
  name               = "${var.general_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.master.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "${var.general_name}-alb"
  }
}

/**
 * Locustマスター用のALBターゲットグループ
 */
resource "aws_lb_target_group" "master" {
  name        = "${var.general_name}-tg"
  port        = 8089
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/"
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.general_name}-tg"
  }
}

/**
 * Locustマスター用の自己署名証明書
 */
resource "tls_private_key" "locust" {
  count     = var.enable_https ? 1 : 0
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "locust" {
  count           = var.enable_https ? 1 : 0
  private_key_pem = tls_private_key.locust[0].private_key_pem

  subject {
    common_name  = "locust.local"
    organization = "Locust Load Testing"
  }

  validity_period_hours = 8760 # 1年

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "locust" {
  count            = var.enable_https ? 1 : 0
  private_key      = tls_private_key.locust[0].private_key_pem
  certificate_body = tls_self_signed_cert.locust[0].cert_pem

  tags = {
    Name = "${var.general_name}-cert"
  }
}

/**
 * Locustマスター用のALBリスナー（HTTP）
 */
resource "aws_lb_listener" "master_http" {
  load_balancer_arn = aws_lb.master.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.enable_https ? "redirect" : "forward"
    
    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    
    target_group_arn = var.enable_https ? null : aws_lb_target_group.master.arn
  }
}

/**
 * Locustマスター用のALBリスナー（HTTPS）
 */
resource "aws_lb_listener" "master_https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.master.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.locust[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.master.arn
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

  load_balancer {
    target_group_arn = aws_lb_target_group.master.arn
    container_name   = "${var.general_name}-master"
    container_port   = 8089
  }

  depends_on = [
    aws_lb_listener.master_http,
    aws_lb_listener.master_https
  ]

  tags = {
    Name = "${var.general_name}-master-service"
  }
}



/**
 * 現在のAWSリージョンの取得
 */
data "aws_region" "current" {}
