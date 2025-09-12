# FastSD CPU インストールガイド for Raspberry Pi 4B/5

## 🚀 クイックスタート

### ワンクリックインストール
```bash
# 自動インストール実行
curl -fsSL https://raw.githubusercontent.com/donkeykey/AIPhotoFrame/main/ai-photoframe/install_fastsdcpu_rpi.sh | bash

# またはローカルファイルから実行
wget https://raw.githubusercontent.com/donkeykey/AIPhotoFrame/main/ai-photoframe/install_fastsdcpu_rpi.sh
chmod +x install_fastsdcpu_rpi.sh
./install_fastsdcpu_rpi.sh
```

## 📋 システム要件

### 必須条件
- **Raspberry Pi 4B/5** (4GB RAM以上推奨)
- **空き容量**: 最低5GB (推奨: 10GB以上)
- **インターネット接続**: 初回インストール時必須
- **冷却システム**: ヒートシンク+ファン推奨

### サポート対象
- ✅ Raspberry Pi 4B (実証済み)
- ✅ Raspberry Pi 5 (ARM64対応)
- ✅ Debian/Raspberry Pi OS Bookworm
- ✅ ARM64 アーキテクチャ

## 🛠️ 自動インストール機能

### インストール内容
1. **システム更新** - 最新パッケージに更新
2. **スワップ拡張** - 6GBのスワップ領域確保
3. **Python環境** - 仮想環境とパッケージ管理
4. **FastSD CPU** - OpenVino非対応版（ARM64互換）
5. **依存関係** - NumPy 1.x系など互換バージョン
6. **テストスクリプト** - 動作確認用スクリプト

### 解決済み問題
- ✅ OpenVino「Illegal instruction」エラー
- ✅ NumPy 2.x系互換性問題
- ✅ ARM64アーキテクチャ対応
- ✅ メモリ不足による「Killed」エラー
- ✅ Python外部管理環境エラー

## 📊 インストール後の使用方法

### 1. 基本的な使用
```bash
# プロジェクトディレクトリに移動
cd ~/fastsdcpu-project

# テスト実行
./start_fastsd.sh
```

### 2. 手動実行
```bash
# 仮想環境をアクティベート
cd ~/fastsdcpu-project/fastsdcpu-stable
source ../fastsd-simple-env/bin/activate

# テスト実行
python test_fastsd.py
```

### 3. インストール検証
```bash
cd ~/fastsdcpu-project
./test_installation.sh
```

## ⚡ パフォーマンス情報

### 予想処理時間（Raspberry Pi 4B）
- **モデルダウンロード**: 10-15分（初回のみ）
- **画像生成**: 10-15分（512x512、20ステップ）
- **メモリ使用量**: 約4GB（スワップ込み）

### 最適化設定
- **推論ステップ**: 20（品質とスピードのバランス）
- **解像度**: 512x512（推奨サイズ）
- **プロンプト**: 英語推奨
- **NumPy**: 1.26.4（互換性版）

## 🔧 トラブルシューティング

### よくある問題

#### 1. ディスク容量不足
```bash
# 容量確認
df -h

# 不要ファイル削除
sudo apt autoremove
sudo apt autoclean
```

#### 2. メモリ不足
```bash
# スワップ確認
free -h

# 他のプロセス終了
sudo systemctl stop bluetooth
pkill -f chromium
```

#### 3. 温度上昇
```bash
# 温度確認
vcgencmd measure_temp

# 冷却ファン設置を推奨
```

#### 4. インストール失敗
```bash
# ログ確認
journalctl -xe

# 再インストール
rm -rf ~/fastsdcpu-project
./install_fastsdcpu_rpi.sh
```

## 📁 ファイル構成

```
~/fastsdcpu-project/
├── fastsd-simple-env/          # Python仮想環境
├── fastsdcpu-stable/           # FastSD CPUソース
│   ├── test_fastsd.py         # テストスクリプト
│   └── test_output.png        # 生成画像（実行後）
├── start_fastsd.sh            # 起動スクリプト
└── test_installation.sh       # インストール検証
```

## 🎯 動作確認済み環境

- **Raspberry Pi 4B (4GB/8GB)**: ✅ 完全動作
- **Raspberry Pi OS Bookworm**: ✅ 推奨環境  
- **Python 3.11.2**: ✅ 標準対応
- **PyTorch 2.0.1**: ✅ CPU最適化版
- **NumPy 1.26.4**: ✅ 互換性版

## 📞 サポート

### 問題報告時の情報
インストールに失敗した場合は、以下の情報を含めてお問い合わせください：

```bash
# システム情報収集
echo "=== システム情報 ==="
cat /proc/device-tree/model
uname -a
lsb_release -a
python3 --version
free -h
df -h
vcgencmd measure_temp
```

### 既知の制限事項
- **GUI版**: 使用不可（QT5インストール失敗）
- **OpenVino**: ARM64で非対応
- **CUDA**: Raspberry Piでは使用不可
- **生成速度**: GPU版と比較して低速

## 🔄 更新・アンインストール

### アップデート
```bash
cd ~/fastsdcpu-project/fastsdcpu-stable
source ../fastsd-simple-env/bin/activate
pip install --upgrade diffusers transformers
```

### アンインストール
```bash
# 完全削除
rm -rf ~/fastsdcpu-project

# スワップ設定復元（オプション）
sudo cp /etc/dphys-swapfile.backup /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile
```

---

**最終更新**: 2025年1月  
**動作確認**: Raspberry Pi 4B/5, ARM64, Debian Bookworm