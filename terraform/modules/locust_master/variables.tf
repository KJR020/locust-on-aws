/**
 * Locustマスターモジュールの変数定義
 */

variable "general_name" {
  description = "リソースの名前などに使う文字列"
  type        = string
}

variable "enable_https" {
  description = "HTTPSを有効にするかどうか"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "WebUIへのアクセスを許可するCIDRブロックのリスト"
  type        = list(string)
  default     = ["0.0.0.0/0"] # デフォルトは全てのIPからのアクセスを許可
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "パブリックサブネットのID"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ECSクラスターのID"
  type        = string
}

variable "fargate_cpu" {
  description = "コンテナのCPU (256=.25vCPU)"
  type        = number
}

variable "fargate_memory" {
  description = "コンテナに割り当てるメモリ (MB)"
  type        = number
}

variable "locust_image" {
  description = "使用するLocustのDockerイメージ"
  type        = string
}

variable "target_host" {
  description = "負荷テスト対象のホスト"
  type        = string
}

variable "locust_file_path" {
  description = "Locustファイルのパス"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for worker communication"
  type        = string
}
