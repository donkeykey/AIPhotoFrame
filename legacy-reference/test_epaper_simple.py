#!/usr/bin/env python3
"""
E-paperディスプレイの接続テスト
"""

from PIL import Image, ImageDraw
from inky.inky_uc8159 import Inky
import sys

def test_epaper():
    """E-paperディスプレイの基本テスト"""
    try:
        print("🔧 E-paperディスプレイテスト開始...")
        
        # Inkyディスプレイの初期化
        inky = Inky(resolution=(640, 400), cs_pin=8, dc_pin=25, reset_pin=17, busy_pin=24)
        print("✅ E-paperディスプレイ初期化成功")
        
        # シンプルなテスト画像を作成
        image = Image.new('RGB', (640, 400), 'white')
        draw = ImageDraw.Draw(image)
        
        # 大きな赤い四角を描画
        draw.rectangle([50, 50, 590, 350], fill='red')
        draw.text((100, 200), "E-paper Test", fill='white')
        
        print("🖼️  テスト画像を転送中...")
        
        # 画像を表示（タイムアウト付き）
        inky.set_image(image)
        inky.show()
        
        print("✅ E-paperディスプレイテスト完了！")
        print("E-paperディスプレイに赤い四角が表示されていれば成功です。")
        return True
        
    except Exception as e:
        print(f"❌ E-paperディスプレイテストエラー: {e}")
        return False

if __name__ == "__main__":
    success = test_epaper()
    sys.exit(0 if success else 1)