# Raspberry Pi 4B/5 FastSD CPU セットアップガイド（2025年完全版）

## 概要
Raspberry Pi 4B/5でFastSD CPUを使用したStable Diffusion画像生成AIの完全自動セットアップガイドです。本ガイドは実際の構築・検証をもとに作成し、OpenVino互換性問題を回避した安定動作版を提供します。

## 🔧 ワンクリックインストール
```bash
# 自動インストールスクリプト実行（推奨）
curl -fsSL https://raw.githubusercontent.com/donkeykey/AIPhotoFrame/main/ai-photoframe/install_fastsdcpu_rpi.sh | bash

# または手動インストールの場合は以下の手順に従ってください
```

## 事前確認：システム要件

### 必須ハードウェア
- **Raspberry Pi 4B/5** (4GB以上推奨、8GBモデルなら安定)
- **MicroSDカード**: 32GB以上（推奨: 64GB以上のClass 10またはA1対応）
- **冷却システム**: 発熱が大きいためヒートシンクとファンは必須
- **電源**: 3A出力のUSB Type-C電源（公式推奨）

### サポート状況
- ✅ **Raspberry Pi 4B**: 完全サポート（検証済み）
- ✅ **Raspberry Pi 5**: 完全サポート（ARM64アーキテクチャ対応）
- ⚠️ **Raspberry Pi 3**: メモリ不足のため非推奨

### 重要：メモリ要件の確認
4GBのRAMとスワップ領域8GBが必要という要件があります。メモリ不足は最も多い失敗原因です。

## ステップ1: Raspberry Pi OS の準備

### 推奨OS設定
```bash
# 推奨: Raspberry Pi OS with desktop bookworm (64-bit)
# 理由: Python 3.11.2が標準搭載で互換性が高い
```

### 初期システム設定
```bash
# システム全体の更新（必須）
sudo apt update && sudo apt upgrade -y

# 必要パッケージのインストール
sudo apt install -y git python3 python3-venv python3-pip
sudo apt install -y python3-dev build-essential libffi-dev libssl-dev

# Python仮想環境対応（最新のOSで必要）
sudo apt install -y python3-full
```

## ステップ2: スワップ領域の拡張（重要）

### 現在の状況確認
```bash
# メモリとスワップの確認
free -h

# スワップの詳細確認
sudo swapon -s
```

**一般的な初期状態:** デフォルトでは約100MBのスワップ領域しかない

### スワップ拡張の実行
```bash
# dphys-swapfile サービス停止
sudo systemctl stop dphys-swapfile

# 設定ファイルのバックアップ
sudo cp /etc/dphys-swapfile /etc/dphys-swapfile.backup

# 設定ファイル編集
sudo nano /etc/dphys-swapfile
```

**設定変更内容:**
```bash
# 既存の設定をコメントアウト
#CONF_SWAPSIZE=100

# 新しい設定を追加
CONF_SWAPSIZE=6144
CONF_MAXSWAP=6144
```

**スワップの再構築:**
```bash
# 新しいスワップファイル作成
sudo dphys-swapfile setup

# サービス再開
sudo systemctl start dphys-swapfile

# 確認
free -h
# Swapが6GB程度表示されることを確認
```

## ステップ3: Python仮想環境の準備

### 最新のRaspberry Pi OSでの注意点
最新のOSでは「外部管理環境」エラーが発生するため、仮想環境の使用が必須

```bash
# 作業ディレクトリ作成
mkdir ~/fastsdcpu-project
cd ~/fastsdcpu-project

# Python仮想環境作成
python3 -m venv fastsd-env

# 仮想環境有効化
source fastsd-env/bin/activate

# pip最新化
pip install --upgrade pip setuptools
```

## ステップ4: FastSD CPU のインストール

### ⚠️ 重要：OpenVino互換性問題の回避
**最新のFastSD CPUはOpenVinoライブラリを使用しており、ARM64アーキテクチャで「Illegal instruction」エラーが発生します。**

### 安定版の使用（推奨）
```bash
# FastSD CPUの安定版クローン
git clone https://github.com/rupeshs/fastsdcpu.git
cd fastsdcpu

# OpenVino導入前の安定版に切り替え
git checkout 3e69280

# 実行権限付与
chmod +x install.sh start-webui.sh
```

### 依存関係のインストール
```bash
# 仮想環境内で互換性のあるバージョンをインストール
pip install torch==2.0.1 torchvision
pip install diffusers==0.21.4 transformers==4.34.0
pip install huggingface_hub==0.16.4 accelerate==0.21.0
pip install safetensors==0.3.3 omegaconf
pip install "numpy<2.0"  # 重要: NumPy 2.x系との互換性問題回避
```

**インストール時の注意点:**
- Raspberry PiではQT5のインストールに失敗するため、GUIアプリは使用不可
- インストールには30分～1時間程度かかります
- 「Preparing metadata (Pyproject.toml)」で非常に時間がかかる場合はスワップ不足の可能性

### よくあるエラーと対処法

#### Python関連エラー
```bash
# エラー: python3.10-venv not found
sudo apt install python3.10-venv

# エラー: pip関連
sudo apt install python3-pip
pip install --upgrade pip
```

#### メモリ不足エラー（"Killed"メッセージ）
```bash
# スワップを8GBに増加
sudo systemctl stop dphys-swapfile
sudo nano /etc/dphys-swapfile
# CONF_SWAPSIZE=8192に変更
sudo dphys-swapfile setup
sudo systemctl start dphys-swapfile
```

## ステップ5: 外部アクセス設定（オプション）

### WebUI設定の変更
他のPCからアクセスする場合：

```bash
# 設定ファイルバックアップ
cp src/frontend/webui/ui.py src/frontend/webui/ui.py.orig

# 設定変更
nano src/frontend/webui/ui.py
```

**変更箇所（99行目付近）:**
```python
# 変更前
webui.launch(share=share)

# 変更後
webui.launch(share=share, server_name="0.0.0.0")
```

## ステップ6: 起動と動作確認

### 初回起動
```bash
# 作業ディレクトリに移動
cd ~/fastsdcpu-project/fastsdcpu

# 仮想環境有効化（重要）
source ../fastsd-env/bin/activate

# WebUI起動
./start-webui.sh
```

### アクセス方法
- **ローカル**: http://localhost:7860
- **外部**: http://[RaspberryPiのIP]:7860

### 初回起動時の注意点
- 初回起動時はモデルのダウンロードで時間がかかる
- ダウンロード完了後はオフラインでも動作可能
- モデルダウンロードで10-15GB程度のディスク容量を消費

## ステップ7: 最適化設定

### 画像生成の推奨設定
**高速化のための設定:**
- **Steps**: 2-4（少なくするほど高速）
- **Resolution**: 512x512（推奨サイズ）
- **Model**: LCMまたはTurboモデル使用

### メモリ効率化設定
```bash
# ブラウザのタブを最小限に（重要）
# 理由: ブラウザがメモリを大量消費するため
```

タブの開きすぎでメモリ使用量が大きくなり、ブラウザを閉じて別のブラウザで実行すると約6秒で作成できた

### パフォーマンス向上設定
```bash
# CPU性能モード設定（オプション）
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 不要サービス停止でメモリ解放
sudo systemctl disable bluetooth
sudo systemctl stop bluetooth
```

## ステップ8: 運用時の注意点

### 温度管理
- 発熱が大きいため継続的な冷却が必要
- 長時間使用時は温度監視を実施
- 必要に応じて処理間隔を空ける

### ストレージ管理
```bash
# 生成画像の保存場所
ls ~/fastsdcpu-project/fastsdcpu/results/

# 定期的な容量確認
df -h

# 古い画像の削除（容量管理）
find ~/fastsdcpu-project/fastsdcpu/results/ -type f -mtime +7 -delete
```

### SDカード延命対策
SDカードは書き換え回数に上限があるため、頻繁な書き込みで寿命が縮む

```bash
# ログの一時的無効化（オプション）
sudo systemctl stop rsyslog
```

## トラブルシューティング

### 主要な問題と解決法

#### 1. "Killed"エラーで停止
**原因**: メモリ不足
**解決策**: 
- スワップを8GBに増加
- 不要なアプリケーション終了
- ブラウザタブの削減

#### 2. インストールが途中で止まる
**原因**: スワップ不足で「Preparing metadata」で停止
**解決策**: 
- スワップ領域の拡張
- 仮想環境の再作成

#### 3. WebUIにアクセスできない
**原因**: 外部アクセス設定未完了
**解決策**: 
- ui.pyの設定変更確認
- ファイアウォール設定確認

#### 4. 画像生成が異常に遅い
**原因**: メモリ不足またはCPU制限
**解決策**: 
- ブラウザメモリ使用量削減
- 解像度を512x512に制限
- Steps数を2-4に設定

### パフォーマンス期待値
- **Raspberry Pi 4B (4GB)**: 約10分/枚
- **解像度512x512**: 標準的な処理時間
- **初回実行**: モデルダウンロードで追加時間

## API使用（上級者向け）

### API専用起動
```bash
# API起動スクリプト作成
cp start-webui.sh start-api.sh

# 編集
nano start-api.sh
# 最終行を以下に変更
# $PYTHON_COMMAND src/app.py --api
```

### API使用例
```bash
# APIサーバー起動
./start-api.sh

# cURLテスト
curl -X POST http://localhost:7860/api/generate \
  -H "Content-Type: application/json" \
  -d '{"prompt": "A beautiful sunset over mountains", "steps": 4}'
```

## まとめ

このガイドは実際の成功・失敗事例を基に作成しており、特に以下の点が成功の鍵となります：

1. **適切なスワップ設定**: 6-8GBのスワップ領域確保
2. **仮想環境の使用**: 最新OSでの必須要件
3. **メモリ管理**: ブラウザタブ数の制限
4. **冷却対策**: 継続的な温度管理

前回に比べて格段に使いやすくなり、高速化されたという報告もあり、適切な設定により実用的な画像生成環境を構築できます。

### 推奨使用パターン
- 教育・実験用途での画像生成
- IoTプロジェクトでのエッジAI活用
- プロトタイプ開発での概念実証

Raspberry Pi 4Bの制約を理解した上で使用すれば、GPUなしでも十分実用的な画像生成AIシステムを実現できます。