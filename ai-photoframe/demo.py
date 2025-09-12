from PIL import Image
from inky.inky_uc8159 import Inky
import os

img = Image.open("/home/pi/fastsdcpu-project/fastsdcpu-stable/test_output.png")
img= img.resize((640, 400))


# Set up the Inky display
inky_display = Inky(resolution=(640, 400), cs_pin=8, dc_pin=25, reset_pin=17, busy_pin=24)
inky_display.set_border(inky_display.BLACK)

inky_display.set_image(img)
inky_display.show()