#!/bin/bash
# AI Photo Frame 実行スクリプト
# 仮想環境をアクティベートしてからAI Photo Frameを実行

PROJECT_DIR="$HOME/fastsdcpu-project"
PHOTOFRAME_DIR="$HOME/AIPhotoFrame/ai-photoframe"

# エラーチェック
if [ ! -d "$PROJECT_DIR/fastsd-simple-env" ]; then
    echo "❌ FastSD CPU仮想環境が見つかりません。install_fastsdcpu_rpi.shを先に実行してください。"
    exit 1
fi

if [ ! -f "$PHOTOFRAME_DIR/ai_photoframe.py" ]; then
    echo "❌ ai_photoframe.pyが見つかりません。"
    exit 1
fi

echo "AI Photo Frame を起動中..."
echo "仮想環境をアクティベート中..."

# 仮想環境をアクティベート
source "$PROJECT_DIR/fastsd-simple-env/bin/activate"

# カレントディレクトリをai-photoframeに変更
cd "$PHOTOFRAME_DIR"

# 引数があればそのまま渡す、なければヘルプを表示
if [ $# -eq 0 ]; then
    echo "使用方法:"
    echo "  $0 generate \"プロンプト\"      # 画像生成して表示"
    echo "  $0 generate-only \"プロンプト\" # 画像生成のみ"
    echo "  $0 display image_path       # 既存画像を表示"
    echo "  $0 list                     # 生成画像一覧"
    echo "  $0 continuous               # 永続実行モード"
    echo ""
    echo "例:"
    echo "  $0 generate \"beautiful mountain landscape\""
    echo "  $0 generate-only \"sunset over ocean\""
    echo "  $0 display /path/to/image.jpg"
    echo "  $0 list"
    echo "  $0 continuous"
    echo ""
    echo "💡 ヒント:"
    echo "  - 画像は自動的に 640x400 サイズで生成されます"
    echo "  - 生成された画像は最新10枚のみ保持されます"
    echo "  - ファイル名には生成日時が含まれます (ai_photo_YYYYMMDD_HHMMSS.png)"
    echo "  - 永続実行モードは config.json で設定できます"
else
    python ai_photoframe.py "$@"
fi