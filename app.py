import os
from diffusers import StableDiffusionPipeline
from PIL import Image, ImageDraw, ImageFont, ImageOps
from inky.inky_uc8159 import Inky
import datetime
import random
import json
import os


filename = os.path.dirname(os.path.realpath(__file__)) + "/prompt.json"
prompt_json = open(filename , "r")
prompt_list = json.load(prompt_json)
print(prompt_list)

prompt = random.choice(prompt_list)
print(prompt)

# generate img
pipe = StableDiffusionPipeline.from_pretrained("/home/pi/stable-diffusion-v1-5", low_cpu_mem_usage=True)
pipe = pipe.to("cpu")

img = pipe(prompt, num_inference_steps=31, width=640, height=400).images[0]

# save img
dt_now = datetime.datetime.now()
str_date = dt_now.strftime('%Y%m%d%H%M%S')
disp_date = dt_now.strftime('%a, %d %b %Y %H:%M:%S')
photo_filename = "/home/pi/AiPhotos/" + str_date + ".png"
img.save(photo_filename)


# Set up the Inky display
inky_display = Inky(resolution=(640, 400), cs_pin=8, dc_pin=25, reset_pin=17, busy_pin=24)
inky_display.set_border(inky_display.BLACK)

# draw text
draw = ImageDraw.Draw(img)
font = ImageFont.truetype('/home/pi/font/MPLUSRounded1c-Bold.ttf', 18, encoding='unic')
draw.text((8, 390), 'Drawn at ' + disp_date + '\n' + prompt, fill='white', stroke_width=2, stroke_fill='black', font=font, anchor='ld')

# flip and mirror
#img = ImageOps.flip(img)
#img = ImageOps.mirror(img)

inky_display.set_image(img)
inky_display.show()
