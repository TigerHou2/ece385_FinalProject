from PIL import Image
from collections import Counter
from scipy.spatial import KDTree
# import numpy as np


def hex_to_rgb(num):
    h = str(num)
    return int(h[0:4], 16), int(('0x' + h[4:6]), 16), int(('0x' + h[6:8]), 16)


def rgb_to_hex(num):
    h = str(num)
    return int(h[0:4], 16), int(('0x' + h[4:6]), 16), int(('0x' + h[6:8]), 16)


filename = input("What's the image name? ")
new_w, new_h = map(int, input("What's the new width x height? Like 28 28. ").split(' '))
palette_hex = ['0x24415D', '0xBC7284', '0xF8B293', '0x525575', '0xF9CD95', '0xEF7580',  # map 1 colors
               '0x035852', '0x2FBDA1', '0x9BE0BE', '0x06847F', '0x62D7B6', '0xDDECCF',  # map 2 colors
               '0x252033', '0x5F4F71', '0x9D728F', '0x342845', '0x7A5E7E', '0x443D5D',  # map 3 colors
               '0x000000', '0x555555', '0xBBBBBB', '0xFFFFFF', '0x844731', '0x987632',  # common colors
               '0x0055AA', '0x4E89C4', '0xBA3420', '0xEF5953',  # team colors
               '0x231F20', '0xEB1A27', '0xF1EB30', '0xFBAF3A'   # bomb colors
               ]
palette_rgb = [hex_to_rgb(color) for color in palette_hex]

pixel_tree = KDTree(palette_rgb)
im = Image.open("../sprite_originals/" + filename + ".png")  # Can be many different formats.
im = im.convert("RGBA")
layer = Image.new('RGBA', (new_w, new_h), (0, 0, 0, 0))
layer.paste(im, (0, 0))
im = layer
# im = im.resize((new_w, new_h),Image.ANTIALIAS) # regular resize
pix = im.load()
pix_freqs = Counter([pix[x, y] for x in range(im.size[0]) for y in range(im.size[1])])
pix_freqs_sorted = sorted(pix_freqs.items(), key=lambda x: x[1])
pix_freqs_sorted.reverse()
print(pix)
outImg = Image.new('RGB', im.size, color='white')
outFile = open("../sprite_bytes/" + filename + '.txt', 'w')
i = 0
for y in range(im.size[1]):
    for x in range(im.size[0]):
        pixel = im.getpixel((x, y))
        print(pixel)
        if pixel[3] < 200:
            outImg.putpixel((x, y), palette_rgb[0])
            outFile.write("%s\n" % bin(0)[2:].zfill(5))
            print(i)
        else:
            index = pixel_tree.query(pixel[:3])[1]
            outImg.putpixel((x, y), palette_rgb[index])
            outFile.write("%s\n" % bin(index)[2:].zfill(5))
        i += 1
outFile.close()
outImg.save("../sprite_converted/" + filename + ".png")
