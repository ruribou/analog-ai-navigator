#!/bin/sh

# バックエンドを起動（バックグラウンドで）
cd /app/backend
uvicorn main:app --host 0.0.0.0 --port 8000 &

# フロントエンドを起動（バックグラウンドで）
cd /app/frontend
node_modules/.bin/next start -p 3000 &

# Nginxをフォアグラウンドで起動
nginx -g "daemon off;"
