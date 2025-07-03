/**
 * ECRリポジトリのみを作成するTerraform設定ファイル
 * 段階的デプロイの第1段階：ECRリポジトリを作成してDockerイメージをプッシュできるようにする
 */

provider "aws" {
  region = var.aws_region
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
 * ECRリポジトリのURLを出力
 */
output "ecr_repository_urls" {
  description = "ECRリポジトリのURL"
  value       = module.ecr.repository_urls
}

output "ecr_repository_webserver_url" {
  description = "WebサーバーのECRリポジトリURL"
  value       = module.ecr.repository_urls["webserver"]
}

output "ecr_repository_locust_url" {
  description = "LocustのECRリポジトリURL"
  value       = module.ecr.repository_urls["locust"]
}