# AI Photo Frame Project

AI画像生成とe-paperディスプレイを使用したフォトフレームプロジェクト

## 📁 プロジェクト構成

### 🖼️ AI Photo Frame (メインプロジェクト)
```
ai-photoframe/
├── install_fastsdcpu_rpi.sh      # 自動インストールスクリプト
├── raspberrypi_fastsdcpu_setup.md # 詳細セットアップガイド
└── README_installation.md        # インストールガイド
```

**用途**: 
- Raspberry Pi 4B/5 での FastSD CPU (Stable Diffusion) セットアップ
- **今後実装予定**: 画像生成機能、e-paperディスプレイ連携

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

### AI Photo Frame セットアップ（推奨）
```bash
# 自動インストール
curl -fsSL https://raw.githubusercontent.com/donkeykey/AIPhotoFrame/main/ai-photoframe/install_fastsdcpu_rpi.sh | bash
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
- **Python 3.11+**: 両プロジェクト対応
- **ARM64**: 完全対応

---
**Last Updated**: 2025年1月
