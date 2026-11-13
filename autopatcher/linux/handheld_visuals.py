"""Title artwork and flat, pixel-lettered controls for the handheld installer."""
import math
import tkinter as tk

BG, FG, ACCENT = '#000000', '#ffffff', '#ffffff'
STYLES = {'normal': '', 'focused': '#4b4b4b',
          'selected': '#282828', 'pressed': '#707070'}


def pixel_font(font, scale):
    unit = 13 if font[0] == 'Extended Acknowledge TT BRK' else 8
    pixels = unit * max(1, math.floor(abs(font[1]) * scale / unit + .5))
    return font[0], -pixels


def faded_image(master, png, alpha):
    return tk.PhotoImage(master=master, data=png, format=('png', '-alpha', alpha))


def image_png(image):
    return image.tk.call(str(image), 'data', '-format', 'png')


def scaled_planet(image, width, height):
    """Nearest-neighbour scaling, including fractional display scales."""
    if width % image.width() == 0 and height % image.height() == 0:
        return image.zoom(width // image.width(), height // image.height())
    # The planet is opaque. PPM avoids adding an imaging-library dependency.
    ppm = image.tk.call(str(image), 'data', '-format', 'ppm')
    header, dimensions, maximum, pixels = ppm.split(b'\n', 3)
    if header != b'P6' or maximum != b'255':
        raise ValueError('Unsupported planet image format')
    source_width, source_height = map(int, dimensions.split())
    offsets = [min(source_width-1, int((x+.5)*source_width/width))*3
               for x in range(width)]
    rows, cache = [], {}
    for y in range(height):
        source_y = min(source_height-1, int((y+.5)*source_height/height))
        if source_y not in cache:
            row = pixels[source_y*source_width*3:(source_y+1)*source_width*3]
            cache[source_y] = b''.join(row[x:x+3] for x in offsets)
        rows.append(cache[source_y])
    data = f'P6\n{width} {height}\n255\n'.encode() + b''.join(rows)
    return tk.PhotoImage(master=image.tk, data=data, format='PPM')


def blit(destination, source, x, y):
    left, top = max(0, x), max(0, y)
    right = min(destination.width(), x + source.width())
    bottom = min(destination.height(), y + source.height())
    if right > left and bottom > top:
        destination.tk.call(str(destination), 'copy', str(source),
                            '-from', left-x, top-y, right-x, bottom-y,
                            '-to', left, top)


class Backdrop:
    def __init__(self, canvas, assets):
        self.canvas = canvas
        self.original = tk.PhotoImage(master=canvas, file=str(assets / 'title-background.png'))
        self.original_logo = tk.PhotoImage(master=canvas, file=str(assets / 'am2arm-banner.png'))
        self.star_item = canvas.create_image(0, 0, anchor='nw')
        self.dark_item = canvas.create_image(0, 0, anchor='nw', state='hidden')
        self.logo_item = canvas.create_image(0, 0, anchor='nw')
        self.cover_item = canvas.create_image(0, 0, anchor='nw', state='hidden')
        pixel = tk.PhotoImage(master=canvas, width=1, height=1)
        pixel.put(BG)
        self.black_png = image_png(pixel)
        self.size = self.cover_key = self.dark_key = self.logo_key = None

    def resize(self, width, height):
        if self.size == (width, height):
            return
        self.size = width, height
        scale = height / 240
        self.stars = scaled_planet(self.original, round(self.original.width()*scale),
                                  round(self.original.height()*scale))
        self.star_x = (width-self.stars.width()) // 2
        self.star_y = min(0, height-self.stars.height())
        self.canvas.itemconfigure(self.star_item, image=self.stars)
        ui_scale = min(height/480, width/640)
        origin = (height-480*ui_scale)/2
        # Whole-pixel reduction preserves the supplied high-resolution banner.
        divisor = max(1, math.ceil(max(self.original_logo.width()/(width*.84),
                                       self.original_logo.height()/(132*ui_scale))))
        self.logo = self.original_logo.subsample(divisor)
        self.logo_png = image_png(self.logo)
        self.canvas.coords(self.logo_item, (width-self.logo.width())//2, round(origin+20*ui_scale))
        self.canvas.itemconfigure(self.logo_item, image=self.logo)
        self.final = tk.PhotoImage(master=self.canvas, width=width, height=height)
        self.final.put(BG, to=(0, 0, width, height))
        blit(self.final, self.stars, self.star_x, self.star_y)
        self.shade = faded_image(self.canvas, self.black_png, .5).zoom(width, height)
        blit(self.final, self.shade, 0, 0)
        self.cover_y = round(origin+156*ui_scale)
        self.cover_png = self.final.tk.call(str(self.final), 'data', '-format', 'png',
                                            '-from', 0, self.cover_y, width, height)
        self.canvas.coords(self.cover_item, 0, self.cover_y)
        self.cover_key = self.dark_key = self.logo_key = None

    def slide(self, progress, background_alpha=1, logo_alpha=1):
        if self.size is None:
            return
        self.canvas.coords(self.star_item, self.star_x, round(self.star_y*progress))
        dark_key = round((1-background_alpha*.5)*16)
        if dark_key != self.dark_key:
            self.dark_key = dark_key
            if dark_key:
                self.dark = faded_image(self.canvas, self.black_png, dark_key/16).zoom(*self.size)
                self.canvas.itemconfigure(self.dark_item, image=self.dark, state='normal')
            else:
                self.canvas.itemconfigure(self.dark_item, state='hidden', image='')
                self.dark = None
        logo_key = round(logo_alpha*16)
        if logo_key != self.logo_key:
            self.logo_key = logo_key
            self.logo_fade = self.logo if logo_key == 16 else faded_image(self.canvas, self.logo_png, logo_key/16)
            self.canvas.itemconfigure(self.logo_item, image=self.logo_fade)

    def fade_menu(self, progress):
        if progress <= 0 or progress >= 1:
            self.canvas.itemconfigure(self.cover_item, state='hidden', image='')
            self.cover = None
            self.cover_key = None
            return
        key = round((1-progress)*16)
        if key != self.cover_key:
            self.cover = faded_image(self.canvas, self.cover_png, key/16)
            self.cover_key = key
            self.canvas.itemconfigure(self.cover_item, image=self.cover)
        self.canvas.itemconfigure(self.cover_item, state='normal')
        self.canvas.tag_raise(self.cover_item)


class CanvasButton:
    def __init__(self, canvas, text, command, font):
        self.canvas, self.command, self.font = canvas, command, font
        self.state, self.style, self.visible = 'normal', 'normal', True
        self.text = text
        self.border_item = canvas.create_rectangle(0, 0, 1, 1, outline='', tags='menu')
        self.text_item = canvas.create_text(0, 0, text=text, font=font, fill=FG, anchor='w', tags='menu')
        self.bounds = (0, 0, 1, 1)

    def configure(self, **values):
        self.state = values.get('state', self.state)
        self.style = values.get('style', self.style)
        self.text = values.get('text', self.text)
        self.paint()

    def position(self, x, y, width, height, font, visible=True):
        self.bounds = x, y, width, height
        self.font, self.visible = font, visible
        self.paint()

    def paint(self):
        x, y, width, height = self.bounds
        self.canvas.coords(self.border_item, x, y, x+width, y+height)
        self.canvas.itemconfigure(self.border_item, fill=STYLES[self.style])
        self.canvas.coords(self.text_item, x+max(8, round(height/4)), y+height/2)
        self.canvas.itemconfigure(self.text_item, text=self.text, font=self.font,
                                  fill='#787878' if self.state == 'disabled' else FG)
        self.set_visible(self.visible)

    def set_visible(self, visible):
        self.visible = visible
        for item in (self.border_item, self.text_item):
            self.canvas.itemconfigure(item, state='normal' if visible else 'hidden')

    def contains(self, x, y):
        left, top, width, height = self.bounds
        return self.visible and left <= x < left+width and top <= y < top+height

    def invoke(self):
        if self.state != 'disabled' and self.visible:
            self.command()
