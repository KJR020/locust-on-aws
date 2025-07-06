/**
 * Terraformの変数定義ファイル
 */

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "general_name" {
  description = "リソースの名前などに使う文字列"
  type        = string
  default     = "locust-fargate"
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "使用するアベイラビリティゾーンの数"
  type        = number
  default     = 2
}

variable "worker_count" {
  description = "Locustワーカーコンテナの数"
  type        = number
  default     = 2
}

variable "fargate_cpu" {
  description = "コンテナのCPU (256=.25vCPU)"
  type        = number
  default     = 256
}

variable "fargate_memory" {
  description = "コンテナに割り当てるメモリ (MB)"
  type        = number
  default     = 512
}

variable "locust_image" {
  description = "使用するLocustのDockerイメージ"
  type        = string
  default     = "locustio/locust:latest"
}

variable "target_host" {
  description = "負荷テスト対象のホスト"
  type        = string
  default     = "https://example.com"
}

variable "locust_file_path" {
  description = "Locustファイルのパス"
  type        = string
  default     = "/mnt/locust/locustfile.py"
}

/**
 * テスト対象のWebサーバーの変数
 */
variable "test_app_image" {
  description = "テスト対象のWebサーバーのイメージ"
  type        = string
  default     = "nginx:latest"
}

variable "test_container_port" {
  description = "テスト対象のWebサーバーのコンテナポート"
  type        = number
  default     = 3000
}

variable "test_app_count" {
  description = "テスト対象のWebサーバーの初期タスク数"
  type        = number
  default     = 2
}

variable "test_min_capacity" {
  description = "テスト対象のWebサーバーの最小キャパシティ"
  type        = number
  default     = 2
}

variable "test_max_capacity" {
  description = "テスト対象のWebサーバーの最大キャパシティ"
  type        = number
  default     = 10
}

variable "test_cpu_target_value" {
  description = "テスト対象のWebサーバーのCPU使用率のターゲット値（％）"
  type        = number
  default     = 60
}

variable "test_request_target_value" {
  description = "テスト対象のWebサーバーのターゲットあたりのリクエスト数のターゲット値"
  type        = number
  default     = 1000
}

variable "allowed_cidr_blocks" {
  description = "Locust Web UIへのアクセスを許可するCIDRブロック"
  type        = list(string)
  default     = ["10.0.0.0/8"]  # デフォルトはプライベートネットワークのみ
}
