# 段階的デプロイガイド

このプロジェクトは、ECRリポジトリの作成とECSサービスのデプロイを段階的に行う構成になっています。

## 理由

元の`main.tf`では、ECRリポジトリの作成と同時にECSサービスも立ち上げようとしますが、この時点ではECRにDockerイメージがまだプッシュされていないため、ECSタスクが失敗してしまいます。

## デプロイ手順

### 第1段階：ECRリポジトリの作成

```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars" -target=module.ecr
terraform apply -var-file="terraform.tfvars" -target=module.ecr
```

または、ECR専用のTerraformファイルを使用：

```bash
terraform plan -var-file="terraform.tfvars" ecr-only.tf
terraform apply -var-file="terraform.tfvars" ecr-only.tf
```

### 第2段階：Dockerイメージのビルドとプッシュ

ECRリポジトリが作成されたら、イメージをビルドしてプッシュします：

```bash
# ECRリポジトリURLを取得
terraform output ecr_repository_webserver_url
terraform output ecr_repository_locust_url

# DockerイメージをビルドしてECRにプッシュ
./scripts/build-and-push-images.sh
```

### 第3段階：ECSクラスターとサービスのデプロイ

イメージがECRにプッシュされたら、ECSサービスをデプロイします：

```bash
# 残りのリソースをデプロイ
terraform plan -var-file="terraform.tfvars" ecs-deployment.tf
terraform apply -var-file="terraform.tfvars" ecs-deployment.tf
```

または、元のmain.tfを使用する場合：

```bash
# ECR以外のリソースをデプロイ
terraform plan -var-file="terraform.tfvars" \
  -target=module.network \
  -target=module.ecs_cluster \
  -target=module.test_webserver \
  -target=module.locust_master \
  -target=module.locust_worker
  
terraform apply -var-file="terraform.tfvars" \
  -target=module.network \
  -target=module.ecs_cluster \
  -target=module.test_webserver \
  -target=module.locust_master \
  -target=module.locust_worker
```

## ファイル構成

- `ecr-only.tf`: ECRリポジトリのみを作成するファイル
- `ecs-deployment.tf`: ECSクラスターとサービスをデプロイするファイル（ECRの既存リポジトリを参照）
- `main.tf`: 従来の一括デプロイ用ファイル（段階的デプロイの場合は使用しない）

## 注意事項

- `ecs-deployment.tf`では`data`リソースを使用してECRリポジトリの情報を取得しているため、ECRリポジトリが事前に作成されている必要があります
- イメージのタグは`latest`を使用していますが、本番環境では具体的なバージョンタグを使用することを推奨します