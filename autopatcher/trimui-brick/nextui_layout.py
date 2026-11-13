"""SD-card paths and firmware menu entries for the Brick package."""
import json
import os
from pathlib import Path

MARKER = '# AM2ARM NextUI launcher v1'
PLAY_ENTRY = Path('Tools/tg5040/AM2ARM Standard.pak/launch.sh')


def stock_menu():
    return os.environ.get('AM2ARM_FRONTEND') == 'stock'


def play_entry():
    return Path('Apps/AM2ARMStandard/launch.sh') if stock_menu() else PLAY_ENTRY


def app_config(label, description):
    return {'label': label, 'icon': '', 'icontop': '../../AM2ARM/patcher/assets/app-icon.png', 'launch': 'launch.sh',
            'description': description}


def launcher(mode):
    if mode not in ('game', 'patcher'):
        raise ValueError('Unknown launch mode')
    frontend = 'export AM2ARM_FRONTEND=stock\n' if stock_menu() else ''
    return f'''#!/bin/sh
{MARKER}
{frontend}am2arm_card=${{SDCARD_PATH:-/mnt/SDCARD}}
exec /bin/sh "$am2arm_card/AM2ARM/runtime/start.sh" {mode}
'''


def check_play_entry(card):
    target = Path(card)/play_entry()
    config = target.parent/'config.json'
    if ((target.exists() and MARKER not in target.read_text()) or
            (stock_menu() and config.exists() and not target.exists())):
        raise RuntimeError('An existing AM2ARM Standard tool uses a different launcher. Keep a backup before replacing it.')


def relative_game(card, game):
    card, game = Path(card).resolve(), Path(game).resolve()
    try:
        relative = game.relative_to(card)
    except ValueError:
        raise RuntimeError('Choose an installation folder on this SD card.') from None
    if not relative.parts:
        raise RuntimeError('The game must have its own folder.')
    return relative


def write_play_entry(card, game):
    card = Path(card)
    relative = relative_game(card, game)
    check_play_entry(card)
    target = card/play_entry()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(launcher('game'))
    target.chmod(0o755)
    if stock_menu():
        config = target.parent/'config.json'
        temporary = config.with_suffix('.new')
        temporary.write_text(json.dumps(app_config('AM2ARM Standard',
            'Gameplay on a single screen'), indent=2)+'\n')
        temporary.replace(config)
    state = card/'AM2ARM/state/installation.json'
    state.parent.mkdir(parents=True, exist_ok=True)
    temporary = state.with_suffix('.new')
    temporary.write_text(json.dumps({'game': relative.as_posix()}, indent=2)+'\n')
    temporary.replace(state)


def installed_game(card):
    card = Path(card)
    state = card/'AM2ARM/state/installation.json'
    if not state.is_file():
        raise RuntimeError('Run AM2ARM Autopatcher and install Standard first.')
    relative = Path(json.loads(state.read_text())['game'])
    if relative.is_absolute():
        raise RuntimeError('The installation record must use a path on this SD card.')
    return card/relative_game(card, card/relative)
