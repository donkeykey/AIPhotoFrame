#!/bin/bash

# Raspberry Pi 4B/5 FastSD CPU 自動インストールスクリプト
# Version: 2025.1
# サポート: Raspberry Pi 4B/5 (ARM64)

set -e  # エラー時は即座に終了

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}=== $1 ===${NC}\n"
}

# エラーハンドリング
cleanup() {
    if [ $? -ne 0 ]; then
        log_error "インストールが失敗しました。ログを確認してください。"
        log_info "サポートが必要な場合は、以下の情報を含めてお問い合わせください："
        echo "- Raspberry Pi モデル: $(cat /proc/device-tree/model 2>/dev/null || echo 'Unknown')"
        echo "- OS バージョン: $(lsb_release -d 2>/dev/null || echo 'Unknown')"
        echo "- Python バージョン: $(python3 --version 2>/dev/null || echo 'Unknown')"
        echo "- エラー発生ステップ: $current_step"
    fi
}

trap cleanup EXIT

# システム情報取得
get_system_info() {
    log_step "システム情報の確認"
    
    local model=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
    local arch=$(uname -m)
    local os_info=$(lsb_release -d 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")
    
    log_info "Raspberry Pi モデル: $model"
    log_info "アーキテクチャ: $arch"
    log_info "OS: $os_info"
    
    # Raspberry Pi 4/5 チェック
    if [[ "$model" == *"Raspberry Pi 4"* ]]; then
        log_success "Raspberry Pi 4B が検出されました"
        RPI_MODEL="4"
    elif [[ "$model" == *"Raspberry Pi 5"* ]]; then
        log_success "Raspberry Pi 5 が検出されました"
        RPI_MODEL="5"
    else
        log_warning "Raspberry Pi 4B/5 以外のモデルが検出されました: $model"
        log_warning "動作は保証されませんが、インストールを続行します"
        RPI_MODEL="other"
    fi
    
    # ARM64 アーキテクチャチェック
    if [[ "$arch" != "aarch64" ]]; then
        log_error "ARM64 アーキテクチャが必要です。現在: $arch"
        exit 1
    fi
    
    # メモリチェック
    local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    log_info "システムメモリ: ${total_mem}MB"
    
    if [ "$total_mem" -lt 3500 ]; then
        log_error "最低4GBのメモリが必要です。現在: ${total_mem}MB"
        exit 1
    fi
}

# 前提条件チェック
check_prerequisites() {
    log_step "前提条件のチェック"
    current_step="前提条件チェック"
    
    # インターネット接続チェック
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "インターネット接続が必要です"
        exit 1
    fi
    log_success "インターネット接続: OK"
    
    # ディスク容量チェック
    local free_space=$(df / | tail -1 | awk '{print $4}')
    local free_space_gb=$((free_space / 1024 / 1024))
    log_info "利用可能ディスク容量: ${free_space_gb}GB"
    
    if [ "$free_space_gb" -lt 5 ]; then
        log_error "最低5GBの空き容量が必要です"
        exit 1
    fi
    
    log_success "前提条件: すべてクリア"
}

# SPI有効化
enable_spi() {
    log_step "SPI インターフェースの有効化"
    current_step="SPI有効化"
    
    # 現在のSPI設定確認
    if grep -q "^dtparam=spi=on" /boot/firmware/config.txt; then
        log_success "SPI は既に有効化されています"
        return
    fi
    
    log_info "config.txt の SPI 設定を確認中..."
    
    # config.txtのバックアップ
    sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
    log_info "config.txtのバックアップを作成しました"
    
    # SPIを有効化
    if grep -q "^#dtparam=spi=on" /boot/firmware/config.txt; then
        # コメントアウトされている場合は有効化
        log_info "SPI設定のコメントアウトを解除中..."
        sudo sed -i 's/^#dtparam=spi=on/dtparam=spi=on/' /boot/firmware/config.txt
    else
        # 設定が存在しない場合は追加
        log_info "SPI設定を追加中..."
        echo "dtparam=spi=on" | sudo tee -a /boot/firmware/config.txt > /dev/null
    fi
    
    # E-paper用のSPI追加設定
    if ! grep -q "^dtoverlay=spi0-0cs" /boot/firmware/config.txt; then
        log_info "E-paper用SPI設定を追加中..."
        echo "dtoverlay=spi0-0cs" | sudo tee -a /boot/firmware/config.txt > /dev/null
        log_info "dtoverlay=spi0-0cs を追加しました"
    fi
    
    # I2Cも同時に有効化（E-paperで使用する場合があるため）
    if ! grep -q "^dtparam=i2c_arm=on" /boot/firmware/config.txt; then
        if grep -q "^#dtparam=i2c_arm=on" /boot/firmware/config.txt; then
            log_info "I2C設定のコメントアウトを解除中..."
            sudo sed -i 's/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' /boot/firmware/config.txt
        else
            log_info "I2C設定を追加中..."
            echo "dtparam=i2c_arm=on" | sudo tee -a /boot/firmware/config.txt > /dev/null
        fi
    fi
    
    # ユーザーをspiとi2cグループに追加
    log_info "ユーザー権限を設定中..."
    sudo usermod -a -G spi,i2c,gpio $USER
    
    log_success "SPI/I2C インターフェースの有効化完了"
    log_warning "変更を有効にするには再起動が必要です"
    
    # 再起動が必要であることを記録
    REBOOT_REQUIRED=true
}

# システム更新
update_system() {
    log_step "システムの更新"
    current_step="システム更新"
    
    log_info "パッケージリストの更新中..."
    sudo apt update -qq
    
    log_info "システムの更新中（時間がかかる場合があります）..."
    sudo apt upgrade -y -qq
    
    log_info "必要なパッケージのインストール中..."
    sudo apt install -y \
        git \
        python3 \
        python3-venv \
        python3-pip \
        python3-dev \
        python3-full \
        build-essential \
        libffi-dev \
        libssl-dev \
        curl \
        wget
    
    log_success "システム更新完了"
}

# スワップ領域の設定
setup_swap() {
    log_step "スワップ領域の設定"
    current_step="スワップ設定"
    
    local current_swap=$(free -m | awk '/^Swap:/{print $2}')
    log_info "現在のスワップ: ${current_swap}MB"
    
    if [ "$current_swap" -lt 6000 ]; then
        log_info "スワップ領域を6GBに拡張中..."
        
        # dphys-swapfile サービス停止
        sudo systemctl stop dphys-swapfile
        
        # 設定ファイルのバックアップ
        sudo cp /etc/dphys-swapfile /etc/dphys-swapfile.backup
        
        # 新しい設定を適用
        sudo tee /etc/dphys-swapfile > /dev/null << EOF
# /etc/dphys-swapfile - user settings for dphys-swapfile package
# auto-generated by FastSD CPU installer

CONF_SWAPSIZE=6144
CONF_MAXSWAP=6144
CONF_SWAPFACTOR=2
CONF_SWAPFILE=/var/swap
EOF
        
        # 新しいスワップファイル作成
        sudo dphys-swapfile setup
        sudo systemctl start dphys-swapfile
        
        # 確認
        sleep 2
        local new_swap=$(free -m | awk '/^Swap:/{print $2}')
        log_success "スワップ拡張完了: ${new_swap}MB"
    else
        log_success "スワップ領域は既に十分です: ${current_swap}MB"
    fi
}

# Python環境の準備
setup_python_env() {
    log_step "Python仮想環境の準備"
    current_step="Python環境準備"
    
    # プロジェクトディレクトリ作成
    PROJECT_DIR="$HOME/fastsdcpu-project"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    log_info "Python仮想環境を作成中..."
    python3 -m venv fastsd-simple-env
    
    log_info "仮想環境をアクティベート中..."
    source fastsd-simple-env/bin/activate
    
    log_info "pipのアップグレード中..."
    pip install --upgrade pip setuptools wheel
    
    log_success "Python環境準備完了"
}

# FastSD CPU のインストール
install_fastsdcpu() {
    log_step "FastSD CPU のインストール"
    current_step="FastSD CPUインストール"
    
    cd "$PROJECT_DIR"
    
    log_info "FastSD CPU リポジトリをクローン中..."
    if [ -d "fastsdcpu-stable" ]; then
        log_info "既存のディレクトリを削除中..."
        rm -rf fastsdcpu-stable
    fi
    
    git clone https://github.com/rupeshs/fastsdcpu.git fastsdcpu-stable
    cd fastsdcpu-stable
    
    log_info "OpenVino互換性問題回避のため、安定版に切り替え中..."
    git checkout 3e69280
    
    log_info "仮想環境をアクティベート中..."
    source ../fastsd-simple-env/bin/activate
    
    log_info "互換性のあるPyTorchをインストール中..."
    pip install torch==2.0.1 torchvision --index-url https://download.pytorch.org/whl/cpu
    
    log_info "互換性のある依存関係をインストール中..."
    pip install diffusers==0.21.4
    pip install transformers==4.34.0
    pip install huggingface_hub==0.16.4
    pip install accelerate==0.21.0
    pip install safetensors==0.3.3
    pip install omegaconf
    pip install "numpy<2.0"
    pip install Pillow
    pip install tqdm
    
    log_info "AI Photo Frame用の追加パッケージをインストール中..."
    # E-paper display support
    pip install inky
    # その他の画像処理ライブラリ
    pip install pillow
    pip install RPi.GPIO
    pip install spidev
    
    log_success "FastSD CPU インストール完了"
}

# テストスクリプトの作成
create_test_script() {
    log_step "テストスクリプトの作成"
    current_step="テストスクリプト作成"
    
    cd "$PROJECT_DIR/fastsdcpu-stable"
    
    cat > test_fastsd.py << 'EOF'
#!/usr/bin/env python3
"""
FastSD CPU テストスクリプト for Raspberry Pi 4B/5
OpenVino互換性問題を回避した安定版
"""

from diffusers import StableDiffusionPipeline
import torch
from time import time
import sys
import os

def main():
    print("=== FastSD CPU テスト for Raspberry Pi 4B/5 ===")
    print("OpenVino非使用版（ARM64互換）")
    print("")
    
    try:
        print("Stable Diffusionモデルを読み込み中...")
        print("初回実行時はモデルのダウンロードに時間がかかります")
        
        # 軽量なモデルを使用
        model_id = "stabilityai/stable-diffusion-2-1-base"
        
        # CPU最適化設定でパイプラインを読み込み
        pipe = StableDiffusionPipeline.from_pretrained(
            model_id,
            torch_dtype=torch.float32,  # CPU互換性のためfloat32使用
            safety_checker=None,        # 高速化のため安全チェッカーを無効
            requires_safety_checker=False,
        )
        pipe = pipe.to("cpu")
        
        # メモリ効率の最適化
        pipe.enable_attention_slicing()
        
        print("✅ モデル読み込み完了！")
        print("")
        
        # テスト用プロンプト
        prompt = "a beautiful sunset over mountains, digital art"
        
        print(f"画像生成中: '{prompt}'")
        print("Raspberry Pi CPUでは10-15分程度かかります...")
        print("")
        
        # CPU最適化設定で画像生成
        start_time = time()
        image = pipe(
            prompt,
            num_inference_steps=20,      # バランスの取れたステップ数
            guidance_scale=7.5,
            height=512,
            width=512,
        ).images[0]
        end_time = time()
        
        # 画像保存
        output_path = "test_output.png"
        image.save(output_path)
        
        duration = end_time - start_time
        print("")
        print("🎉 画像生成成功！")
        print(f"⏱️  生成時間: {duration:.1f}秒 ({duration/60:.1f}分)")
        print(f"🖼️  保存先: {os.path.abspath(output_path)}")
        print("")
        print("✅ FastSD CPU がRaspberry Pi上で正常に動作しています！")
        
        return True
        
    except Exception as e:
        print(f"❌ エラーが発生しました: {e}")
        import traceback
        print("\n詳細エラー情報:")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
EOF
    
    chmod +x test_fastsd.py
    log_success "テストスクリプト作成完了"
}

# systemdサービスの設定
setup_systemd_service() {
    log_step "systemd自動起動サービスの設定"
    current_step="systemdサービス設定"

    # AI Photo Frameディレクトリの確認
    AI_PHOTOFRAME_DIR="$HOME/AIPhotoFrame/ai-photoframe"
    if [ ! -d "$AI_PHOTOFRAME_DIR" ]; then
        log_warning "AI Photo Frameディレクトリが見つかりません: $AI_PHOTOFRAME_DIR"
        log_warning "systemdサービスの設定をスキップします"
        return
    fi

    # サービスファイルの確認
    if [ ! -f "$AI_PHOTOFRAME_DIR/ai-photoframe.service" ]; then
        log_warning "systemdサービスファイルが見つかりません"
        log_warning "systemdサービスの設定をスキップします"
        return
    fi

    log_info "systemdサービスファイルをコピー中..."
    sudo cp "$AI_PHOTOFRAME_DIR/ai-photoframe.service" /etc/systemd/system/

    log_info "systemd設定をリロード中..."
    sudo systemctl daemon-reload

    # サービスの有効化確認
    read -p "AI Photo Frameを自動起動しますか？ (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        log_info "AI Photo Frameサービスを有効化中..."
        sudo systemctl enable ai-photoframe.service

        read -p "今すぐサービスを開始しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "AI Photo Frameサービスを開始中..."
            sudo systemctl start ai-photoframe.service

            # サービス状態確認
            sleep 3
            if systemctl is-active --quiet ai-photoframe.service; then
                log_success "AI Photo Frameサービスが正常に開始されました"
                log_info "サービス状態を確認: sudo systemctl status ai-photoframe"
                log_info "ログを確認: sudo journalctl -u ai-photoframe -f"
            else
                log_warning "AI Photo Frameサービスの開始に失敗した可能性があります"
                log_info "状態確認: sudo systemctl status ai-photoframe"
            fi
        else
            log_info "サービスは有効化されていますが、開始されていません"
            log_info "手動で開始: sudo systemctl start ai-photoframe"
        fi
    else
        log_info "自動起動は設定されませんでした"
        log_info "手動で有効化: sudo systemctl enable ai-photoframe"
    fi

    log_success "systemdサービス設定完了"
}

# 起動スクリプトの作成
create_startup_scripts() {
    log_step "起動スクリプトの作成"
    current_step="起動スクリプト作成"
    
    cd "$PROJECT_DIR"
    
    # FastSD CPU 起動スクリプト
    cat > start_fastsd.sh << 'EOF'
#!/bin/bash
# FastSD CPU 起動スクリプト

PROJECT_DIR="$HOME/fastsdcpu-project"
cd "$PROJECT_DIR/fastsdcpu-stable"

echo "FastSD CPU を起動中..."
echo "仮想環境をアクティベート中..."

source ../fastsd-simple-env/bin/activate

echo "テスト実行中..."
python test_fastsd.py
EOF
    
    # テストスクリプト
    cat > test_installation.sh << 'EOF'
#!/bin/bash
# インストール検証スクリプト

PROJECT_DIR="$HOME/fastsdcpu-project"
cd "$PROJECT_DIR/fastsdcpu-stable"

echo "=== FastSD CPU インストール検証 ==="

# 仮想環境の確認
if [ -d "../fastsd-simple-env" ]; then
    echo "✅ Python仮想環境: OK"
else
    echo "❌ Python仮想環境: 見つかりません"
    exit 1
fi

# 仮想環境をアクティベート
source ../fastsd-simple-env/bin/activate

# パッケージの確認
echo "必要なパッケージの確認中..."
python -c "
import sys
packages = ['torch', 'diffusers', 'transformers', 'numpy', 'PIL']
missing = []

for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg}: OK')
    except ImportError:
        print(f'❌ {pkg}: 見つかりません')
        missing.append(pkg)

if missing:
    print(f'エラー: 以下のパッケージが見つかりません: {missing}')
    sys.exit(1)
else:
    print('✅ 全ての必要パッケージが利用可能です')
"

echo ""
echo "🎉 インストール検証完了！"
echo ""
echo "使用方法:"
echo "  テスト実行: cd $PROJECT_DIR && ./start_fastsd.sh"
echo "  手動実行: cd $PROJECT_DIR/fastsdcpu-stable && source ../fastsd-simple-env/bin/activate && python test_fastsd.py"
EOF
    
    chmod +x start_fastsd.sh test_installation.sh
    log_success "起動スクリプト作成完了"
}

# インストール完了メッセージ
show_completion_message() {
    log_step "インストール完了"
    
    echo ""
    echo "🎉 FastSD CPU のインストールが完了しました！"
    echo ""
    echo "📁 インストール場所: $PROJECT_DIR"
    echo ""
    echo "🚀 使用方法:"
    echo "  1. テスト実行:"
    echo "     cd $PROJECT_DIR"
    echo "     ./start_fastsd.sh"
    echo ""
    echo "  2. 手動実行:"
    echo "     cd $PROJECT_DIR/fastsdcpu-stable"
    echo "     source ../fastsd-simple-env/bin/activate"
    echo "     python test_fastsd.py"
    echo ""
    echo "  3. インストール検証:"
    echo "     cd $PROJECT_DIR"
    echo "     ./test_installation.sh"
    echo ""
    echo "  4. AI Photo Frame の使用:"
    echo "     cd ~/AIPhotoFrame/ai-photoframe"
    echo "     ./run_ai_photoframe.sh generate \"beautiful mountain landscape\""
    echo "     ./run_ai_photoframe.sh display /path/to/image.jpg"
    echo "     ./run_ai_photoframe.sh continuous  # 永続実行モード"
    echo ""
    echo "  5. systemd自動起動管理:"
    echo "     sudo systemctl start ai-photoframe      # サービス開始"
    echo "     sudo systemctl stop ai-photoframe       # サービス停止"
    echo "     sudo systemctl status ai-photoframe     # 状態確認"
    echo "     sudo journalctl -u ai-photoframe -f     # ログ確認"
    echo ""
    echo "⚠️  注意事項:"
    echo "  - 初回実行時はモデルダウンロードに時間がかかります（約10-15分）"
    echo "  - Raspberry Pi CPUでの画像生成は10-15分程度かかります"
    echo "  - メモリ使用量を抑えるため、実行中は他のアプリを終了してください"
    echo "  - E-paperディスプレイを使用する場合はSPIが有効化されている必要があります"
    echo ""
    echo "🔧 システム情報:"
    echo "  - Raspberry Pi モデル: $(cat /proc/device-tree/model 2>/dev/null || echo 'Unknown')"
    echo "  - Python バージョン: $(python3 --version)"
    echo "  - 総メモリ: $(free -h | awk '/^Mem:/{print $2}')"
    echo "  - スワップ: $(free -h | awk '/^Swap:/{print $2}')"
    echo ""
    log_success "すべての準備が完了しました！"
}

# メイン実行
main() {
    clear
    echo "================================================"
    echo "  FastSD CPU 自動インストーラー for Raspberry Pi"
    echo "  Version: 2025.1"
    echo "  Support: Raspberry Pi 4B/5"
    echo "================================================"
    echo ""
    
    # 再起動フラグを初期化
    REBOOT_REQUIRED=false
    
    get_system_info
    check_prerequisites
    enable_spi
    update_system
    setup_swap
    setup_python_env
    install_fastsdcpu
    create_test_script
    create_startup_scripts
    setup_systemd_service
    show_completion_message
    
    # 再起動が必要な場合の処理
    if [ "$REBOOT_REQUIRED" = true ]; then
        echo ""
        log_warning "システムの変更を有効にするために再起動が必要です"
        echo ""
        read -p "今すぐ再起動しますか？ (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "システムを再起動しています..."
            sudo reboot
        else
            log_warning "手動で再起動してください: sudo reboot"
            log_info "再起動後にAI Photo Frameが使用可能になります"
        fi
    fi
    
    log_success "インストールプロセス完了！"
}

# スクリプト実行
main "$@"