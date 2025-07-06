# テスト対象Webサーバー

このディレクトリには、Locust負荷テストの対象となるサンプルWebサーバーのコードが含まれています。

## 機能

- 通常リクエスト（`/`）: 標準的なレスポンスを返します
- 高負荷リクエスト（`/heavy`）: CPU負荷の高い処理を実行します
- ヘルスチェック（`/health`）: サーバーの状態を返します

## 実行方法

### JavaScriptバージョン

```bash
npm install
npm start
```

### TypeScriptバージョン

```bash
npm install
npm run start:ts
```

## Dockerイメージのビルド

```bash
docker build -t test-webserver .
```

## コンテナの実行

```bash
docker run -p 3000:3000 test-webserver
```
