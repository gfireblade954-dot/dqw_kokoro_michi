#!/bin/bash
set -e

# Flutter web ビルド（GitHub Pages 用の base-href を指定、キャッシュ更新用にタイムスタンプを付与）
flutter build web --release --base-href /dqw_kokoro_michi/ --dart-define=SERVICE_WORKER_VERSION=$(date +%Y%m%d%H%M%S)

# build/web の中身を docs フォルダにコピー
rm -rf docs
cp -r build/web docs

# Git コミットと push
git add .
git commit -m "deploy"
git push
