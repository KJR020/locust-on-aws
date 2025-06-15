# GitHub Actions CI/CD セットアップガイド

このガイドでは、Locust on AWSプロジェクト用のGitHub Actions CI/CDパイプラインをセットアップする手順を説明します。

## 前提条件

- AWS アカウント
- GitHub リポジトリの管理者権限
- Terraform で ECR モジュールがデプロイ済み

## 1. AWS OIDC Identity Provider の設定

### 1.1 GitHub OIDC プロバイダーの作成

```bash
# OIDC プロバイダーを作成
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 1.2 確認

```bash
# 作成されたプロバイダーを確認
aws iam list-open-id-connect-providers
```

## 2. GitHub Repository Secrets の設定

GitHub リポジトリの Settings > Secrets and variables > Actions で以下のシークレットを追加：

### Repository Secrets

| 名前             | 値               | 説明           |
|------------------|------------------|----------------|
| `AWS_REGION`     | `ap-northeast-1` | AWSリージョン       |
| `AWS_ACCOUNT_ID` | `123456789012`   | あなたのAWSアカウントID |

**重要**: `AWS_ACCOUNT_ID` は実際のAWSアカウントIDに置き換えてください。

## 3. IAM ロールの確認

Terraform ECR モジュールによって自動作成されるIAMロールを確認：

```bash
# IAMロールの存在確認
aws iam get-role --role-name locust-fargate-cicd-ecr-role

# ロールのポリシーを確認
aws iam list-attached-role-policies --role-name locust-fargate-cicd-ecr-role
```

## 4. GitHub Actions ワークフローの有効化

### 4.1 ワークフローファイルの確認

以下のファイルがプロジェクトに追加されていることを確認：

```
.github/
└── workflows/
    ├── build-images.yml      # メインのビルド・プッシュワークフロー
    └── pr-build-check.yml    # PR用のビルドチェック
```

### 4.2 アクセス権限の設定

GitHub リポジトリの Settings > Actions > General で以下を設定：

- **Workflow permissions**: "Read and write permissions"
- **Allow GitHub Actions to create and approve pull requests**: チェック

## 5. ワークフローのテスト

### 5.1 初回実行（手動トリガー）

1. GitHub リポジトリの Actions タブに移動
2. "Build and Push Docker Images" ワークフローを選択
3. "Run workflow" をクリック
4. "Force build all images" をチェック
5. "Run workflow" を実行

### 5.2 自動トリガーのテスト

#### アプリケーションコード変更のテスト

```bash
# Locust アプリを変更
echo "# Test change" >> apps/locust/README.md
git add apps/locust/README.md
git commit -m "test: trigger locust build"
git push origin main
```

#### プルリクエストワークフローのテスト

```bash
# 新しいブランチを作成
git checkout -b test-pr-workflow

# Webserver アプリを変更
echo "# Test PR change" >> apps/webserver/README.md
git add apps/webserver/README.md
git commit -m "test: trigger webserver build in PR"
git push origin test-pr-workflow

# GitHub でプルリクエストを作成
```

## 6. 確認手順

### 6.1 ワークフロー実行の確認

1. GitHub Actions タブでワークフローの実行状況を確認
2. ビルドログでエラーがないかチェック
3. ECR コンソールで新しいイメージがプッシュされているか確認

### 6.2 ECR イメージの確認

```bash
# ECR リポジトリのイメージ一覧
aws ecr describe-images --repository-name locust-fargate-locust-custom
aws ecr describe-images --repository-name locust-fargate-test-webserver
```

### 6.3 イメージタグの確認

期待されるタグが作成されているか確認：

- `latest` (main ブランチプッシュ時)
- `commit-{SHA}` (コミットハッシュベース)
- `pr-{NUMBER}` (プルリクエスト時、プッシュなし)
- `v{VERSION}` (タグプッシュ時)

## 7. トラブルシューティング

### 7.1 権限エラー

**症状**: `AssumeRoleFailure` エラー

**対処法**:
1. OIDC プロバイダーが正しく設定されているか確認
2. IAM ロールの信頼ポリシーを確認
3. GitHub Repository Secrets が正しく設定されているか確認

```bash
# IAM ロールの信頼ポリシーを確認
aws iam get-role --role-name locust-fargate-cicd-ecr-role --query 'Role.AssumeRolePolicyDocument'
```

### 7.2 ECR プッシュエラー

**症状**: ECR へのプッシュが失敗

**対処法**:
1. ECR リポジトリが存在するか確認
2. IAM ロールに適切な ECR 権限があるか確認

```bash
# ECR リポジトリの存在確認
aws ecr describe-repositories --repository-names locust-fargate-locust-custom locust-fargate-test-webserver
```

### 7.3 ビルドエラー

**症状**: Docker ビルドが失敗

**対処法**:
1. Dockerfile の構文エラーをチェック
2. 依存関係の問題がないか確認
3. ローカルでビルドテストを実行

```bash
# ローカルビルドテスト
cd apps/locust
docker build -t test-locust .

cd ../webserver
docker build -t test-webserver .
```

## 8. 運用ガイド

### 8.1 定期メンテナンス

- 月次でベースイメージの更新確認
- ECR イメージスキャン結果の確認
- GitHub Actions の使用量監視

### 8.2 セキュリティチェック

- IAM ロール権限の定期見直し
- シークレットローテーション計画
- 脆弱性スキャン結果の確認

### 8.3 コスト最適化

- ECR ライフサイクルポリシーの確認
- GitHub Actions 使用量の監視
- 不要なイメージの削除

## 9. 次のステップ

セットアップ完了後、以下の拡張を検討：

1. **自動 ECS デプロイメント**: 成功したビルド後の自動デプロイ
2. **通知設定**: Slack や email での成功/失敗通知
3. **モニタリング**: CloudWatch での詳細監視
4. **カナリアデプロイメント**: 段階的なデプロイメント戦略

## サポート

問題が発生した場合は、以下を確認：

1. GitHub Actions の実行ログ
2. AWS CloudTrail ログ
3. ECR リポジトリの設定
4. IAM ロールとポリシーの設定

詳細なトラブルシューティングについては、プロジェクトの Issue を作成してください。
