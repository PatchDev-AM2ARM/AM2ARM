"""Model selection for the shared TrimUI launcher and installer."""
import os
from pathlib import Path


DISPLAY_SIZES = {'brick': (1024, 768), 'smartpro': (1280, 720)}


def display_size(device=None):
    device = device or os.environ.get('AM2ARM_TRIMUI_DEVICE')
    try:
        return DISPLAY_SIZES[device]
    except KeyError:
        raise RuntimeError('Supported models: TrimUI Brick and original Smart Pro.') from None


def current_device(environ=None, mainui=Path('/usr/trimui/bin/MainUI'),
                   cmdline=Path('/proc/cmdline')):
    environ = os.environ if environ is None else environ
    if environ.get('AM2ARM_FRONTEND') != 'stock':
        if environ.get('PLATFORM') != 'tg5040':
            raise RuntimeError('This package requires NextUI on the tg5040 platform.')
        device = environ.get('DEVICE')
        if device not in DISPLAY_SIZES:
            raise RuntimeError('Supported models: TrimUI Brick and original Smart Pro.')
        return device

    # NextUI identifies these stock firmware models from the same MainUI text.
    data = Path(mainui).read_bytes()
    if b'Trimui Smart Pro S\0' in data or b'Trimui Brick Pro\0' in data:
        raise RuntimeError('This TrimUI model has not been verified with this package.')
    found = [device for device, label in (
        ('brick', b'Trimui Brick\0'), ('smartpro', b'Trimui Smart Pro\0')) if label in data]
    if len(found) == 1:
        return found[0]
    # Retain the original Brick identification for older firmware images.
    if not found and 'lcd=jd9168' in Path(cmdline).read_text().split():
        return 'brick'
    raise RuntimeError('Could not identify a supported TrimUI model. Please send the logs folder.')
