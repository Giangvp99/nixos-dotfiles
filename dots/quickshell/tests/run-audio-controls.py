#!/usr/bin/env python3
"""Isolated AudioCard/AudioService regression; never writes real audio state."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

if socket.gethostname() != 'j4n9-proxmox':
    raise SystemExit('Run only on j4n9-proxmox')
source = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='audio-controls-') as directory:
    tree = Path(directory) / 'quickshell'
    shutil.copytree(source, tree)
    config = tree / 'shell.qml'
    config.write_text((tree / 'tests/AudioControls.qml').read_text()
        .replace('"../modules/', '"modules/').replace('"../services"', '"services"'))
    env = dict(os.environ)
    instances = subprocess.run(['hyprctl', 'instances', '-j'], capture_output=True, text=True, timeout=5)
    if instances.returncode == 0:
        rows = json.loads(instances.stdout)
        if len(rows) == 1:
            env.update(WAYLAND_DISPLAY=rows[0]['wl_socket'], HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    log_path = Path('/tmp/audio-controls-tests.log')
    def ipc(method, *args):
        result = subprocess.run(['qs', 'ipc', '-p', str(config), 'call', 'audioTest', method,
                                 *map(str, args)], capture_output=True, text=True, timeout=5, env=env)
        if result.returncode:
            raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def wait(predicate):
        deadline = time.monotonic() + 12
        last = None
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError(log_path.read_text())
            try:
                last = json.loads(ipc('status'))
                if predicate(last):
                    return last
            except (ValueError, RuntimeError) as error:
                last = str(error)
            time.sleep(.15)
        raise AssertionError(str(last) + '\n' + log_path.read_text())
    with log_path.open('w') as log:
        process = subprocess.Popen(['qs', '-p', str(config)], stdout=log, stderr=log, env=env)
        try:
            native = wait(lambda row: row['loaded'])
            time.sleep(1)
            native = json.loads(ipc('status'))
            print('NATIVE read-only: ' + json.dumps(native), flush=True)
            ipc('mocks')
            wait(lambda row: row['available'] and len(row['outputs']) == 2)
            print('PASS service: ' + ipc('serviceTests') + ' assertions', flush=True)
            ipc('expand'); time.sleep(.3)
            ipc('prepareSelection')
            ipc('focus','dashboardOutputDevice_102'); time.sleep(.15)
            for key, stage in [('Return','selection'),('Escape','escape'),('Tab','tab'),('Backtab','backtab'),('Right','slider')]:
                if stage=='slider':
                    ipc('focus','dashboardInputVolume'); time.sleep(.15)
                assert ipc('key',key)=='true', key
                time.sleep(.2)
                count=int(ipc('keyboardCheck',stage))
                assert count>=20, (stage,ipc('status'),log_path.read_text())
            print('PASS Enter/Escape/Tab/Backtab/microphone slider', flush=True)
            ipc('focusDevice'); time.sleep(.3)
            ipc('disconnect'); time.sleep(.3)
            print('PASS hotplug: ' + ipc('disconnectedTests') + ' assertions', flush=True)
            for width in (340, 420):
                ipc('resize', width); wait(lambda row: row['width'] == width)
                ipc('viewTests')
            for _ in range(10):
                ipc('unload'); wait(lambda row: not row['loaded'])
                ipc('load'); wait(lambda row: row['loaded'])
            print('PASS narrow/wide layout and 10 unload/reload cycles', flush=True)
            ipc('fullOpen'); time.sleep(.5)
            assert int(ipc('fullCheck')) >= 37
            ipc('fullFocus'); time.sleep(.15)
            assert ipc('fullKey','Tab')=='true'; time.sleep(.2)
            assert json.loads(ipc('fullStatus'))['focus']==['dashboardInputMute']
            assert ipc('fullKey','Escape')=='true'; time.sleep(.3)
            full=json.loads(ipc('fullStatus'))
            assert not full['opened'] and not full['loaded'], full
            print('PASS full dashboard Tab integration, Escape and lazy destruction', flush=True)
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill(); process.wait(timeout=5)
    errors = [line for line in log_path.read_text().splitlines()
              if any(word in line for word in ('ReferenceError', 'TypeError', 'Binding loop', 'Unable to assign', 'Error:'))]
    if errors:
        raise AssertionError('\n'.join(errors))
    print('PASS no QML errors; real audio state untouched', flush=True)
