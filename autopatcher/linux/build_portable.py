"""Build the desktop Linux Autopatcher with its verified decoder and payloads."""
from pathlib import Path
import shutil
import subprocess
import sys

source = Path(__file__).resolve().parent
output = Path(sys.argv[1]).resolve()
command = [sys.executable, '-m', 'PyInstaller', '--noconfirm', '--clean', '--onedir',
           '--windowed', '--name', 'AM2ARM-Linux-Autopatcher', '--distpath', str(output / 'dist'),
           '--workpath', str(output / 'work'), '--specpath', str(output), str(source / 'linux_patcher.py')]
if sys.platform.startswith('linux'):
    from PyInstaller.depend.bindepend import resolve_library_path
    for name in ('libxcb.so.1', 'libfontconfig.so.1'):
        library = resolve_library_path(name)
        if library:
            command.extend(['--add-binary', library + ':.'])
subprocess.run(command, check=True)
app = output / 'dist/AM2ARM-Linux-Autopatcher'
for directory in ('assets', 'vendor', 'patch-bundle', 'licenses'):
    shutil.copytree(source / directory, app / directory, dirs_exist_ok=True)
for name in ('README.txt', 'LICENSE'):
    shutil.copy2(source / name, app / name)
print('Desktop application built:', app, flush=True)
