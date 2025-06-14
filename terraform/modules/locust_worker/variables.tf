/**
 * Locustワーカーモジュールの変数定義
 */

variable "general_name" {
  description = "リソースの名前などに使う文字列"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "プライベートサブネットのID一覧"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ECSクラスターのID"
  type        = string
}

variable "fargate_cpu" {
  description = "Fargateタスクに割り当てるCPUユニット"
  type        = number
}

variable "fargate_memory" {
  description = "Fargateタスクに割り当てるメモリ (MB)"
  type        = number
}

variable "locust_image" {
  description = "使用するLocustのDockerイメージ"
  type        = string
}

variable "master_host" {
  description = "Locustマスターのホスト名"
  type        = string
}

variable "worker_count" {
  description = "起動するLocustワーカーの数"
  type        = number
}

variable "target_host" {
  description = "負荷テスト対象のホスト"
  type        = string
}

variable "locust_file_path" {
  description = "Locustファイルのパス"
  type        = string
}
