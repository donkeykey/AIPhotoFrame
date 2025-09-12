from PIL import Image, ImageDraw, ImageFont, ImageOps
from inky.inky_uc8159 import Inky
import datetime
import os
import sys

# 表示する画像ファイルのパス（コマンドライン引数で指定可能）
if len(sys.argv) > 1:
    image_path = sys.argv[1]
else:
    # デフォルト画像パス
    image_path = "/home/pi/fastsdcpu-project/fastsdcpu-stable/test_output.png"

print(f"🖼️  画像を表示: {image_path}")

# 画像の存在確認
if not os.path.exists(image_path):
    print(f"❌ 画像ファイルが見つかりません: {image_path}")
    print("使用方法: python3 demo.py [画像ファイルパス]")
    sys.exit(1)

# 既存画像を読み込み
img = Image.open(image_path)
print(f"📷 画像を読み込み: {img.size}")

# 640x400にリサイズ（必要に応じて）
if img.size != (640, 400):
    img = img.resize((640, 400), Image.Resampling.LANCZOS)
    print(f"🔄 リサイズ: {img.size}")

# 現在時刻
dt_now = datetime.datetime.now()
disp_date = dt_now.strftime('%a, %d %b %Y %H:%M:%S')


# Set up the Inky display (GPIO競合回避)
try:
    # GPIO競合を無視して強制実行
    import warnings
    warnings.filterwarnings("ignore")
    
    inky_display = Inky(resolution=(640, 400), cs_pin=8, dc_pin=25, reset_pin=17, busy_pin=24)
    inky_display.set_border(inky_display.BLACK)
    print("✅ E-paperディスプレイ初期化成功")
except Exception as e:
    print(f"❌ E-paperディスプレイ初期化エラー: {e}")
    print("GPIO競合またはハードウェア接続を確認してください")
    sys.exit(1)

# draw text
draw = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype('/home/pi/font/MPLUSRounded1c-Bold.ttf', 18, encoding='unic')
except:
    font = ImageFont.load_default()
    print("⚠️  デフォルトフォントを使用")

# 画像ファイル名を表示テキストに使用
image_name = os.path.basename(image_path)
draw.text((8, 390), f'Displayed at {disp_date}\nImage: {image_name}', fill='white', stroke_width=2, stroke_fill='black', font=font, anchor='ld')

# flip and mirror
#img = ImageOps.flip(img)
#img = ImageOps.mirror(img)

print("🖼️  E-paperディスプレイに画像を転送中...")
inky_display.set_image(img)
inky_display.show()
print("✅ 画像表示完了！")
