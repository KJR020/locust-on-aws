# ECRリポジトリとCodeBuildのみを残す手順

このガイドでは、ECRリポジトリとCodeBuildプロジェクトのみを残して、他のAWSリソース（ECS、ALB、VPCなど）を削除する方法を説明します。

## 手順

### 1. 既存のリソースを削除

まず、ECRリポジトリ以外のすべてのリソースを削除します。

```bash
# 現在のディレクトリに移動
cd /Users/kjr020/work/github.com/KJR020/locust-on-aws/terraform

# 既存のTerraformステートをバックアップ
cp terraform.tfstate terraform.tfstate.backup

# 既存のリソースを削除（ECRリポジトリを除く）
terraform destroy -target=module.locust_worker -target=module.locust_master -target=module.test_webserver -target=module.ecs_cluster -target=module.network
```

### 2. ECRリポジトリのみの設定に切り替え

ECRリポジトリのみを管理する新しいTerraform設定ファイルを使用します。

```bash
# main.tfを一時的に退避
mv main.tf main.tf.original

# ECRリポジトリのみの設定を適用
terraform apply -auto-approve
```

### 3. CodeBuildプロジェクトの設定を確認

CodeBuildプロジェクトは、AWSマネジメントコンソールから手動で作成されている場合、Terraformの管理外である可能性があります。その場合は、以下の点を確認してください：

1. CodeBuildプロジェクトがECRリポジトリにアクセスできるIAM権限を持っていること
2. buildspec.ymlファイルが正しく設定されていること
3. CodeBuildプロジェクトの「特権モード」が有効になっていること

### 4. 注意事項

- この操作により、ECSクラスター、タスク定義、サービス、ALB、VPCなどのリソースはすべて削除されます
- ECRリポジトリ内のイメージは保持されます
- CodeBuildプロジェクトは手動で作成した場合、この操作の影響を受けません
- 将来的に完全な環境を再構築する場合は、`main.tf.original`を`main.tf`に戻して`terraform apply`を実行してください

### 5. 確認

ECRリポジトリが残っていることを確認します：

```bash
aws ecr describe-repositories --query 'repositories[*].repositoryName'
```

CodeBuildプロジェクトが残っていることを確認します：

```bash
aws codebuild list-projects
```
