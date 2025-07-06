# Locust on AWS - Terraformプロジェクト構造

## プロジェクト概要

このTerraformプロジェクトは、AWS ECS Fargate上にLocustクラスターを構築するためのものです。Locustは負荷テストツールであり、このプロジェクトではマスター・ワーカーアーキテクチャを使用して分散負荷テストを実行できるように設計されています。

## プロジェクト構造

```
terraform/
├── main.tf           # メインの設定ファイル
├── variables.tf      # 変数定義ファイル
├── outputs.tf        # 出力定義ファイル
└── modules/          # モジュールディレクトリ
    ├── network/      # ネットワークリソース用モジュール
    ├── ecs_cluster/  # ECSクラスター用モジュール
    ├── locust_master/ # Locustマスターノード用モジュール
    └── locust_worker/ # Locustワーカーノード用モジュール
```

## `main.tf`と`modules`の関係

### `main.tf`の役割

`main.tf`はプロジェクトのエントリーポイントとして機能し、以下の役割を持ちます：

1. **AWSプロバイダーの設定**：使用するAWSリージョンを定義します
2. **モジュールの呼び出し**：必要なインフラストラクチャを構築するための各モジュールを呼び出します
3. **変数の受け渡し**：ルートモジュールの変数をサブモジュールに渡します
4. **モジュール間の依存関係の管理**：モジュール間で必要な出力値を参照します

### `modules`ディレクトリの役割

`modules`ディレクトリには、インフラストラクチャの各部分を担当する再利用可能なコンポーネントが含まれています：

1. **network**：VPC、サブネット、ルートテーブル、インターネットゲートウェイ、NATゲートウェイなどのネットワークリソースを作成します
2. **ecs_cluster**：Locustを実行するためのECSクラスターを作成します
3. **locust_master**：Locustマスターノードを実行するためのECSサービス、タスク定義、ALB、セキュリティグループなどを作成します
4. **locust_worker**：Locustワーカーノードを実行するためのECSサービスとタスク定義を作成します

## モジュール間の依存関係

```
main.tf
  │
  ├── module "network"
  │     └── outputs: vpc_id, public_subnet_ids, private_subnet_ids
  │
  ├── module "ecs_cluster"
  │     └── outputs: cluster_id
  │
  ├── module "locust_master"
  │     ├── inputs: vpc_id, public_subnet_ids, ecs_cluster_id
  │     └── outputs: master_host
  │
  └── module "locust_worker"
        └── inputs: vpc_id, private_subnet_ids, ecs_cluster_id, master_host
```

## 変数の流れ

1. ルートモジュール（`main.tf`）は`variables.tf`から変数を取得します
2. これらの変数は必要に応じて各サブモジュールに渡されます
3. 各モジュールは自身の`variables.tf`で変数を定義し、親モジュールから値を受け取ります
4. モジュールは`outputs.tf`を通じて他のモジュールが使用する値を出力します

## モジュールの詳細

### networkモジュール

- VPC、パブリック/プライベートサブネット、インターネットゲートウェイ、NATゲートウェイなどを作成
- 複数のアベイラビリティゾーンにリソースを分散
- パブリックサブネットはインターネットゲートウェイを経由して外部と通信
- プライベートサブネットはNATゲートウェイを経由して外部と通信

### ecs_clusterモジュール

- Locustを実行するためのECSクラスターを作成
- Fargateとして実行するための設定
- コンテナインサイトを有効化

### locust_masterモジュール

- Locustマスターノード用のセキュリティグループを作成
- ECSタスク実行ロールとポリシーを設定
- マスターノード用のECSタスク定義を作成
- CloudWatchロググループを設定
- ALB、ターゲットグループ、リスナーを作成
- マスターノード用のECSサービスを設定

### locust_workerモジュール

- Locustワーカーノード用のセキュリティグループを作成
- ワーカーノード用のECSタスク定義を作成
- CloudWatchロググループを設定
- ワーカーノード用のECSサービスを設定
- マスターノードと通信するための設定

## デプロイフロー

1. `terraform init`でプロジェクトを初期化
2. `terraform plan`で変更内容を確認
3. `terraform apply`でインフラストラクチャをデプロイ

デプロイ後、ALBのDNS名を使用してLocustのWebインターフェースにアクセスし、負荷テストを実行できます。
