variable "general_name" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "repositories" {
  description = "作成するECRリポジトリの設定"
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "MUTABLE")
    scan_on_push        = optional(bool, true)
    lifecycle_policy = optional(object({
      untagged_expire_days = optional(number, 1)
      tagged_expire_days   = optional(number, 7)
      max_image_count     = optional(number, 30)
    }), {})
  }))
  default = {}
}

variable "allowed_principals" {
  description = "ECRアクセスを許可するAWSアカウントIDまたはARN"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "リソースに適用するタグ"
  type        = map(string)
  default     = {}
}

variable "enable_cross_region_replication" {
  description = "クロスリージョンレプリケーションを有効にするかどうか"
  type        = bool
  default     = false
}

variable "replication_regions" {
  description = "レプリケーション先のリージョン一覧"
  type        = list(string)
  default     = []
}
