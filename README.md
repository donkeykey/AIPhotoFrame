# AI Photo Frame Project

FastSD CPUとe-paperディスプレイを使用したAI画像生成フォトフレーム

## 📁 プロジェクト構成

### 🖼️ AI Photo Frame (メインプロジェクト)
```
ai-photoframe/
├── install_fastsdcpu_rpi.sh      # 自動インストールスクリプト（SPI設定含む）
├── ai_photoframe.py              # メインプログラム（画像生成＋表示）
├── image_generator.py            # 画像生成機能
├── run_ai_photoframe.sh          # 実行スクリプト
├── generated_images/             # 生成画像保存ディレクトリ（最新10枚）
├── raspberrypi_fastsdcpu_setup.md # 詳細セットアップガイド
└── README_installation.md        # インストールガイド
```

**機能**:
- Raspberry Pi 4B/5 での FastSD CPU (Stable Diffusion) による640x400画像生成
- Inky e-paperディスプレイへの自動表示
- 生成画像の管理（最新10枚を自動保持）
- SPI/I2C自動設定

### 📚 Legacy Reference (参考用)
```
legacy-reference/
├── app.py              # 旧メインアプリケーション
├── server.py           # 旧サーバー
├── prompt.json         # プロンプト設定
├── static/             # CSS・JSファイル (Bootstrap)
└── templates/          # HTMLテンプレート
```

**用途**: 旧版のWebベースアプリ（参考用・非推奨）

## 🚀 クイックスタート

### 1. AI Photo Frame セットアップ
```bash
# リポジトリをクローン
git clone https://github.com/donkeykey/AIPhotoFrame.git
cd AIPhotoFrame/ai-photoframe

# 自動インストール（SPI設定、FastSD CPU、E-paper用ライブラリ）
./install_fastsdcpu_rpi.sh
```

### 2. 使用方法
```bash
# 画像生成して即座に表示
./run_ai_photoframe.sh generate "beautiful mountain landscape"

# 画像生成のみ（表示しない）
./run_ai_photoframe.sh generate-only "sunset over ocean"

# 既存画像を表示
./run_ai_photoframe.sh display /path/to/image.jpg

# 生成画像一覧を表示
./run_ai_photoframe.sh list
```

### 旧版の参考（非推奨）
```bash
cd legacy-reference
python3 server.py
```

## 📖 詳細ドキュメント

- **AI Photo Frame インストール**: [ai-photoframe/README_installation.md](ai-photoframe/README_installation.md)
- **セットアップガイド**: [ai-photoframe/raspberrypi_fastsdcpu_setup.md](ai-photoframe/raspberrypi_fastsdcpu_setup.md)

## 🎯 対応環境

- **Raspberry Pi 4B/5**: FastSD CPU 対応
- **Python 3.11+**: 仮想環境で管理
- **ARM64**: 完全対応
- **E-paper**: Inky 640x400 対応（自動SPI設定）
- **メモリ**: 4GB以上推奨

## ⚠️ 注意事項

- **初回実行**: モデルダウンロードに10-15分程度かかります
- **生成時間**: Raspberry Pi CPUでは画像生成に10-15分程度必要
- **メモリ使用量**: 生成中は他のアプリを終了することを推奨
- **ファイル管理**: 生成画像は最新10枚のみ自動保持
- **SPI設定**: インストールスクリプトが自動的に有効化（再起動が必要な場合あり）

## 🔧 生成画像について

- **サイズ**: 640x400 (E-paper最適化)
- **形式**: PNG
- **ファイル名**: `ai_photo_YYYYMMDD_HHMMSS.png`
- **保存場所**: `~/AIPhotoFrame/ai-photoframe/generated_images/`

---
**Last Updated**: 2025年9月
