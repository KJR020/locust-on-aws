/**
 * テスト対象となるWebサーバーモジュールの変数定義
 */

variable "general_name" {
  description = "リソースの名前などに使う文字列"
  type        = string
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "パブリックサブネットのID一覧"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "プライベートサブネットのID一覧"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ECSクラスターのID"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECSクラスターの名前"
  type        = string
}

variable "fargate_cpu" {
  description = "Fargateタスクに割り当てるCPUユニット"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "Fargateタスクに割り当てるメモリ (MB)"
  type        = number
  default     = 512
}

variable "app_image" {
  description = "Webサーバーのコンテナイメージ"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "コンテナのポート"
  type        = number
  default     = 80
}

variable "app_count" {
  description = "起動するタスクの数"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "ヘルスチェックのパス"
  type        = string
  default     = "/"
}

variable "min_capacity" {
  description = "Auto Scalingの最小容量"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Auto Scalingの最大容量"
  type        = number
  default     = 10
}

variable "cpu_target_value" {
  description = "CPU使用率のターゲット値（％）"
  type        = number
  default     = 60
}

variable "request_target_value" {
  description = "ターゲットあたりのリクエスト数のターゲット値"
  type        = number
  default     = 1000
}
