# アナログ媒体と生成系AIによる対話型案内の提案

## Requirements

- Docker
  - Python 3.12.x
  - Node.js 22.x
  - PostgreSQL 16.x

## 開発環境用のセットアップ
### 1. Docker のインストール
Docker Desktop をインストールしてください。
設定で、使用できるメモリを 4GB 以上にしておくと動作が安定します。

### 2. プロジェクトのクローン
このリポジトリを git clone してください。
その際に .env.sample を .env にコピーしてください。
以下のコマンドで行います。
```bash
git clone git@github.com:ruribou/analog-ai-navigator.git
cd analog-ai-navigator
cp .env.sample .env
```

### 3. コンテナの起動
以下のコマンドでコンテナを起動します。
```bash
make up
```
気になる人は Makefile で定義してあるので見てみてください。