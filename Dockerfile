# ビルドステージ: フロントエンド
FROM node:22-alpine AS frontend-build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ビルドステージ: バックエンド
FROM python:3.11-slim AS backend-build
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./

# 最終ステージ: Nginx + フロントエンド + バックエンド
FROM nginx:alpine
WORKDIR /app

# Nginxの設定
COPY nginx.conf /etc/nginx/conf.d/default.conf

# フロントエンドのビルド結果をコピー
COPY --from=frontend-build /app/.next /app/frontend/.next
COPY --from=frontend-build /app/public /app/frontend/public
COPY --from=frontend-build /app/node_modules /app/frontend/node_modules
COPY --from=frontend-build /app/package.json /app/frontend/package.json

# バックエンドのファイルをコピー
COPY --from=backend-build /app /app/backend
COPY --from=backend-build /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=backend-build /usr/local/bin/uvicorn /usr/local/bin/uvicorn

# スタートアップスクリプト
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8080
CMD ["/app/start.sh"]
