# Cloud SQL (PostgreSQL with pgvector) セットアップガイド

このガイドでは、Google Cloud SQLでPostgreSQLインスタンスを作成し、pgvector拡張機能を設定する方法を説明します。

## 1. Cloud SQLインスタンスの作成

### 1.1 Google Cloud CLIでPostgreSQLインスタンスを作成

```bash
gcloud sql instances create analog-ai-db \
  --database-version=POSTGRES_14 \
  --tier=db-g1-small \
  --region=asia-northeast1 \
  --root-password=YOUR_ROOT_PASSWORD \
  --availability-type=zonal \
  --storage-size=10GB
```

### 1.2 GUIでの作成（代替方法）

1. Google Cloudコンソールで「SQL」に移動
2. 「インスタンスを作成」をクリック
3. PostgreSQLを選択
4. インスタンスIDを入力（例：analog-ai-db）
5. パスワードを設定
6. リージョンを選択（例：asia-northeast1）
7. マシンタイプを選択（例：db-g1-small）
8. 「作成」をクリック

## 2. データベースとユーザーの作成

### 2.1 データベースの作成

```bash
gcloud sql databases create appdb --instance=analog-ai-db
```

### 2.2 ユーザーの作成

```bash
gcloud sql users create appuser \
  --instance=analog-ai-db \
  --password=YOUR_USER_PASSWORD
```

## 3. pgvector拡張機能のインストール

### 3.1 Cloud SQLコンソールからSQLエディタを開く

1. Google Cloudコンソールで「SQL」に移動
2. 作成したインスタンス（analog-ai-db）をクリック
3. 「SQLエディタ」タブを選択

### 3.2 pgvector拡張機能を有効化

以下のSQLコマンドを実行します：

```sql
-- pgvector拡張機能をインストール
CREATE EXTENSION IF NOT EXISTS vector;

-- 拡張機能が正しくインストールされたか確認
SELECT * FROM pg_extension WHERE extname = 'vector';
```

## 4. テーブルの作成とインデックスの設定

以下のSQLコマンドを実行して、ベクトル検索用のテーブルとインデックスを作成します：

```sql
-- ドキュメント用テーブルの作成
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255),
  content TEXT,
  embedding vector(1536),  -- OpenAIのembedding次元数
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE
);

-- タイトルにインデックスを作成
CREATE INDEX idx_documents_title ON documents(title);

-- ベクトル列にIVFLATインデックスを作成
CREATE INDEX idx_documents_embedding ON documents USING ivfflat (embedding vector_l2_ops) WITH (lists = 100);
```

## 5. テストデータの挿入

```sql
-- テストデータを挿入（ランダムなベクトル値）
INSERT INTO documents (title, content, embedding)
VALUES 
  ('テストドキュメント1', 'これはテスト用のコンテンツです。', '[0.1, 0.2, 0.3, ...]'::vector),
  ('テストドキュメント2', 'これは別のテスト用コンテンツです。', '[0.2, 0.3, 0.4, ...]'::vector);
```

## 6. ベクトル検索のテスト

```sql
-- L2距離（ユークリッド距離）による最近傍検索
SELECT id, title, content, embedding <-> '[0.1, 0.2, 0.3, ...]'::vector AS distance
FROM documents
ORDER BY distance
LIMIT 5;

-- 内積による類似度検索
SELECT id, title, content, embedding <#> '[0.1, 0.2, 0.3, ...]'::vector AS similarity
FROM documents
ORDER BY similarity
LIMIT 5;

-- コサイン類似度による検索
SELECT id, title, content, (1 - (embedding <=> '[0.1, 0.2, 0.3, ...]'::vector)) AS cosine_similarity
FROM documents
ORDER BY cosine_similarity DESC
LIMIT 5;
```

## 7. アプリケーションからの接続設定

### 7.1 Cloud SQLへの接続情報

Cloud Run環境からCloud SQLに接続するには、以下の環境変数を設定します：

```
DB_USER=appuser
DB_PASSWORD=YOUR_USER_PASSWORD
DB_NAME=appdb
DB_INSTANCE_CONNECTION_NAME=YOUR_PROJECT_ID:REGION:analog-ai-db
```

### 7.2 Cloud SQLインスタンス接続名の確認方法

```bash
gcloud sql instances describe analog-ai-db --format='value(connectionName)'
```

## 8. メンテナンスとバックアップ

### 8.1 自動バックアップの設定

1. Google Cloudコンソールで「SQL」に移動
2. インスタンスを選択
3. 「バックアップ」タブを選択
4. 「自動バックアップを構成」をクリック
5. バックアップ時間とバックアップ保持期間を設定

### 8.2 手動バックアップの作成

```bash
gcloud sql backups create --instance=analog-ai-db
```

## 9. パフォーマンス最適化のヒント

1. **適切なインデックスを作成する**：頻繁に検索される列にはインデックスを作成します。
2. **定期的なVACUUM**：定期的に`VACUUM ANALYZE`を実行して、データベースのパフォーマンスを維持します。
3. **適切なリストサイズの選択**：`ivfflat`インデックスのリストサイズは、データ量に応じて調整します。
4. **接続プーリング**：アプリケーションでは接続プーリングを使用して、データベース接続のオーバーヘッドを減らします。

## 10. トラブルシューティング

### 10.1 一般的な問題と解決策

- **接続エラー**：Cloud SQLインスタンスへの接続が失敗する場合は、ネットワーク設定とIAM権限を確認します。
- **パフォーマンスの問題**：クエリが遅い場合は、`EXPLAIN ANALYZE`を使用してクエリプランを分析します。
- **メモリエラー**：大きなベクトル操作でメモリエラーが発生する場合は、インスタンスのサイズをアップグレードします。

### 10.2 ログの確認

```bash
gcloud logging read "resource.type=cloudsql_database AND resource.labels.database_id=YOUR_PROJECT_ID:REGION:analog-ai-db" --limit=10
```
