# ECR統合設計 - Locust on AWS

## 概要

このドキュメントでは、既存のLocust on AWSプロジェクトにAmazon Elastic Container Registry (ECR)を統合するための設計について説明します。

## 現在の課題

1. **Dockerイメージ管理の不明確さ**: 現在、WebサーバーとLocustのDockerイメージをどこで管理しているかが明確でない
2. **デプロイの複雑さ**: 手動でのイメージビルドとプッシュが必要
3. **バージョン管理**: イメージのバージョニングとタグ管理が体系化されていない
4. **セキュリティ**: パブリックレジストリに依存するリスク

## ECR統合の目標

1. **プライベートレジストリの構築**: AWSネイティブなプライベートコンテナレジストリの利用
2. **自動化**: CI/CDパイプラインでの自動ビルド・プッシュ
3. **セキュリティ**: IAMベースのアクセス制御
4. **コスト最適化**: ライフサイクルポリシーによる古いイメージの自動削除
5. **モジュール化**: 再利用可能なTerraformモジュールとしての実装

## アーキテクチャ設計

### ECRモジュール構成

```
terraform/
├── modules/
│   ├── ecr/                    # 新規追加
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── network/
│   ├── ecs_cluster/
│   ├── locust_master/
│   ├── locust_worker/
│   └── test_webserver/
└── main.tf
```

### ECRリポジトリ戦略

#### 1. リポジトリ構成
- **test-webserver**: テスト対象のWebサーバーアプリケーション
- **locust-custom**: カスタムLocustイメージ（必要に応じて）

#### 2. タグ戦略
- **latest**: 最新の安定版
- **v{major}.{minor}.{patch}**: セマンティックバージョニング
- **{git-sha}**: GitコミットハッシュベースのタグAL
- **{environment}**: 環境別タグ（dev, staging, prod）

#### 3. ライフサイクルポリシー
- **未タグイメージ**: 1日後に削除
- **開発用タグ**: 7日後に削除
- **本番用タグ**: 30個の最新イメージを保持

## モジュール設計詳細

### ECRモジュール (`./modules/ecr`)

#### 入力変数 (variables.tf)
```hcl
variable "general_name" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "repositories" {
  description = "作成するECRリポジトリの設定"
  type = map(object({
    name                 = string
    image_tag_mutability = string
    scan_on_push        = bool
    lifecycle_policy    = object({
      untagged_expire_days = number
      tagged_expire_days   = number
      max_image_count     = number
    })
  }))
}

variable "allowed_principals" {
  description = "ECRアクセスを許可するAWSアカウントID"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "リソースに適用するタグ"
  type        = map(string)
  default     = {}
}
```

#### 主要リソース (main.tf)
1. **ECRリポジトリ** (`aws_ecr_repository`)
   - イメージスキャンの有効化
   - タグの変更可能性設定
   - 暗号化設定

2. **ライフサイクルポリシー** (`aws_ecr_lifecycle_policy`)
   - 古いイメージの自動削除
   - 未タグイメージの管理
   - イメージ数の上限設定

3. **リポジトリポリシー** (`aws_ecr_repository_policy`)
   - IAMベースのアクセス制御
   - クロスアカウントアクセス（必要に応じて）

4. **IAMロール・ポリシー**
   - ECSタスクからのECRアクセス用
   - CI/CDパイプライン用のプッシュ権限

#### 出力値 (outputs.tf)
```hcl
output "repository_urls" {
  description = "ECRリポジトリのURL"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.repository_url }
}

output "repository_arns" {
  description = "ECRリポジトリのARN"
  value       = { for k, v in aws_ecr_repository.repositories : k => v.arn }
}

output "registry_id" {
  description = "ECRレジストリID"
  value       = data.aws_caller_identity.current.account_id
}
```

## 統合計画

### Phase 1: ECRモジュール作成
1. ECRモジュールの実装
2. 基本的なリポジトリとポリシーの作成
3. 既存のmain.tfからの呼び出し

### Phase 2: 既存モジュールの更新
1. test_webserverモジュールでECRイメージを参照するように変更
2. locust_master/workerモジュールでECRイメージを参照するように変更
3. Dockerfileの更新（WebサーバーをTypeScriptベースに統一）

### Phase 3: CI/CDパイプライン（将来的）
1. GitHub ActionsまたはAWS CodePipelineの設定
2. 自動ビルド・プッシュワークフロー
3. タグベースのデプロイメント

## 実装上の考慮事項

### 1. セキュリティ
- **プライベートリポジトリ**: パブリックアクセスは無効
- **イメージスキャン**: 脆弱性スキャンを有効化
- **IAM最小権限**: 必要最小限のアクセス権のみ付与

### 2. コスト最適化
- **ライフサイクルポリシー**: 不要なイメージの自動削除
- **圧縮**: マルチステージビルドによるイメージサイズ削減
- **適切なタグ戦略**: 無駄なイメージの蓄積を防止

### 3. 運用性
- **モニタリング**: CloudWatchメトリクスの活用
- **ログ記録**: API呼び出しのCloudTrailログ
- **タグ管理**: 一貫したタグ戦略による管理性向上

### 4. 既存システムへの影響
- **後方互換性**: 既存のデプロイメントに影響を与えない段階的移行
- **ゼロダウンタイム**: ローリングアップデートによる無停止移行
- **ロールバック計画**: 問題発生時の迅速な復旧

## 次のステップ

1. **ECRモジュールの実装**: 基本的なECRリポジトリとポリシーの作成
2. **Dockerfileの更新**: WebサーバーのTypeScript統一に合わせた調整
3. **main.tfの更新**: ECRモジュールの呼び出し追加
4. **既存モジュールの更新**: ECRイメージ参照への変更
5. **テスト**: 新しい構成での動作確認

この設計により、ECRを効果的に統合し、コンテナイメージの管理を自動化・最適化できます。

## 実装状況

### ✅ 完了済み
1. **ECRモジュールの実装**: 基本的なECRリポジトリとポリシーの作成
   - `/terraform/modules/ecr/` - 完全なモジュール実装
   - ライフサイクルポリシー、セキュリティ設定、IAMロール含む

2. **main.tfの更新**: ECRモジュールの呼び出し追加
   - webserver、locust用のリポジトリ設定
   - 既存モジュールでのECRイメージ参照への変更

3. **Dockerfileの最適化**: TypeScript統一とマルチステージビルド
   - `/apps/webserver/Dockerfile` - 本番用最適化済み

4. **ビルド・プッシュスクリプト**: 自動化スクリプトの作成
   - `/scripts/build-and-push-images.sh` - 完全自動化

### 🔄 次のステップ
1. **テスト**: 新しい構成での動作確認
2. **ドキュメント更新**: READMEに新しいワークフローを記載
3. **CI/CDパイプライン**: GitHub Actionsワークフローの作成（将来的）

### 📋 使用方法

#### 1. ECRリポジトリの作成とイメージプッシュ
```bash
# スクリプトを使用した自動ビルド・プッシュ
./scripts/build-and-push-images.sh

# または手動でのビルド・プッシュ
# ECRにログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com

# Webサーバーイメージ
cd apps/webserver
docker build -t <ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com/locust-on-aws-test-webserver:latest .
docker push <ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com/locust-on-aws-test-webserver:latest

# Locustイメージ
cd apps/locust
docker build -t <ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com/locust-on-aws-locust-custom:latest .
docker push <ACCOUNT_ID>.dkr.ecr.ap-northeast-1.amazonaws.com/locust-on-aws-locust-custom:latest
```

#### 2. インフラストラクチャのデプロイ
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### 3. 新しいイメージのデプロイ
```bash
# 新しいイメージをビルド・プッシュ
./scripts/build-and-push-images.sh

# ECSサービスの更新（イメージが更新されると自動的に新しいタスクが起動）
aws ecs update-service --cluster <CLUSTER_NAME> --service <SERVICE_NAME> --force-new-deployment
```
