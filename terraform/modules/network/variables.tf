/**
 * ネットワークモジュールの変数定義
 */

variable "general_name" {
  description = "リソースの名前などに使う文字列"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
}

variable "az_count" {
  description = "使用するアベイラビリティゾーンの数"
  type        = number
}
