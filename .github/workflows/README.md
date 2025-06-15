# GitHub Actions ワークフロー

このディレクトリには、Locust on AWSプロジェクト用のGitHub Actions CI/CDワークフローが含まれています。

## ワークフロー一覧

### 1. build-images.yml
**メインのビルド・プッシュワークフロー**

- **トリガー**: 
  - `main`ブランチへのプッシュ
  - タグプッシュ（`v*`）
  - プルリクエスト（ビルドテストのみ）
  - 手動実行

- **機能**:
  - アプリケーションコードの変更検出
  - LocustとWebサーバーイメージの並列ビルド
  - ECRへの自動プッシュ
  - イメージタグの自動生成
  - セキュリティスキャン

### 2. pr-build-check.yml
**プルリクエスト用のビルドチェック**

- **トリガー**: プルリクエスト作成・更新

- **機能**:
  - Dockerfileの文法チェック（hadolint）
  - ビルドテスト（プッシュなし）
  - PRサマリーの生成

## セットアップ

詳細なセットアップ手順は [../GITHUB_ACTIONS_SETUP.md](../GITHUB_ACTIONS_SETUP.md) を参照してください。

## 必要なシークレット

GitHub リポジトリの Settings > Secrets and variables > Actions で設定：

| 名前 | 説明 | 例 |
|------|------|-----|
| `AWS_REGION` | AWSリージョン | `ap-northeast-1` |
| `AWS_ACCOUNT_ID` | AWSアカウントID | `123456789012` |

## イメージタグ戦略

### 自動生成タグ

- `latest`: mainブランチの最新コミット
- `commit-{SHA}`: Gitコミットハッシュベース
- `pr-{NUMBER}`: プルリクエスト用（テストのみ、プッシュなし）
- `v{VERSION}`: リリースタグ（手動タグ作成時）

### 使用例

```bash
# mainブランチプッシュ後
123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/locust-fargate-locust-custom:latest
123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/locust-fargate-locust-custom:commit-abc1234

# リリースタグ作成後
123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/locust-fargate-test-webserver:v1.0.0
```

## ワークフロー実行

### 手動実行

1. GitHub リポジトリの Actions タブに移動
2. "Build and Push Docker Images" を選択
3. "Run workflow" をクリック
4. 必要に応じて "Force build all images" をチェック
5. "Run workflow" を実行

### 自動実行

以下の場合に自動実行されます：

```bash
# mainブランチへのプッシュ
git push origin main

# タグプッシュ
git tag v1.0.0
git push origin v1.0.0

# プルリクエスト作成
git checkout -b feature/new-feature
git push origin feature/new-feature
# GitHub でPR作成
```

## モニタリング

### 実行状況の確認

1. GitHub Actions タブで実行状況を確認
2. 失敗したジョブのログを確認
3. ECRコンソールでイメージプッシュを確認

### 通知設定

必要に応じて以下の通知を設定可能：

- Slack通知（成功/失敗）
- Email通知（失敗時）
- GitHub通知（デフォルト有効）

## トラブルシューティング

### よくある問題

1. **権限エラー**
   - OIDC設定の確認
   - IAMロールの信頼ポリシー確認
   - シークレット設定の確認

2. **ビルドエラー**
   - Dockerfileの構文確認
   - 依存関係の問題確認
   - ローカルビルドテスト実行

3. **プッシュエラー**
   - ECRリポジトリの存在確認
   - IAM権限の確認
   - ネットワーク接続の確認

### デバッグ手順

```bash
# ローカルでのテスト
cd apps/locust
docker build -t test-locust .

cd ../webserver  
docker build -t test-webserver .

# ECRリポジトリの確認
aws ecr describe-repositories

# IAMロールの確認
aws iam get-role --role-name locust-fargate-cicd-ecr-role
```

## 関連ドキュメント

- [CI_DESIGN.md](../CI_DESIGN.md): 設計詳細
- [GITHUB_ACTIONS_SETUP.md](../GITHUB_ACTIONS_SETUP.md): セットアップガイド
- [ECR_DESIGN.md](../ECR_DESIGN.md): ECR統合設計
