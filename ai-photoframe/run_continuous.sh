#!/bin/bash
# AI Photo Frame 永続実行スクリプト
# systemdサービス用

PROJECT_DIR="$HOME/fastsdcpu-project"
PHOTOFRAME_DIR="$HOME/AIPhotoFrame/ai-photoframe"

# ログ記録関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# エラーチェック
if [ ! -d "$PROJECT_DIR/fastsd-simple-env" ]; then
    log "❌ FastSD CPU仮想環境が見つかりません: $PROJECT_DIR/fastsd-simple-env"
    exit 1
fi

if [ ! -f "$PHOTOFRAME_DIR/ai_photoframe.py" ]; then
    log "❌ ai_photoframe.pyが見つかりません: $PHOTOFRAME_DIR/ai_photoframe.py"
    exit 1
fi

if [ ! -f "$PHOTOFRAME_DIR/config.json" ]; then
    log "❌ 設定ファイルが見つかりません: $PHOTOFRAME_DIR/config.json"
    exit 1
fi

log "🚀 AI Photo Frame永続実行開始"
log "プロジェクトディレクトリ: $PROJECT_DIR"
log "フォトフレームディレクトリ: $PHOTOFRAME_DIR"

# カレントディレクトリをai-photoframeに変更
cd "$PHOTOFRAME_DIR"

# 仮想環境をアクティベート
log "仮想環境をアクティベート中..."
source "$PROJECT_DIR/fastsd-simple-env/bin/activate"

# Python環境の確認
log "Python環境: $(which python)"
log "Python版本: $(python --version)"

# 必要なパッケージの確認
python -c "import torch, diffusers, inky; print('必要なパッケージは利用可能です')" || {
    log "❌ 必要なパッケージが見つかりません"
    exit 1
}

# 永続実行モードを開始
log "永続実行モードを開始します..."
exec python ai_photoframe.py continuous