#!/bin/bash
# AI Photo Frame 実行スクリプト
# FastSD CPUで画像生成 → E-paperディスプレイに表示

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="/home/pi/fastsdcpu-project"
DISPLAY_SCRIPT="/home/pi/AIPhotoFrame/ai-photoframe/display_epaper.py"

echo -e "${BLUE}🖼️  AI Photo Frame - Complete Pipeline${NC}"
echo ""

# FastSD CPU環境の確認
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  FastSD CPU環境が見つかりません。${NC}"
    echo "まずFastSD CPUをインストールしてください:"
    echo "curl -fsSL https://raw.githubusercontent.com/donkeykey/AIPhotoFrame/main/ai-photoframe/install_fastsdcpu_rpi.sh | bash"
    exit 1
fi

# 1. FastSD CPUで画像生成
echo -e "${BLUE}🎨 Step 1: FastSD CPUで画像生成中...${NC}"
cd "$PROJECT_DIR/fastsdcpu-stable"
source ../fastsd-simple-env/bin/activate

if python test_fastsd.py; then
    echo -e "${GREEN}✅ 画像生成完了！${NC}"
else
    echo "❌ 画像生成に失敗しました"
    exit 1
fi

# 2. E-paperディスプレイに表示（同じ仮想環境内）
echo ""
echo -e "${BLUE}🖼️  Step 2: E-paperディスプレイに表示中...${NC}"

# 仮想環境は既にアクティベート済み
if python3 "$DISPLAY_SCRIPT"; then
    echo -e "${GREEN}🎉 AI Photo Frame 完了！${NC}"
else
    echo "❌ E-paper表示に失敗しました"
    deactivate
    exit 1
fi

deactivate

echo ""
echo -e "${BLUE}📊 使用方法:${NC}"
echo "  完全実行: ./run_photoframe.sh"
echo "  画像表示のみ: source $PROJECT_DIR/fastsd-simple-env/bin/activate && python3 display_epaper.py"
echo "  カスタム画像: source $PROJECT_DIR/fastsd-simple-env/bin/activate && python3 display_epaper.py /path/to/image.png"
echo "  プレビュー: source $PROJECT_DIR/fastsd-simple-env/bin/activate && python3 display_epaper.py --preview"