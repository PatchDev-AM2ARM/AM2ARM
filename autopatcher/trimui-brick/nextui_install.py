"""Keep the common patch engine and add a NextUI Tools entry."""
from pathlib import Path
import os
from linux_patcher import prepare_game as prepare_standard
from nextui_layout import check_play_entry, relative_game, write_play_entry


def prepare_game(source, output, edition, progress):
    if edition != 'standard':
        raise RuntimeError('This Brick package supports Standard Edition.')
    card = Path(os.environ.get('SDCARD_PATH', '/mnt/SDCARD'))
    relative_game(card, Path(output)/'AM2ARM Standard')
    check_play_entry(card)
    result, digest = prepare_standard(source, output, edition, progress)
    write_play_entry(card, result)
    return result, digest
