import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile

SOURCE = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(SOURCE))
sys.path.insert(0,str(SOURCE/'menus'))
import package_sd
from launch_layout import card_shortcuts
from test_install import release_at


class MenuEntrypoints(unittest.TestCase):
    def test_keyboard_compiler_uses_runtime_supplied_by_display_launcher(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            runtime = root / 'game card' / 'runtime'
            (runtime / 'core').mkdir(parents=True)
            loader = runtime / 'core/ld-linux-aarch64.so.1'
            loader.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            loader.chmod(0o755)
            server = root / 'display-server'
            server.mkdir()
            compiler = server / 'xkbcomp'
            compiler.write_bytes((SOURCE / 'runtime/bin/xkbcomp').read_bytes())
            env = dict(os.environ, AM2ARM_RUNTIME_DIR=str(runtime), AM2ARM_DISPLAY_PATH='direct')
            result = subprocess.run(['sh', './xkbcomp', '-xkm', 'a keymap'], cwd=server,
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), [
                '--library-path', f'{runtime}/core:{runtime}/lib', str(runtime / 'bin/xkbcomp.bin'),
                '-xkm', 'a keymap',
            ])

    def test_every_card_shortcut_runs_one_game_from_a_card_with_spaces(self):
        with tempfile.TemporaryDirectory() as folder:
            card = Path(folder)/'My Games'
            app = card/'am2arm-launcher'
            app.mkdir(parents=True)
            (app/'launch.sh').write_text('printf "%s\\n" "$AM2ARM_FRONTEND" "$AM2ARM_GAME_CARD" "$1" "${2:-play}"\n')
            entries = card_shortcuts(card)
            for name, frontend in {'Tools/tg5040/AM2ARM.pak/launch.sh':'nextui','Tools/my355/AM2ARM.pak/launch.sh':'tools',
                'Apps/AM2ARM/launch.sh':'stock','App/AM2ARM/launch.sh':'spruce','ports/AM2ARM.sh':'ports',
                'roms/ports/AM2ARM.sh':'ports'}.items():
                with self.subTest(name=name):
                    result=subprocess.check_output(['sh',entries[name]],text=True,env=dict(os.environ,SDCARD_PATH='/wrong'))
                    self.assertEqual(result.splitlines(),[frontend,str(card),'auto','play'])
            for folder in ('App','Apps'):
                config=json.loads((card/folder/'AM2ARM/config.json').read_text())
                for device in ('TRIMUI_SMART_PRO_S', 'SPRUCE_TRIMUI_SMART_PRO_S'):
                    self.assertIn(device, config['devices'])
                self.assertEqual(config['label'],'AM2ARM')
                self.assertEqual((card/folder/'AM2ARM'/config['icon']).resolve(), app/'AM2ARM/patcher/assets/app-icon.png')
            self.assertEqual(len(entries),len({name.casefold() for name in entries}))

    def test_unpacker_that_discards_modes_can_still_start_the_runtime(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);app=root/'AM2ARM';app.mkdir()
            tool=app/'native tool'
            tool.write_text('#!/bin/sh\necho "game ready"\n')
            tool.chmod(0o644)
            (root/'executables.txt').write_text('AM2ARM/native tool\n')
            (app/'launch.sh').write_text('exec "$(dirname "$0")/native tool"\n')
            entry=root/'launch.sh'
            entry.write_bytes((SOURCE/'menus/payload.sh').read_bytes())
            run=subprocess.run(['sh',entry],text=True,capture_output=True)
            self.assertEqual(run.returncode,0,run.stderr)
            self.assertEqual(run.stdout.strip(),'game ready')
            self.assertTrue(os.access(tool,os.X_OK))


class PackageTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.installer, self.gmloader = self.root/'previous', self.root/'gmloader'
        for name in package_sd.REQUIRED:
            base = self.gmloader if name.startswith('gmloader/') else self.installer
            self.put(base/name.removeprefix('gmloader/'), b'\x7fELF component')
        for name in ('runtime/play.py', 'runtime/kms/libGL.so.1', 'patcher/handheld_gui.py', 'patcher/patch-bundle/dual/wrapper.bin'):
            self.put(self.installer/name, b'previous')
        for name in package_sd.INSTALLER:
            self.put(self.installer/name/'part', b'part')
        self.game, self.music = self.root/'AM2ARM-gmloader-1.6.4.zip', self.root/'AM2ARM-music.zip'
        release_at(self.game)
        self.tracks({'musTitle.ogg': b'music'})

    def put(self, path, data):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return path

    def tracks(self, tracks):
        with ZipFile(self.music, 'w') as archive:
            for name, data in tracks.items():
                archive.writestr(name, data)
        with ZipFile(self.music) as archive:
            rows = [f'{i.CRC:08X} {i.filename}' for i in archive.infolist()]
        with ZipFile(self.game) as archive:
            members = {name: archive.read(name) for name in archive.namelist() if name != 'music.txt'}
        with ZipFile(self.game, 'w') as archive:
            for name, data in members.items():
                archive.writestr(name, data)
            archive.writestr('music.txt', '\n'.join(rows) + '\n')

    def package(self):
        output = self.root/'out'
        cli = ['package_sd.py', '--installer', self.installer, '--gmloader', self.gmloader, '--game', self.game,
               '--music', self.music, '--output', output]
        with patch.object(sys, 'argv', [str(value) for value in cli]):
            package_sd.main()
        return output/'AM2ARM-1.6.4-linux-arm64.zip'

    def test_card_holds_the_installer_the_loader_and_one_game(self):
        with ZipFile(self.package()) as archive:
            names = set(archive.namelist())
            app = 'am2arm-launcher/AM2ARM/'
            for name in (*package_sd.REQUIRED, 'game/am2arm.zip', 'game/gmloader.json', 'game/assets/musTitle.ogg', 'launch.sh'):
                self.assertIn(app+name, names)
            # Scripts come from the sources, not from the installer ZIP.
            self.assertNotEqual(archive.read(app+'runtime/play.py'), b'previous')
            self.assertNotEqual(archive.read(app+'patcher/handheld_gui.py'), b'previous')
            self.assertNotIn(app+'runtime/kms/libGL.so.1', names)
            self.assertFalse([name for name in names if 'patch-bundle' in name])
            self.assertIn('am2arm-launcher/dependencies/README.md', names)
            self.assertEqual(archive.read(app+'game/am2arm.zip'), self.game.read_bytes())
            programs = archive.read('am2arm-launcher/executables.txt').decode().splitlines()
            for name in ('AM2ARM/gmloader/gmloadernext.aarch64', 'AM2ARM/runtime/python/usr/bin/python3.11',
                         'AM2ARM/runtime/core/ld-linux-aarch64.so.1', 'AM2ARM/runtime/start.sh'):
                self.assertIn(name, programs)
                self.assertTrue(archive.getinfo('am2arm-launcher/'+name).external_attr >> 16 & 0o111)
            self.assertNotIn('AM2ARM/gmloader/lib/libdualscreen.so', programs)

    def test_music_from_another_release_stops_packaging(self):
        self.package()
        with ZipFile(self.music, 'w') as archive:
            archive.writestr('musTitle.ogg', b'other music')
        with self.assertRaisesRegex(ValueError, 'different release'):
            package_sd.collect(self.installer, self.gmloader, self.game, self.music, self.root/'music')

    def test_missing_component_or_player_files_stop_packaging(self):
        (self.gmloader/'fallback/libSDL2-2.0.so.0').unlink()
        with self.assertRaisesRegex(ValueError, 'fallback/libSDL2'):
            package_sd.collect(self.installer, self.gmloader, self.game, self.music, self.root/'music')
        self.put(self.installer/'runtime/share/data.win', b'private')
        with self.assertRaisesRegex(ValueError, 'Unexpected input'):
            package_sd.collect(self.installer, self.gmloader, self.game, self.music, self.root/'music2')

    def test_rebuilt_game_data_is_never_packaged(self):
        with ZipFile(self.game, 'a') as archive:
            archive.writestr('assets/game.droid', b'private')
        with self.assertRaisesRegex(ValueError, 'not the AM2ARM-gmloader ZIP'):
            package_sd.collect(self.installer, self.gmloader, self.game, self.music, self.root/'music')
