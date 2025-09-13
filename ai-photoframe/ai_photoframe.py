#!/usr/bin/env python3
"""
AI Photo Frame - メインプログラム
画像生成とe-paper表示を統合
"""

from PIL import Image
from inky.inky_uc8159 import Inky
import os
import sys
from image_generator import ImageGenerator
import time
from datetime import datetime
import glob
import json
import random
import signal

class AIPhotoFrame:
    def __init__(self):
        """AI Photo Frameの初期化"""
        # 設定ファイル読み込み
        self.config = self._load_config()

        # E-paper ディスプレイの設定
        resolution = tuple(self.config['display']['resolution'])
        self.inky_display = Inky(resolution=resolution, cs_pin=8, dc_pin=25, reset_pin=17, busy_pin=24)
        self.inky_display.set_border(self.inky_display.BLACK)

        # 画像生成器の初期化
        self.generator = ImageGenerator()

        # 出力ディレクトリ
        self.output_dir = "/home/pi/AIPhotoFrame/ai-photoframe/generated_images"
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)

        # 起動時に古い画像を削除
        self._cleanup_old_images()

        # 永続実行用フラグ
        self.running = False
    
    def display_image(self, image_path):
        """
        画像をe-paperディスプレイに表示
        
        Args:
            image_path (str): 表示する画像のパス
            
        Returns:
            bool: 表示成功時True
        """
        try:
            print(f"画像を表示中: {image_path}")
            
            # ファイル存在チェック
            if not os.path.exists(image_path):
                print(f"❌ ファイルが見つかりません: {image_path}")
                return False
            
            print(f"ファイルサイズ: {os.path.getsize(image_path)} bytes")
            
            # 画像を開いて640x400にリサイズ
            img = Image.open(image_path)
            print(f"元の画像サイズ: {img.size}")
            img = img.resize((640, 400))
            print("画像リサイズ完了: 640x400")
            
            # e-paperに表示
            print("e-paperディスプレイに送信中...")
            self.inky_display.set_image(img)
            self.inky_display.show()
            
            print("✅ 画像表示完了")
            return True
            
        except Exception as e:
            print(f"❌ 画像表示エラー: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def generate_and_display(self, prompt, display_immediately=True):
        """
        画像を生成してe-paperに表示
        
        Args:
            prompt (str): 生成する画像の説明
            display_immediately (bool): 生成後すぐに表示するか
            
        Returns:
            str|None: 成功時は生成された画像のパス、失敗時はNone
        """
        print("=== AI Photo Frame - 画像生成と表示 ===")
        print(f"プロンプト: {prompt}")
        print()
        
        # 出力ファイル名を生成（日時付き）
        now = datetime.now()
        timestamp_str = now.strftime("%Y%m%d_%H%M%S")
        output_file = os.path.join(self.output_dir, f"ai_photo_{timestamp_str}.png")
        
        # 画像生成
        print("🎨 画像生成を開始...")
        success = self.generator.generate_image(prompt, output_file)
        
        if not success:
            print("❌ 画像生成に失敗しました")
            return None
        
        if display_immediately:
            print("\n📺 e-paperディスプレイに表示...")
            display_success = self.display_image(output_file)
            
            if display_success:
                print("\n🎉 AI Photo Frame処理完了！")
            else:
                print("\n⚠️ 画像生成は成功しましたが、表示に失敗しました")
        
        return output_file
    
    def display_existing_image(self, image_path):
        """
        既存の画像をe-paperに表示
        
        Args:
            image_path (str): 表示する画像のパス
        """
        print("=== AI Photo Frame - 既存画像表示 ===")
        
        if not os.path.exists(image_path):
            print(f"❌ ファイルが見つかりません: {image_path}")
            return False
        
        return self.display_image(image_path)

    def _cleanup_old_images(self):
        """
        古い画像を削除して最新10枚のみ保持
        """
        try:
            # generated_imagesディレクトリ内のai_photo_*.pngファイルを取得
            pattern = os.path.join(self.output_dir, "ai_photo_*.png")
            image_files = glob.glob(pattern)

            if len(image_files) <= 10:
                return

            # ファイルを更新日時でソート（古い順）
            image_files.sort(key=lambda x: os.path.getmtime(x))

            # 古いファイルを削除（最新10枚を残す）
            files_to_delete = image_files[:-10]
            deleted_count = 0

            for file_path in files_to_delete:
                try:
                    os.remove(file_path)
                    deleted_count += 1
                except OSError as e:
                    print(f"⚠️ ファイル削除エラー {file_path}: {e}")

            if deleted_count > 0:
                print(f"🗑️ 古い画像{deleted_count}枚を削除しました（最新10枚を保持）")

        except Exception as e:
            print(f"⚠️ 画像クリーンアップエラー: {e}")

    def list_generated_images(self):
        """
        生成された画像の一覧を表示
        """
        print("=== AI Photo Frame - 生成画像一覧 ===")

        pattern = os.path.join(self.output_dir, "ai_photo_*.png")
        image_files = glob.glob(pattern)

        if not image_files:
            print("生成された画像はありません")
            return

        # ファイルを更新日時でソート（新しい順）
        image_files.sort(key=lambda x: os.path.getmtime(x), reverse=True)

        print(f"保存場所: {self.output_dir}")
        print(f"画像数: {len(image_files)}枚\n")

        for i, file_path in enumerate(image_files, 1):
            filename = os.path.basename(file_path)
            file_size = os.path.getsize(file_path) / 1024  # KB
            mod_time = datetime.fromtimestamp(os.path.getmtime(file_path))

            print(f"{i:2d}. {filename}")
            print(f"    サイズ: {file_size:.1f} KB")
            print(f"    作成日時: {mod_time.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"    パス: {file_path}")
            print()

    def generate_only(self, prompt):
        """
        画像生成のみ（表示しない）

        Args:
            prompt (str): 生成する画像の説明

        Returns:
            str|None: 成功時は生成された画像のパス、失敗時はNone
        """
        return self.generate_and_display(prompt, display_immediately=False)

    def _load_config(self):
        """設定ファイルを読み込み"""
        config_path = os.path.join(os.path.dirname(__file__), "config.json")
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"⚠️ 設定ファイル読み込みエラー: {e}")
            # デフォルト設定を返す
            return {
                "continuous_mode": {
                    "enabled": True,
                    "prompts": [
                        "beautiful landscape, digital art",
                        "serene nature scene, photorealistic",
                        "abstract art, colorful patterns"
                    ]
                },
                "display": {"resolution": [640, 400], "border_color": "black"},
                "image": {"format": "png", "quality": 95, "max_stored": 10}
            }

    def _signal_handler(self, signum, frame):
        """シグナルハンドラー（Ctrl+C等での終了処理）"""
        print(f"\n🛑 シグナル {signum} を受信しました。終了処理中...")
        self.running = False

    def run_continuous(self):
        """永続実行モード - 表示完了後すぐに次の画像を生成し続ける"""
        if not self.config['continuous_mode']['enabled']:
            print("❌ 永続実行モードが無効化されています")
            return

        # シグナルハンドラーを設定
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

        prompts = self.config['continuous_mode']['prompts']

        print("=== AI Photo Frame - 連続実行モード開始 ===")
        print(f"プロンプト数: {len(prompts)}個")
        print("モード: 表示完了後すぐに次の生成を開始")
        print("終了するには Ctrl+C を押してください")
        print()

        self.running = True
        cycle_count = 0

        try:
            while self.running:
                cycle_count += 1
                print(f"\n🔄 サイクル {cycle_count} 開始 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

                # ランダムにプロンプトを選択
                prompt = random.choice(prompts)
                print(f"📝 選択されたプロンプト: '{prompt}'")

                # 画像生成と表示
                try:
                    result_path = self.generate_and_display(prompt)
                    if result_path:
                        print(f"✅ サイクル {cycle_count} 完了 - {datetime.now().strftime('%H:%M:%S')}")
                        print("⚡ すぐに次のサイクルを開始...")
                    else:
                        print(f"⚠️ サイクル {cycle_count} で画像生成に失敗")
                        print("⏰ 10秒待機してリトライします...")
                        time.sleep(10)  # エラー時は少し待機

                except Exception as e:
                    print(f"❌ サイクル {cycle_count} でエラー: {e}")
                    print("⏰ 30秒待機してリトライします...")
                    time.sleep(30)  # エラー時は長めに待機

                # 古い画像の自動削除実行（毎回）
                self._cleanup_old_images()

                # プロセス確認（メモリ不足等の確認）
                if cycle_count % 10 == 0:
                    print(f"📊 進行状況: {cycle_count}サイクル完了")

        except KeyboardInterrupt:
            print("\n🛑 キーボード割り込みを受信しました")
        finally:
            self.running = False
            print(f"\n🏁 AI Photo Frame連続実行モードを終了しました")
            print(f"📈 総サイクル数: {cycle_count}")
            print(f"⏱️  実行時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} に終了")

def main():
    """メイン関数 - コマンドライン引数で動作を制御"""
    if len(sys.argv) < 2:
        print("使用方法:")
        print("  python ai_photoframe.py generate \"プロンプト\"      # 画像生成して表示")
        print("  python ai_photoframe.py generate-only \"プロンプト\" # 画像生成のみ")
        print("  python ai_photoframe.py display image_path       # 既存画像を表示")
        print("  python ai_photoframe.py list                     # 生成画像一覧")
        print("  python ai_photoframe.py continuous               # 永続実行モード")
        print("\n例:")
        print("  python ai_photoframe.py generate \"beautiful mountain landscape\"")
        print("  python ai_photoframe.py display /path/to/image.jpg")
        print("  python ai_photoframe.py continuous")
        return

    command = sys.argv[1].lower()

    photoframe = AIPhotoFrame()

    if command == "generate":
        if len(sys.argv) < 3:
            print("❌ プロンプトを指定してください")
            return

        prompt = " ".join(sys.argv[2:])
        result_path = photoframe.generate_and_display(prompt)
        if result_path:
            print(f"\n📁 保存先: {result_path}")

    elif command == "generate-only":
        if len(sys.argv) < 3:
            print("❌ プロンプトを指定してください")
            return

        prompt = " ".join(sys.argv[2:])
        result_path = photoframe.generate_only(prompt)
        if result_path:
            print(f"\n📁 保存先: {result_path}")
            print(f"💡 表示するには: python ai_photoframe.py display \"{result_path}\"")

    elif command == "display":
        if len(sys.argv) < 3:
            print("❌ 画像パスを指定してください")
            return

        image_path = sys.argv[2]
        photoframe.display_existing_image(image_path)

    elif command == "list":
        photoframe.list_generated_images()

    elif command == "continuous":
        photoframe.run_continuous()

    else:
        print(f"❌ 不明なコマンド: {command}")
        print("使用可能なコマンド: generate, generate-only, display, list, continuous")

if __name__ == "__main__":
    main()