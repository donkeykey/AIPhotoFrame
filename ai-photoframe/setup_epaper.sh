#!/bin/bash
# E-paper ディスプレイセットアップスクリプト
# Inky Impression用ライブラリとフォントを既存のFastSD CPU環境にインストール

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# FastSD CPU環境のパス
PROJECT_DIR="/home/pi/fastsdcpu-project"
VENV_PATH="$PROJECT_DIR/fastsd-simple-env"

echo -e "${BLUE}🖼️  E-paper Display Setup for AI Photo Frame${NC}"
echo -e "${BLUE}📦 既存のFastSD CPU仮想環境を使用: $VENV_PATH${NC}"
echo ""

# FastSD CPU環境の確認
if [ ! -d "$VENV_PATH" ]; then
    echo -e "${RED}❌ FastSD CPU環境が見つかりません: $VENV_PATH${NC}"
    echo "まずFastSD CPUをインストールしてください:"
    echo "curl -fsSL https://raw.githubusercontent.com/donkeykey/AIPhotoFrame/main/ai-photoframe/install_fastsdcpu_rpi.sh | bash"
    exit 1
fi

echo -e "${GREEN}✅ FastSD CPU環境を確認: $VENV_PATH${NC}"

# SPI有効化の確認と設定
echo -e "${BLUE}📡 SPI設定の確認と設定...${NC}"

# /boot/firmware/config.txtでdtoverlay=spi0-0csの確認・追加
CONFIG_FILE="/boot/firmware/config.txt"
if ! grep -q "dtoverlay=spi0-0cs" "$CONFIG_FILE"; then
    echo -e "${YELLOW}⚠️  dtoverlay=spi0-0csを$CONFIG_FILEに追加します...${NC}"
    echo "dtoverlay=spi0-0cs" | sudo tee -a "$CONFIG_FILE" > /dev/null
    echo -e "${GREEN}✅ dtoverlay=spi0-0csを追加しました${NC}"
    REBOOT_REQUIRED=true
else
    echo -e "${GREEN}✅ dtoverlay=spi0-0cs設定済み${NC}"
fi

# SPIの有効化確認
if ! lsmod | grep -q spi_bcm2835; then
    echo -e "${YELLOW}⚠️  SPIが無効です。raspi-configで有効にしてください:${NC}"
    echo "sudo raspi-config → Interface Options → SPI → Enable"
    echo ""
    if [ "$REBOOT_REQUIRED" = true ]; then
        echo "設定変更後、再起動が必要です: sudo reboot"
    else
        echo "有効化後、再起動が必要です: sudo reboot"
    fi
    exit 1
else
    echo -e "${GREEN}✅ SPI有効${NC}"
fi

# システムパッケージのインストール
echo -e "${BLUE}📦 システムパッケージのインストール...${NC}"
sudo apt update
sudo apt install -y python3-pip python3-pil python3-numpy

# Inkyライブラリのインストール（仮想環境内）
echo -e "${BLUE}🎨 Inky Impressionライブラリのインストール（仮想環境内）...${NC}"
source "$VENV_PATH/bin/activate"
pip install inky[rpi,example-depends]
echo -e "${GREEN}✅ 仮想環境内にInkyライブラリをインストール完了${NC}"

# フォントディレクトリとフォントのセットアップ
echo -e "${BLUE}🔤 日本語フォントのセットアップ...${NC}"
FONT_DIR="/home/pi/font"
FONT_FILE="$FONT_DIR/MPLUSRounded1c-Bold.ttf"

if [ ! -d "$FONT_DIR" ]; then
    mkdir -p "$FONT_DIR"
fi

if [ ! -f "$FONT_FILE" ]; then
    echo "日本語フォント（M PLUS Rounded 1c）をダウンロード中..."
    wget -O "/tmp/MPLUSRounded1c.zip" "https://fonts.google.com/download?family=M%20PLUS%20Rounded%201c"
    
    if [ -f "/tmp/MPLUSRounded1c.zip" ]; then
        cd /tmp
        unzip -q MPLUSRounded1c.zip
        cp MPLUSRounded1c-Bold.ttf "$FONT_FILE"
        echo -e "${GREEN}✅ フォントインストール完了${NC}"
    else
        echo -e "${YELLOW}⚠️  フォントダウンロードに失敗。デフォルトフォントを使用します${NC}"
    fi
else
    echo -e "${GREEN}✅ フォント既にインストール済み${NC}"
fi

# GPIO設定の確認
echo -e "${BLUE}⚡ GPIO設定の確認...${NC}"
echo "Inky Impression接続確認:"
echo "  CS:    GPIO 8  (Pin 24)"
echo "  DC:    GPIO 25 (Pin 22)"
echo "  RESET: GPIO 17 (Pin 11)"
echo "  BUSY:  GPIO 24 (Pin 18)"

# テストスクリプトの実行
echo ""
echo -e "${BLUE}🧪 E-paperディスプレイテスト...${NC}"
echo "テストを実行しますか? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}プレビューモードでテスト実行中（仮想環境内）...${NC}"
    source "$VENV_PATH/bin/activate"
    python3 /home/pi/AIPhotoFrame/ai-photoframe/display_epaper.py --preview
    
    if [ -f "/tmp/epaper_preview.png" ]; then
        echo -e "${GREEN}✅ プレビュー生成成功: /tmp/epaper_preview.png${NC}"
        echo ""
        echo "実際のE-paperディスプレイでテストしますか? (y/N)"
        read -r response2
        
        if [[ "$response2" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}E-paperディスプレイテスト実行中（仮想環境内）...${NC}"
            python3 /home/pi/AIPhotoFrame/ai-photoframe/display_epaper.py
        fi
    fi
    deactivate
fi

echo ""
echo -e "${GREEN}🎉 E-paperディスプレイセットアップ完了！${NC}"
echo ""
echo -e "${BLUE}📚 使用方法:${NC}"
echo "  1. 仮想環境アクティベート: source $VENV_PATH/bin/activate"
echo "  2. 画像表示: python3 /home/pi/AIPhotoFrame/ai-photoframe/display_epaper.py"
echo "  3. 完全実行: /home/pi/AIPhotoFrame/ai-photoframe/run_photoframe.sh"
echo "  4. プレビュー: python3 display_epaper.py --preview"
echo ""
echo -e "${BLUE}🔧 トラブルシューティング:${NC}"
echo "  - SPI無効エラー: sudo raspi-config → Interface Options → SPI → Enable"
echo "  - GPIO接続確認: 上記のピン番号を確認"
echo "  - 権限エラー: sudo usermod -a -G spi,gpio pi && sudo reboot"