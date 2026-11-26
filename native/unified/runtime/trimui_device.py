"""Model selection for the shared TrimUI launcher and installer."""
from contextlib import contextmanager
import os
from pathlib import Path


from compat_display import identify, read

DISPLAY_SIZES = {'brick': (1024, 768), 'smartpro': (1280, 720), 'smartpros': (1280, 720),
                 'flip': (640, 480), 'g350': (640, 480), 'rg351p': (480, 320)}


def display_size(device=None):
    device = device or os.environ.get('AM2ARM_TRIMUI_DEVICE')
    try:
        return DISPLAY_SIZES[device]
    except KeyError:
        raise RuntimeError('The display hardware has not been identified.') from None


def current_device():
    frontend = os.environ.get('PLATFORM', '')
    model, cpu = read('/proc/device-tree/model'), read('/proc/cpuinfo')
    menu = os.environ.get('AM2ARM_FRONTEND')
    if frontend == 'tg5040':
        frontend = os.environ.get('DEVICE', '')
    try:
        return identify(model, cpu, frontend, read('/etc/os-release'))
    except RuntimeError as error:
        # Only older firmware with no board identifier needs these fallbacks.
        if not str(error).startswith('Unrecognized'):
            raise
        if menu == 'nextui' and os.environ.get('PLATFORM') == 'tg5040' and frontend in ('brick','smartpro'):
            return frontend
        if menu != 'stock':
            raise
        mainui = Path('/usr/trimui/bin/MainUI')
        if not mainui.is_file():
            raise
        content = mainui.read_bytes()
        if b'Trimui Brick Pro\0' in content:
            raise RuntimeError('This board requires another hardware profile.') from error
        models = [('smartpros', b'Trimui Smart Pro S\0'), ('smartpro', b'Trimui Smart Pro\0'), ('brick', b'Trimui Brick\0')]
        found = [device for device, label in models if label in content]
        if len(found) == 1:
            return found[0]
        if not found and 'lcd=jd9168' in read('/proc/cmdline').split():
            return 'brick'
        raise


@contextmanager
def stay_awake(card, device, marker=Path('/tmp/stay_awake')):
    """Keep TrimUI's firmware from sleeping while AM2ARM is open."""
    owned = False
    if device in ('smartpro', 'smartpros', 'brick') and (
            os.environ.get('AM2ARM_FRONTEND') == 'stock' or (card/'spruce').is_dir()):
        try:
            marker.touch(exist_ok=False)
            owned = True
        except FileExistsError:
            pass
    try:
        yield
    finally:
        if owned:
            marker.unlink(missing_ok=True)
