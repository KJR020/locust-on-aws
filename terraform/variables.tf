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
