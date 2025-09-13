#!/usr/bin/env python3
"""
AI Photo Frame - Image Generator
FastSD CPUベースの640x400画像生成機能
"""

from diffusers import StableDiffusionPipeline
import torch
from time import time
import os
from PIL import Image
import sys

class ImageGenerator:
    def __init__(self):
        self.pipe = None
        self.model_loaded = False
        
    def load_model(self):
        """Stable Diffusionモデルを読み込み"""
        if self.model_loaded:
            return True
            
        try:
            print("Stable Diffusionモデルを読み込み中...")
            print("初回実行時はモデルのダウンロードに時間がかかります")
            
            # 軽量なモデルを使用
            model_id = "stabilityai/stable-diffusion-2-1-base"
            
            # CPU最適化設定でパイプラインを読み込み
            self.pipe = StableDiffusionPipeline.from_pretrained(
                model_id,
                torch_dtype=torch.float32,  # CPU互換性のためfloat32使用
                safety_checker=None,        # 高速化のため安全チェッカーを無効
                requires_safety_checker=False,
            )
            self.pipe = self.pipe.to("cpu")
            
            # メモリ効率の最適化
            self.pipe.enable_attention_slicing()
            
            self.model_loaded = True
            print("✅ モデル読み込み完了！")
            return True
            
        except Exception as e:
            print(f"❌ モデル読み込みエラー: {e}")
            return False
    
    def generate_image(self, prompt, output_path="generated_image.png", callback=None):
        """
        画像を生成して保存

        Args:
            prompt (str): 生成する画像の説明
            output_path (str): 保存先パス
            callback (callable): 進行状況コールバック関数

        Returns:
            bool: 生成成功時True
        """
        if not self.model_loaded:
            if not self.load_model():
                return False
        
        try:
            print(f"画像生成中: '{prompt}'")
            print("Raspberry Pi CPUでは10-15分程度かかります...")

            # コールバック関数を定義
            def step_callback(step, timestep, latents):
                if callback:
                    callback(step, 20)  # 現在のstep、総step数
                return {}

            # 640x400サイズで画像生成
            start_time = time()
            image = self.pipe(
                prompt,
                num_inference_steps=20,      # バランスの取れたステップ数
                guidance_scale=7.5,
                height=400,                  # e-paperサイズに合わせて調整
                width=640,
                callback=step_callback,
                callback_steps=1,            # 毎ステップでコールバック実行
            ).images[0]
            end_time = time()
            
            # 画像保存
            image.save(output_path)
            
            duration = end_time - start_time
            print(f"🎉 画像生成成功！")
            print(f"⏱️  生成時間: {duration:.1f}秒 ({duration/60:.1f}分)")
            print(f"🖼️  保存先: {os.path.abspath(output_path)}")
            
            return True
            
        except Exception as e:
            print(f"❌ 画像生成エラー: {e}")
            import traceback
            traceback.print_exc()
            return False

def main():
    """テスト実行用のメイン関数"""
    print("=== AI Photo Frame - Image Generator Test ===")
    
    generator = ImageGenerator()
    
    # テスト用プロンプト
    test_prompts = [
        "a beautiful sunset over mountains, digital art",
        "a serene forest with morning mist, photorealistic",
        "abstract geometric patterns in blue and gold"
    ]
    
    for i, prompt in enumerate(test_prompts):
        output_file = f"test_output_{i+1}.png"
        success = generator.generate_image(prompt, output_file)
        
        if success:
            print(f"✅ テスト {i+1} 成功: {output_file}")
        else:
            print(f"❌ テスト {i+1} 失敗")
            break
        print("-" * 50)

if __name__ == "__main__":
    main()