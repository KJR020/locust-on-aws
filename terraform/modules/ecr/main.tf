# 現在のAWSアカウント情報を取得
data "aws_caller_identity" "current" {}

# 現在のリージョン情報を取得
data "aws_region" "current" {}

# ECRリポジトリの作成
resource "aws_ecr_repository" "repositories" {
  for_each = var.repositories

  name                 = "${var.general_name}-${each.value.name}"
  image_tag_mutability = each.value.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name        = "${var.general_name}-${each.value.name}"
    Environment = var.general_name
    ManagedBy   = "terraform"
  })
}

# ライフサイクルポリシーの作成
resource "aws_ecr_lifecycle_policy" "repositories" {
  for_each = { for k, v in var.repositories : k => v if v.lifecycle_policy != null }

  repository = aws_ecr_repository.repositories[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${each.value.lifecycle_policy.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = each.value.lifecycle_policy.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${each.value.lifecycle_policy.untagged_expire_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = each.value.lifecycle_policy.untagged_expire_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete tagged images older than ${each.value.lifecycle_policy.tagged_expire_days} days (excluding production tags)"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = ["dev", "staging", "feature", "hotfix"]
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = each.value.lifecycle_policy.tagged_expire_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# リポジトリポリシーの作成（外部アクセス制御）
resource "aws_ecr_repository_policy" "repositories" {
  for_each = { for k, v in var.repositories : k => v if length(var.allowed_principals) > 0 }

  repository = aws_ecr_repository.repositories[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# ECS タスク用のIAMロール
resource "aws_iam_role" "ecs_ecr_role" {
  name = "${var.general_name}-ecs-ecr-role"

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

  tags = merge(var.tags, {
    Name        = "${var.general_name}-ecs-ecr-role"
    Environment = var.general_name
    ManagedBy   = "terraform"
  })
}

# ECS タスク用のECRアクセスポリシー
resource "aws_iam_role_policy" "ecs_ecr_policy" {
  name = "${var.general_name}-ecs-ecr-policy"
  role = aws_iam_role.ecs_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = [for repo in aws_ecr_repository.repositories : repo.arn]
      }
    ]
  })
}

# CI/CD用のIAMロール（GitHub Actions等で使用）
resource "aws_iam_role" "cicd_ecr_role" {
  name = "${var.general_name}-cicd-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.general_name}-cicd-ecr-role"
    Environment = var.general_name
    ManagedBy   = "terraform"
  })
}

# CI/CD用のECRアクセスポリシー
resource "aws_iam_role_policy" "cicd_ecr_policy" {
  name = "${var.general_name}-cicd-ecr-policy"
  role = aws_iam_role.cicd_ecr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [for repo in aws_ecr_repository.repositories : repo.arn]
      }
    ]
  })
}

# クロスリージョンレプリケーション設定（オプション）
resource "aws_ecr_replication_configuration" "this" {
  count = var.enable_cross_region_replication ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = var.replication_regions
        content {
          region      = destination.value
          registry_id = data.aws_caller_identity.current.account_id
        }
      }
    }
  }
}
