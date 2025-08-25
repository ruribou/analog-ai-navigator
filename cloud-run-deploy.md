# Cloud Runへのデプロイ手順

このドキュメントでは、アプリケーションをGoogle Cloud RunとCloud SQL (PostgreSQL with pgvector)を使用してデプロイする方法を説明します。

## 前提条件

- Google Cloudアカウントとプロジェクト
- gcloudコマンドラインツールのインストールと設定
- Dockerのインストール

## 1. Cloud SQLインスタンスの作成

### 1.1 PostgreSQLインスタンスを作成

```bash
gcloud sql instances create analog-ai-db \
  --database-version=POSTGRES_14 \
  --tier=db-g1-small \
  --region=asia-northeast1 \
  --root-password=YOUR_ROOT_PASSWORD \
  --availability-type=zonal \
  --storage-size=10GB
```

### 1.2 データベースとユーザーを作成

```bash
gcloud sql databases create appdb --instance=analog-ai-db

gcloud sql users create appuser \
  --instance=analog-ai-db \
  --password=YOUR_USER_PASSWORD
```

### 1.3 pgvector拡張機能の有効化

Cloud SQLコンソールからSQLエディタを開き、以下のSQLを実行します：

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

## 2. サービスアカウントの設定

### 2.1 サービスアカウントを作成

```bash
gcloud iam service-accounts create analog-ai-service \
  --display-name="Analog AI Service Account"
```

### 2.2 必要な権限を付与

```bash
# Cloud SQLクライアント権限
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:analog-ai-service@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

## 3. コンテナイメージのビルドとプッシュ

### 3.1 Artifact Registryリポジトリを作成

```bash
gcloud artifacts repositories create analog-ai-repo \
  --repository-format=docker \
  --location=asia-northeast1 \
  --description="Analog AI Navigator Repository"
```

### 3.2 Dockerビルドと認証

```bash
# Artifact Registryへの認証
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# イメージをビルド
docker build -t asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/analog-ai-repo/analog-ai-app:v1 .

# イメージをプッシュ
docker push asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/analog-ai-repo/analog-ai-app:v1
```

## 4. Cloud Runサービスのデプロイ

```bash
gcloud run deploy analog-ai-service \
  --image=asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/analog-ai-repo/analog-ai-app:v1 \
  --region=asia-northeast1 \
  --platform=managed \
  --allow-unauthenticated \
  --service-account=analog-ai-service@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --add-cloudsql-instances=YOUR_PROJECT_ID:asia-northeast1:analog-ai-db \
  --set-env-vars="DB_USER=appuser,DB_PASSWORD=YOUR_USER_PASSWORD,DB_NAME=appdb,DB_INSTANCE_CONNECTION_NAME=YOUR_PROJECT_ID:asia-northeast1:analog-ai-db"
```

## 5. カスタムドメインの設定（オプション）

Cloud Runコンソールから、デプロイしたサービスを選択し、「ドメインのマッピング」でカスタムドメインを設定できます。

## 6. デプロイの確認

デプロイが完了したら、提供されたURLにアクセスしてアプリケーションが正常に動作していることを確認します。

```bash
# ヘルスチェックエンドポイントにアクセス
curl https://YOUR_SERVICE_URL/api/health
```

## トラブルシューティング

### ログの確認

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=analog-ai-service" --limit=10
```

### サービスの再デプロイ

コードを更新した場合は、新しいバージョンのイメージをビルドしてプッシュし、再デプロイします。

```bash
docker build -t asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/analog-ai-repo/analog-ai-app:v2 .
docker push asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/analog-ai-repo/analog-ai-app:v2

gcloud run deploy analog-ai-service \
  --image=asia-northeast1-docker.pkg.dev/YOUR_PROJECT_ID/analog-ai-repo/analog-ai-app:v2 \
  --region=asia-northeast1
```
