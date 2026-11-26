"""Touch and controller interface for installing AM2ARM on the handheld."""
import argparse
import os
from pathlib import Path
import queue
import threading
import time
import tkinter as tk

from handheld_input import Controller
from handheld_sound import MenuSound
from handheld_visuals import Backdrop, CanvasButton, load_fonts, pixel_font
from patch_core import base_dir

BG, PANEL, FG, ACCENT = '#000000', '#151515', '#ffffff', '#ffffff'


class HandheldWindow:
    def __init__(self, root, library, size=None):
        self.root, self.library = root, library
        self.source = library.original()
        self.busy = self.closed = self.play = False
        self.messages = queue.Queue()
        self.controller = Controller()
        self.sound = MenuSound(base_dir() / 'assets/menu_move.wav')
        self.picker = None
        self.notice = None
        self.focus_index = 0
        self.buttons, self.button_windows = [], []
        self.pressed = None
        self.poll_id = self.intro_id = None
        self.intro_active = True
        self.slide_progress = self.menu_progress = self.background_alpha = self.logo_alpha = 0
        self.width, self.height = size or ((root.winfo_screenwidth(), root.winfo_screenheight())
            if os.environ.get('AM2R_PATCHER_FULLSCREEN') == '1' else (640, 480))
        self.progress_value, self.pulse = 0, 0
        assets = base_dir() / 'assets'
        load_fonts(assets)
        self.font = ('uni 05_53', -16)
        self.menu_font = ('Extended Acknowledge TT BRK', -26)
        root.title('AM2ARM Autopatcher')
        root.geometry(f'{self.width}x{self.height}+0+0')
        root.minsize(640, 480)
        root.protocol('WM_DELETE_WINDOW', self.close)
        self.canvas = tk.Canvas(root, width=self.width, height=self.height, bg=BG, highlightthickness=0)
        self.canvas.pack(fill='both', expand=True)
        self.background = Backdrop(self.canvas, assets)
        self.labels = []
        self.subtitle = self.text('AUTOPATCHER  ' + library.version, 162, self.font)
        self.help = self.text('Needs your original AM2R 1.1 for Windows', 266, self.font, '#bfbfbf')
        self.choose = self.button('CHOOSE AM2R 1.1 ZIP', self.browse, 298)
        self.meter = self.canvas.create_rectangle(16, 0, 360, 8, fill='#333333', width=0, tags='menu')
        self.fill = self.canvas.create_rectangle(16, 0, 16, 8, fill=ACCENT, width=0, tags='menu')
        self.status = tk.StringVar(value='Select your original Windows 1.1 ZIP.\nYour source file stays unchanged.')
        self.status_item = self.text(self.status.get().partition('\n')[0], 416, self.font, tags='status')
        self.status.trace_add('write', lambda *_: self.canvas.itemconfigure(self.status_item, text=self.status.get().partition('\n')[0]))
        self.canvas.create_text(16, 464, text='A: Select   B: Exit', font=self.font, fill='#bfbfbf', anchor='sw', tags=('menu', 'controls'))
        self.canvas.create_text(624, 464, text='github.com/PatchDev-AM2ARM/AM2ARM', font=('uni 05_53', -8), fill=FG, anchor='se', tags=('menu', 'project-url'))
        self.canvas.bind('<Configure>', self.resize)
        self.canvas.bind('<ButtonPress-1>', self.pointer_down)
        self.canvas.bind('<ButtonRelease-1>', self.pointer_up)
        self.layout()
        for key, action in [('Up', 'up'), ('Down', 'down'), ('Left', 'left'), ('Right', 'right'),
                            ('Return', 'accept'), ('Escape', 'back'), ('F5', 'finish')]:
            root.bind('<' + key + '>', lambda event, value=action: self.action(value))
        root.after_idle(root.focus_force)
        self.intro_id = root.after_idle(self.start_intro)
        self.poll_id = root.after(50, self.poll)

    def text(self, text, y, font, color=FG, tags=()):
        item = self.canvas.create_text(16, 0, text=text, font=font, fill=color, width=344,
                                       anchor='nw', justify='left', tags=('menu', *([tags] if isinstance(tags, str) else tags)))
        self.labels.append((item, y, font))
        return item

    def button(self, text, command, y, width=344, x=16):
        button = CanvasButton(self.canvas, text, lambda: self.activate(command), self.menu_font)
        self.buttons.append(button)
        self.button_windows.append((button, x, y, width))
        return button

    def resize(self, event):
        if event.width > 1 and event.height > 1:
            self.width, self.height = event.width, event.height
            self.layout()

    def layout(self):
        self.scale = min(self.height / 480, self.width / 640)
        self.content_width = round(min(self.width-32*self.scale, 464*self.scale))
        self.left = round((self.width-self.content_width)/2)
        self.right = self.left+self.content_width
        self.content_width = self.right - self.left
        self.origin = max(4*self.scale, (self.height - 472*self.scale)/2)
        self.background.resize(self.width, self.height)
        for item, y, font in self.labels:
            self.canvas.coords(item, self.left, round(self.origin + y*self.scale))
            self.canvas.itemconfigure(item, width=self.content_width, font=pixel_font(font, self.scale))
        for button, _, y, _ in self.button_windows:
            button.position(self.left, round(self.origin+y*self.scale), self.content_width, round(30*self.scale),
                pixel_font(self.menu_font, self.scale), visible=True)
        self.canvas.coords(self.meter, self.left, round(self.origin + 404*self.scale),
                            self.right, round(self.origin + 409*self.scale))
        self.canvas.coords('controls', round(16*self.scale), self.height-round(12*self.scale))
        self.canvas.coords('project-url', self.width-round(16*self.scale), self.height-round(12*self.scale))
        self.canvas.itemconfigure('controls', font=pixel_font(self.font, self.scale))
        self.canvas.itemconfigure('project-url', font=pixel_font(self.font, self.scale))
        self.canvas.coords(self.subtitle, self.width/2, round(self.origin+162*self.scale))
        self.canvas.itemconfigure(self.subtitle, anchor='n', justify='center')
        self.draw_progress()
        self.highlight()
        self.render_intro()

    def highlight(self):
        for index, button in enumerate(self.buttons):
            state = 'normal'
            if index == self.focus_index:
                state = 'focused'
            if index == self.pressed:
                state = 'pressed'
            button.configure(style=state)

    def browse(self):
        if not self.busy:
            start = self.source.parent if self.source else self.library.card
            self.picker = FilePicker(self.root, start, self.picked, self.beep)

    def beep(self):
        if not self.intro_active and not self.busy and self.root.focus_displayof() is not None:
            self.sound.play()

    def activate(self, command):
        if self.intro_active:
            self.finish_intro()
        elif not self.busy:
            self.beep()
            command()

    def pointer_down(self, event):
        if self.busy or self.intro_active:
            return
        self.pressed = next((i for i,b in enumerate(self.buttons) if b.contains(event.x, event.y)), None)
        self.highlight()

    def pointer_up(self, event):
        if self.intro_active:
            self.finish_intro()
            return
        index, self.pressed = self.pressed, None
        self.highlight()
        if self.busy:
            return
        if index is not None and self.buttons[index].contains(event.x, event.y):
            self.focus_index = index
            self.buttons[index].invoke()

    def start_intro(self):
        self.intro_start = time.monotonic()
        self.animate_intro()

    def animate_intro(self):
        if not self.intro_active or self.closed:
            return
        elapsed = time.monotonic()-self.intro_start
        progress = min(1, elapsed/1.2)
        self.slide_progress = 1-(1-min(1,elapsed/.85))**3
        self.background_alpha = min(1, elapsed/.3)
        self.logo_alpha = max(0, min(1, (elapsed-.5)/.45))
        self.menu_progress = max(0, min(1, (elapsed-.85)/.35))
        if progress >= 1:
            self.finish_intro()
        else:
            self.render_intro()
            self.intro_id = self.root.after(16, self.animate_intro)

    def render_intro(self):
        self.background.slide(self.slide_progress, self.background_alpha, self.logo_alpha)
        self.canvas.itemconfigure('menu', state='normal' if self.menu_progress > 0 else 'hidden')
        self.background.fade_menu(self.menu_progress)

    def finish_intro(self):
        if self.intro_id is not None:
            self.root.after_cancel(self.intro_id)
            self.intro_id = None
        first, self.intro_active = self.intro_active, False
        self.slide_progress = self.menu_progress = self.background_alpha = self.logo_alpha = 1
        self.render_intro()
        if first:
            self.begin()

    def picked(self, path):
        self.picker = None
        if path is not None:
            self.source = path
            self.begin()
        else:
            self.status.set('Select your original Windows AM2R 1.1 ZIP.')

    def begin(self):
        if self.busy:
            return
        if self.source is None:
            self.browse()
            return
        self.busy = True
        for button in self.buttons:
            button.configure(state='disabled')
        self.progress_value = None
        self.status.set('Checking your original game…')
        source = self.source

        def work():
            try:
                self.library.install(source, lambda done, total, text: self.messages.put(('progress', done, total, text)))
                self.messages.put(('done',))
            except Exception as error:
                self.messages.put(('error', str(error)))
        threading.Thread(target=work, daemon=True).start()

    def action(self, action):
        if self.busy:
            return
        if self.intro_active:
            self.finish_intro()
            return
        if self.notice is not None:
            self.notice.action(action)
        elif self.picker is not None:
            self.picker.action(action)
        elif action in ('accept', 'finish'):
            self.buttons[self.focus_index].invoke()
        elif action == 'back':
            self.request_exit()

    def request_exit(self):
        if not self.busy:
            self.notice = Notice(self.root, 'EXIT INSTALLER?',
                'Return to the system menu?\n\nYour original ZIP and saves stay on the card.',
                self.stay, exit_action=self.close)

    def draw_progress(self):
        start = 0
        if self.progress_value is None:
            self.pulse = (self.pulse + 6*self.scale) % self.content_width
            start, end = self.pulse, min(self.content_width, self.pulse + 70*self.scale)
        else:
            end = round(self.content_width * max(0, min(100, self.progress_value)) / 100)
        self.canvas.coords(self.fill, self.left+start, round(self.origin+404*self.scale),
                            self.left+end, round(self.origin+409*self.scale))

    def poll(self):
        for action in self.controller.poll():
            self.action(action)
            if self.closed:
                return
        latest = None
        while True:
            try:
                message = self.messages.get_nowait()
            except queue.Empty:
                break
            if message[0] == 'progress':
                latest = message
                continue
            latest = None
            self.busy = False
            self.progress_value = 100 if message[0] == 'done' else 0
            for button in self.buttons:
                button.configure(state='normal')
            if message[0] == 'done':
                self.play = True
                self.close()
                return
            self.status.set('Installation stopped.')
            self.notice = Notice(self.root, 'INSTALLATION STOPPED', message[1], self.dismiss_notice)
            print('Installation failed:', message[1], flush=True)
        if latest:
            _, done, total, text = latest
            self.progress_value = done * 100 / total if total > 1 else None
            self.status.set(text)
        if self.busy or latest:
            self.draw_progress()
        self.poll_id = self.root.after(50, self.poll)

    def stay(self):
        self.notice = None

    def dismiss_notice(self):
        self.notice = None
        self.source = None
        self.status.set('Select your original Windows AM2R 1.1 ZIP.')

    def close(self):
        if not self.busy:
            self.closed = True
            for callback in (self.poll_id, self.intro_id):
                if callback is not None:
                    self.root.after_cancel(callback)
            self.controller.close()
            self.sound.close()
            self.root.destroy()


class Notice:
    def __init__(self, root, title, message, callback, exit_action=None):
        self.callback = callback
        self.exit_action = exit_action
        self.frame = tk.Frame(root, bg=BG)
        self.frame.place(x=0, y=0, relwidth=1, relheight=1)
        scale = root.winfo_height() / 480
        tk.Label(self.frame, text=title, bg=BG, fg=ACCENT,
                 font=pixel_font(('uni 05_53', -22), scale)).pack(pady=round(18*scale))
        self.body = tk.Text(self.frame, bg=PANEL, fg=FG, wrap='word', borderwidth=0,
                            font=pixel_font(('uni 05_53', -20), scale), takefocus=False)
        self.body.insert('1.0', message)
        self.body.configure(state='disabled')
        tk.Button(self.frame, text='A: EXIT / B: STAY' if exit_action else 'A / B: CLOSE',
                  bg=PANEL, fg=FG, command=exit_action or self.close,
                  font=pixel_font(('uni 05_53', -20), scale)).pack(side='bottom', pady=round(16*scale))
        tk.Label(self.frame, text='D-pad: Scroll', bg=BG, fg=FG,
                 font=pixel_font(('uni 05_53', -16), scale)).pack(side='bottom')
        self.body.pack(fill='both', expand=True, padx=round(18*scale), pady=round(8*scale))

    def close(self):
        self.frame.destroy()
        self.callback()

    def action(self, action):
        if action in ('accept', 'finish') and self.exit_action:
            self.exit_action()
        elif action in ('accept', 'back', 'finish'):
            self.close()
        elif action in ('up', 'down', 'left', 'right'):
            self.body.yview_scroll(-1 if action in ('up', 'left') else 1,
                                   'pages' if action in ('left', 'right') else 'units')


class FilePicker:
    def __init__(self, root, start, callback, beep=lambda: None):
        self.callback = callback
        self.beep = beep
        self.path = start if start.is_dir() else Path.cwd()
        self.frame = tk.Frame(root, bg=BG)
        self.frame.place(x=0, y=0, relwidth=1, relheight=1)
        self.heading = tk.Label(self.frame, text='', bg=BG, fg=ACCENT,
                                font=('uni 05_53', -16), anchor='nw', justify='left')
        self.heading.place(x=12, y=8, width=616, height=52)
        self.items = tk.Listbox(self.frame, font=('uni 05_53', -24), bg=PANEL, fg=FG,
                                selectbackground='#4b4b4b', selectforeground='white',
                                activestyle='none', highlightthickness=0, height=10, exportselection=False)
        self.items.place(x=12, y=66, width=616, height=318)
        self.items.bind('<Double-Button-1>', lambda _: self.open())
        self.bar = tk.Frame(self.frame, bg=BG)
        self.bar.place(x=8, y=390, width=624, height=46)
        for text, command in [('BACK', self.back), ('UP', self.parent), ('OPEN', self.open)]:
            self.button(self.bar, text, command)
        self.footer = tk.Label(self.frame, text='A: Open   B: Back   L1: Up',
                 bg=BG, fg=FG, font=('uni 05_53', -16))
        self.frame.bind('<Configure>', self.layout)
        self.refresh()

    def layout(self, event):
        if event.widget != self.frame:
            return
        width, height = event.width, event.height
        scale = min(height / 480, width / 640)
        pad = round(12*scale)
        self.heading.place(x=pad, y=round(8*scale), width=width-pad*2, height=round(52*scale))
        self.heading.configure(font=pixel_font(('uni 05_53', -16), scale))
        self.items.place(x=pad, y=round(66*scale), width=width-pad*2, height=round(height-162*scale))
        self.items.configure(font=pixel_font(('uni 05_53', -24), scale))
        self.bar.place(x=pad, y=round(height-90*scale), width=width-pad*2, height=round(46*scale))
        for button in self.bar.winfo_children():
            button.configure(font=pixel_font(('Extended Acknowledge TT BRK', -22), scale))
        self.footer.place(x=pad, y=round(height-36*scale), width=width-pad*2, height=round(28*scale))
        self.footer.configure(font=pixel_font(('uni 05_53', -16), scale))

    def button(self, parent, text, command):
        tk.Button(parent, text=text, command=lambda: (self.beep(), command()), font=('Extended Acknowledge TT BRK', -22),
                  bg=PANEL, fg=FG, activebackground='#4b4b4b', activeforeground='white',
                  padx=8, pady=10, relief='flat').pack(side='left', fill='x', expand=True, padx=3)

    def refresh(self):
        location = str(self.path)
        if len(location) > 58:
            location = '…' + location[-57:]
        self.heading.configure(text='Choose original AM2R 1.1 ZIP\n' + location)
        self.items.delete(0, 'end')
        self.entries = []
        if self.path.parent != self.path:
            self.entries.append(self.path.parent)
            self.items.insert('end', '[..] Parent folder')
        try:
            children = sorted([p for p in self.path.iterdir() if not p.name.startswith('.') and
                    (p.is_dir() or p.suffix.lower() == '.zip')],
                    key=lambda p: (not p.is_dir(), p.name.casefold()))
        except OSError as error:
            children = []
            self.heading.configure(text=str(error))
        for entry in children:
            self.entries.append(entry)
            self.items.insert('end', ('[DIR] ' if entry.is_dir() else '') + entry.name)
        if self.entries:
            self.items.selection_set(0)

    def parent(self):
        self.path = self.path.parent
        self.refresh()

    def back(self):
        self.finish(None)

    def finish(self, path):
        self.frame.destroy()
        self.callback(path)

    def open(self):
        selected = self.items.curselection()
        if not selected:
            return
        path = self.entries[selected[0]]
        if path.is_dir():
            self.path = path
            self.refresh()
        else:
            self.finish(path)

    def action(self, action):
        self.beep()
        if action == 'previous':
            self.parent()
        elif action in ('up', 'down', 'left', 'right', 'next') and self.entries:
            amount = {'up': -1, 'down': 1, 'left': -8, 'right': 8, 'previous': -8, 'next': 8}[action]
            current = self.items.curselection()
            index = max(0, min(len(self.entries) - 1, (current[0] if current else 0) + amount))
            self.items.selection_clear(0, 'end')
            self.items.selection_set(index)
            self.items.see(index)
        elif action == 'accept':
            self.open()
        elif action == 'back':
            self.back()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--size', help='Desktop preview window, for example 1280x720')
    args = parser.parse_args()
    size = None
    if args.size:
        try:
            width, height = map(int, args.size.lower().split('x'))
            if not 640 <= width <= 3840 or not 480 <= height <= 2160:
                raise ValueError()
            size = width, height
        except ValueError:
            parser.error('--size must be WIDTHxHEIGHT, at least 640x480 and at most 3840x2160')
    from first_run import Library
    root = tk.Tk()
    window = HandheldWindow(root, Library.from_environment(), size)
    root.mainloop()
    return 0 if window.play else 2


if __name__ == '__main__':
    raise SystemExit(main())
