"""AM2ARM Autopatcher: build the game's archive from the command line."""
import argparse
from pathlib import Path

from patch_core import PatchError, build_port


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--zip', type=Path, required=True, help='Your original AM2R 1.1 ZIP or folder')
    parser.add_argument('--game', type=Path, required=True, help="The release's AM2ARM-gmloader ZIP")
    parser.add_argument('--out', type=Path, default=Path('am2arm.port'), help='Where to write the archive')
    args = parser.parse_args()
    previous = None

    def progress(done, total, text):
        nonlocal previous
        current = f'{text} {int(done * 100 / total) if total > 1 else 0}%'
        if current != previous:
            print(current, flush=True)
            previous = current
    try:
        digest = build_port(args.zip, args.game, args.out, progress)
    except PatchError as error:
        parser.exit(1, str(error) + '\n')
    print('Ready:', args.out)
    print('SHA-256:', digest)


if __name__ == '__main__':
    main()
