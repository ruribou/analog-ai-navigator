# backend/Dockerfile
# EOL を踏まえて python3.12-slim を使用
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY . .

# ホットリロードができるように --reload を追加
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]