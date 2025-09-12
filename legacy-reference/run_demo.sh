#!/bin/bash
# demo.py用実行スクリプト（GPIO競合回避）

set -e

VENV_PATH="/home/pi/fastsdcpu-project/fastsd-simple-env"

echo "🔧 GPIO競合回避のためSPIをリセット中..."

# SPIデバイスを一旦リセット
sudo modprobe -r spidev || true
sleep 1
sudo modprobe spidev || true
sleep 1

echo "🖼️  demo.py実行中..."

# sudo環境で仮想環境のPythonを使用
sudo -E "$VENV_PATH/bin/python3" demo.py "$@"