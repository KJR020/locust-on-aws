# Locust on AWS - アーキテクチャ概要

このドキュメントでは、Locust on AWSプロジェクトのTerraformスクリプトが構築するインフラストラクチャの概要を説明します。

## 全体アーキテクチャ

このプロジェクトは、AWS ECS Fargate上にLocust負荷テスト環境と、テスト対象となるオートスケーリング可能なWebサーバーを構築します。主要なコンポーネントは以下の通りです：

1. **ネットワーク基盤**：VPC、サブネット、ルートテーブル、インターネットゲートウェイ、NATゲートウェイ
2. **コンテナレジストリ**：Amazon ECRを使用したプライベートDockerイメージレジストリ
3. **ECSクラスター**：Locustマスター、ワーカー、テスト対象Webサーバーを実行するためのクラスター
4. **Locustマスター**：WebUIを提供し、ワーカーを制御するLocustマスターノード
5. **Locustワーカー**：実際に負荷テストを実行するワーカーノード
6. **テスト対象Webサーバー**：オートスケーリングのテスト対象となるWebアプリケーション

## モジュール構成

Terraformコードは以下のモジュールで構成されています：

### 1. ネットワークモジュール (`./modules/network`)

- **目的**: VPC、サブネット、ルートテーブル、インターネットゲートウェイ、NATゲートウェイを作成
- **主要リソース**:
  - VPC (`aws_vpc.main`)
  - インターネットゲートウェイ (`aws_internet_gateway.main`)
  - パブリックサブネット (`aws_subnet.public`)
  - プライベートサブネット (`aws_subnet.private`)
  - NATゲートウェイ (`aws_nat_gateway.main`)
  - ルートテーブル (`aws_route_table.public`, `aws_route_table.private`)

### 2. ECRモジュール (`./modules/ecr`)

- **目的**: プライベートコンテナレジストリとして、アプリケーションのDockerイメージを管理
- **主要リソース**:
  - ECRリポジトリ (`aws_ecr_repository.repositories`)
  - ライフサイクルポリシー (`aws_ecr_lifecycle_policy.repositories`)
  - リポジトリポリシー (`aws_ecr_repository_policy.repositories`)
  - IAMロール (`aws_iam_role.ecr_access_role`)

### 3. ECSクラスターモジュール (`./modules/ecs_cluster`)

- **目的**: Locustマスター、ワーカー、テスト対象Webサーバーを実行するためのECSクラスターを作成
- **主要リソース**:
  - ECSクラスター (`aws_ecs_cluster.main`)

### 3. テスト対象Webサーバーモジュール (`./modules/test_webserver`)

- **目的**: オートスケーリング可能なテスト対象Webサーバーを構築
- **主要リソース**:
  - セキュリティグループ (`aws_security_group.alb`, `aws_security_group.ecs_tasks`)
  - アプリケーションロードバランサー (`aws_lb.main`)
  - ターゲットグループ (`aws_lb_target_group.app`)
  - ECSタスク定義 (`aws_ecs_task_definition.app`)
  - ECSサービス (`aws_ecs_service.main`)
  - オートスケーリング設定 (`aws_appautoscaling_target.ecs_target`, `aws_appautoscaling_policy.cpu`, `aws_appautoscaling_policy.requests`)
  - IAMロール (`aws_iam_role.ecs_task_execution_role`, `aws_iam_role.ecs_task_role`)

### 4. Locustマスターモジュール (`./modules/locust_master`)

- **目的**: Locustマスターノードを実行するためのECSサービスとタスク定義を作成
- **主要リソース**:
  - セキュリティグループ (`aws_security_group.master`)
  - ECSタスク定義 (`aws_ecs_task_definition.master`)
  - ECSサービス (`aws_ecs_service.master`)
  - アプリケーションロードバランサー (`aws_lb.master`)
  - ターゲットグループ (`aws_lb_target_group.master`)
  - IAMロール (`aws_iam_role.ecs_task_execution_role`)

### 5. Locustワーカーモジュール (`./modules/locust_worker`)

- **目的**: Locustワーカーノードを実行するためのECSサービスとタスク定義を作成
- **主要リソース**:
  - セキュリティグループ (`aws_security_group.worker`)
  - ECSタスク定義 (`aws_ecs_task_definition.worker`)
  - ECSサービス (`aws_ecs_service.worker`)
  - IAMロール (`aws_iam_role.ecs_task_execution_role`)

## アプリケーション構成

### テスト対象Webサーバー (`/apps/webserver/`)

- **言語**: TypeScript/JavaScript
- **フレームワーク**: Express
- **ファイル構成**:
  - `server.ts`: TypeScript版のWebサーバー実装
  - `server.js`: JavaScript版のWebサーバー実装
  - `Dockerfile`: コンテナイメージ作成用
  - `package.json`: 依存関係とスクリプト定義
- **機能**:
  - ルートエンドポイント (`/`): ランダムな遅延を発生させる通常のエンドポイント
  - 高負荷エンドポイント (`/heavy`): より長い遅延とCPU負荷を発生させるエンドポイント
  - ヘルスチェックエンドポイント (`/health`): サーバーの状態を確認するエンドポイント

### Locustテストスクリプト (`/apps/locust/`)

- **言語**: Python
- **ファイル構成**:
  - `locustfile.py`: 負荷テストシナリオ定義
  - `requirements.txt`: Python依存関係
  - `Dockerfile`: カスタムLocustイメージ作成用
- **機能**:
  - 通常リクエスト: ルートエンドポイントへのリクエスト（頻度：中）
  - 高負荷リクエスト: 高負荷エンドポイントへのリクエスト（頻度：低）
  - ヘルスチェック: ヘルスチェックエンドポイントへのリクエスト（頻度：高）

## オートスケーリング設定

テスト対象Webサーバーは以下の条件でオートスケーリングするように設定されています：

1. **CPU使用率ベース**: 設定されたCPU使用率のしきい値（デフォルト: 60%）を超えると、サービスは自動的にスケールアウトします
2. **リクエスト数ベース**: ターゲットあたりのリクエスト数が設定されたしきい値（デフォルト: 1000リクエスト）を超えると、サービスは自動的にスケールアウトします

スケールイン（縮小）は、これらのメトリクスが設定されたしきい値を下回った場合に発生します。スケールインのクールダウン期間は300秒、スケールアウトのクールダウン期間は60秒に設定されています。

## デプロイフロー

1. Terraformを使用してインフラストラクチャをプロビジョニング
2. テスト対象WebサーバーがECS Fargateにデプロイされ、ALBを通じてアクセス可能になる
3. Locustマスターノードがデプロイされ、WebUIがALBを通じてアクセス可能になる
4. Locustワーカーノードがプライベートサブネットにデプロイされ、マスターノードと通信
5. Locust WebUIを使用して負荷テストを開始し、テスト対象Webサーバーのオートスケーリング動作を観察

## ネットワーク構成

- **VPC**: 10.0.0.0/16（デフォルト）
- **パブリックサブネット**: 10.0.0.0/24, 10.0.1.0/24, ...（AZ数に応じて）
- **プライベートサブネット**: 10.0.100.0/24, 10.0.101.0/24, ...（AZ数に応じて）
- **インターネットゲートウェイ**: パブリックサブネットからインターネットへのアクセスを提供
- **NATゲートウェイ**: プライベートサブネットからインターネットへのアクセスを提供（アウトバウンドのみ）

## セキュリティ設定

- **Locustマスター**: 
  - インバウンド: 8089/TCP（WebUI）、5557-5558/TCP（ワーカー通信）
  - アウトバウンド: すべて許可
- **Locustワーカー**:
  - インバウンド: なし
  - アウトバウンド: すべて許可
- **テスト対象WebサーバーALB**:
  - インバウンド: 80/TCP（HTTP）
  - アウトバウンド: すべて許可
- **テスト対象WebサーバーECSタスク**:
  - インバウンド: コンテナポート/TCP（ALBからのみ）
  - アウトバウンド: すべて許可

## 変数設定

主要な変数は以下の通りです：

- **general_name**: リソースの名前に使用される一般的な接頭辞
- **aws_region**: AWSリージョン（デフォルト: ap-northeast-1）
- **vpc_cidr**: VPCのCIDRブロック（デフォルト: 10.0.0.0/16）
- **az_count**: 使用するアベイラビリティゾーンの数
- **fargate_cpu**: Fargateタスクに割り当てるCPUユニット
- **fargate_memory**: Fargateタスクに割り当てるメモリ（MB）
- **worker_count**: 起動するLocustワーカーの数
- **test_app_image**: テスト対象WebサーバーのDockerイメージ
- **test_container_port**: テスト対象Webサーバーのコンテナポート
- **test_min_capacity**: テスト対象Webサーバーの最小タスク数
- **test_max_capacity**: テスト対象Webサーバーの最大タスク数
- **test_cpu_target_value**: CPU使用率のオートスケーリングターゲット値
- **test_request_target_value**: リクエスト数のオートスケーリングターゲット値
