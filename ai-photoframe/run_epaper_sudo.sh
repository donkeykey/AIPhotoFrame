#!/bin/bash
# E-Paper表示（sudo権限で実行）
# GPIO競合問題を回避するためsudo権限でInkyライブラリを実行

set -e

PROJECT_DIR="/home/pi/fastsdcpu-project"
VENV_PATH="$PROJECT_DIR/fastsd-simple-env"
DISPLAY_SCRIPT="/home/pi/AIPhotoFrame/ai-photoframe/display_epaper.py"

# 仮想環境をsudo環境で使用
echo "🔧 sudo権限でE-paperディスプレイを実行中..."
echo "   GPIO8競合問題を回避します"

# 仮想環境のPythonパスを取得
PYTHON_PATH="$VENV_PATH/bin/python3"

if [ ! -f "$PYTHON_PATH" ]; then
    echo "❌ 仮想環境が見つかりません: $VENV_PATH"
    exit 1
fi

# sudo環境で仮想環境のPythonを使用
sudo -E "$PYTHON_PATH" "$DISPLAY_SCRIPT" "$@"