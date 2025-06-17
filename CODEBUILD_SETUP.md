# AWS CodeBuildによるCI/CD設定ガイド

このドキュメントでは、AWS CodeBuildを使用してLocustおよびWebserverイメージのビルドとデプロイを自動化する方法について説明します。

## 目次

1. [概要](#概要)
2. [前提条件](#前提条件)
3. [CodeBuildプロジェクトの設定](#CodeBuildプロジェクトの設定)
4. [IAMロールの設定](#IAMロールの設定)
5. [ビルドトリガーの設定](#ビルドトリガーの設定)
6. [高度な設定](#高度な設定)

## 概要

AWS CodeBuildを使用すると、以下の利点があります：

- **アーキテクチャの一貫性**: AWS環境内でビルドするため、ローカル環境の違いによる問題を解消
- **AWS統合**: ECR、ECS、その他のAWSサービスとシームレスに連携
- **セキュリティ**: AWSのIAMロールを使用した安全な認証情報管理
- **マルチアーキテクチャビルド**: Docker BuildXによる複数アーキテクチャ対応イメージの構築

## 前提条件

- AWSアカウント
- GitHubリポジトリ（またはAWS CodeCommit）にプロジェクトがプッシュされていること
- 適切な権限を持つIAMユーザー/ロール

## CodeBuildプロジェクトの設定

### 1. CodeBuildプロジェクトの作成

1. AWSマネジメントコンソールにログインし、CodeBuildサービスに移動します
2. 「ビルドプロジェクトを作成する」をクリックします
3. 以下の情報を入力します：
   - **プロジェクト名**: `locust-on-aws-build`
   - **説明**: `Locust負荷テスト環境のDockerイメージビルド`

### 2. ソース設定

1. **ソースプロバイダー**: GitHub（または使用しているリポジトリサービス）
2. **リポジトリ**: リポジトリのURLを入力
3. **ソースバージョン**: `main`（または使用するブランチ）
4. **Webhook**: 有効化して自動ビルドを設定（オプション）

### 3. 環境設定

1. **環境イメージ**: マネージド型イメージ
2. **オペレーティングシステム**: Amazon Linux 2
3. **ランタイム**: Standard
4. **イメージ**: `aws/codebuild/amazonlinux2-x86_64-standard:4.0`
5. **特権モード**: 有効（Dockerビルドに必要）
6. **サービスロール**: 新しいサービスロールを作成（または既存のロールを使用）

### 4. Buildspec設定

1. **ビルド仕様**: `buildspec.yml`を使用
2. プロジェクトのルートディレクトリに`buildspec.yml`ファイルが存在することを確認

## IAMロールの設定

CodeBuildサービスロールには以下の権限が必要です：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices"
      ],
      "Resource": "arn:aws:ecs:*:*:service/locust-fargate-cluster/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

## ビルドトリガーの設定

### GitHub Webhookの設定

1. CodeBuildプロジェクトの編集画面で「ソース」セクションに移動
2. 「Webhook」を有効化
3. 以下のイベントを選択：
   - PUSH: コードがプッシュされたときにビルド
   - PULL_REQUEST_CREATED: PRが作成されたときにビルド
   - PULL_REQUEST_UPDATED: PRが更新されたときにビルド

### フィルターグループの設定（オプション）

特定のファイルが変更された場合のみビルドをトリガーするフィルターを設定できます：

1. 「Webhook」セクションで「フィルターグループを追加」をクリック
2. 以下のフィルターを追加：
   - イベントタイプ: PUSH
   - ヘッドリファレンス: ^refs/heads/main$
   - ファイルパス: ^apps/.*$

## 高度な設定

### 1. VPC内でのビルド実行

セキュリティを強化するために、VPC内でCodeBuildを実行できます：

1. CodeBuildプロジェクトの「編集」→「環境」セクション
2. 「追加設定」を展開
3. 「VPC」を選択し、適切なVPC、サブネット、セキュリティグループを設定

### 2. キャッシュ設定

ビルド時間を短縮するためにキャッシュを設定：

1. CodeBuildプロジェクトの「編集」→「アーティファクト」セクション
2. 「キャッシュタイプ」で「Amazon S3」または「ローカル」を選択
3. キャッシュの場所とモードを設定

### 3. 環境変数の設定

ビルドプロセスで使用する環境変数を設定：

1. CodeBuildプロジェクトの「編集」→「環境」セクション
2. 「追加設定」→「環境変数」で必要な変数を追加：
   - `AWS_REGION`: ビルドを実行するリージョン
   - `FORCE_BUILD`: 強制ビルドフラグ（必要に応じて）

## トラブルシューティング

### ビルドエラー

1. **Docker関連のエラー**:
   - 特権モードが有効になっていることを確認
   - Dockerバージョンの互換性を確認

2. **ECRプッシュエラー**:
   - IAMロールに適切な権限があることを確認
   - ECRリポジトリが存在することを確認

3. **BuildXエラー**:
   - BuildXのインストールコマンドが正しいことを確認
   - 最新バージョンを使用しているか確認

### ログの確認

ビルドログはCodeBuildプロジェクトの「ビルド履歴」から確認できます。詳細なログはCloudWatchにも保存されます。
