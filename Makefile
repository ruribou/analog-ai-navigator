.PHONY: up stop up-bg logs build clean

# 開発環境の起動（ビルド込み）
up:
	docker compose -f docker-compose.dev.yml up --build

# 開発環境の停止
stop:
	docker compose -f docker-compose.dev.yml down

# バックグラウンドで起動
up-bg:
	docker compose -f docker-compose.dev.yml up -d --build

# ログの確認
logs:
	docker compose -f docker-compose.dev.yml logs -f

# イメージの再ビルド
build:
	docker compose -f docker-compose.dev.yml build

# ボリュームも含めて完全停止・削除
clean:
	docker compose -f docker-compose.dev.yml down -v
