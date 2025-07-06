# Locust負荷テスト

このディレクトリには、AWS ECS上で実行するLocust負荷テストのコードが含まれています。

## ファイル構成

- `locustfile.py`: 負荷テストのシナリオを定義するPythonスクリプト
- `requirements.txt`: 必要なPythonパッケージのリスト
- `Dockerfile`: カスタムLocustイメージを作成するための定義ファイル

## 負荷テストシナリオ

現在のテストシナリオには以下のユーザー行動が含まれています：

1. 通常リクエスト（頻度：中）- ルートエンドポイント（`/`）へのアクセス
2. 高負荷リクエスト（頻度：低）- 高負荷エンドポイント（`/heavy`）へのアクセス
3. ヘルスチェック（頻度：高）- ヘルスチェックエンドポイント（`/health`）へのアクセス

## Dockerイメージのビルド

```bash
docker build -t custom-locust .
```

## ローカルでの実行方法

### スタンドアロンモード

```bash
docker run -p 8089:8089 custom-locust
```

### 分散モード（マスター）

```bash
docker run -p 8089:8089 -p 5557:5557 -p 5558:5558 custom-locust --master
```

### 分散モード（ワーカー）

```bash
docker run custom-locust --worker --master-host=<マスターのIPアドレス>
```

## AWS ECRへのプッシュ

```bash
# ECRリポジトリの作成（初回のみ）
aws ecr create-repository --repository-name custom-locust

# イメージのタグ付け
docker tag custom-locust:latest <AWSアカウントID>.dkr.ecr.<リージョン>.amazonaws.com/custom-locust:latest

# ECRへのログイン
aws ecr get-login-password | docker login --username AWS --password-stdin <AWSアカウントID>.dkr.ecr.<リージョン>.amazonaws.com

# イメージのプッシュ
docker push <AWSアカウントID>.dkr.ecr.<リージョン>.amazonaws.com/custom-locust:latest
```
