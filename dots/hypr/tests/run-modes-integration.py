#!/usr/bin/env python3
"""Native VM integration. Temporarily changes focus and creates a headless output.
Run from any directory; requires existing hyprctl and kitty, no extra packages.
"""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
if socket.gethostname() != 'j4n9-proxmox':
    raise SystemExit('Run only on j4n9-proxmox')

def run(*args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=10)
    if result.returncode or result.stdout.strip().startswith('error:'):
        raise RuntimeError(result.stderr or result.stdout)
    return result.stdout.strip()

instances = json.loads(run('hyprctl', 'instances', '-j'))
if len(instances) != 1:
    raise SystemExit('Exactly one Hyprland instance required')
instance = instances[0]

def ctl(*args):
    return run('hyprctl', '-i', instance['instance'], *args)

def read(name):
    return json.loads(ctl('-j', name))

def lua(body):
    return ctl('dispatch', 'function() ' + body + ' end')

def wait(predicate):
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(.1)
    raise AssertionError('Native compositor state timed out')

def switch(mode):
    lua('require("modes.core").switch(' + json.dumps(mode) + ')')

def refresh():
    lua('require("modes.core").refresh()')

initial_monitors = read('monitors')
initial_clients = read('clients')
initial_workspace = read('activeworkspace')['name']
initial_window = read('activewindow').get('address')
initial_cursor = read('cursorpos')
if len(initial_monitors) != 1 or initial_monitors[0]['specialWorkspace']['name']:
    raise SystemExit('Requires one monitor without an open special workspace')
if any(c['workspace']['name'] == 'special:minimized' or any(
        t == 'minimized' or t.startswith('mode-return-secondary-') for t in c['tags'])
       or c['workspace']['name'].endswith('-secondary') for c in initial_clients):
    raise SystemExit('Existing minimized/secondary-return windows: test deferred')
if ctl('configerrors'):
    raise SystemExit('Resolve existing config errors first')

process = None
output = None
address = None
original = initial_monitors[0]['name']
class_name = 'mode-integration-' + str(os.getpid())

def client():
    return next((c for c in read('clients') if c['class'] == class_name), None)

def at(name):
    c = client()
    return c if c and c['workspace']['name'] == name else None

def focus_test():
    lua('hl.dispatch(hl.dsp.focus({window=hl.get_window(' + json.dumps('address:' + address) + ')}))')
    wait(lambda: read('activewindow').get('address') == address)

# Load the actual binding callback in an isolated environment. Other binds are
# discarded; hl queries/dispatches still use the native compositor API.
# This verifies callback behavior, not physical keyboard event delivery.
def minimize_restore():
    lua('local callback; local proxy=setmetatable({bind=function(keys, fn) '
        'if keys=="SUPER + M" then callback=fn end end},{__index=hl}); '
        'local env=setmetatable({hl=proxy},{__index=_G}); '
        'assert(loadfile(' + json.dumps(str(ROOT / 'binds.lua')) + ',"t",env))(); '
        'assert(callback)()')

try:
    env = dict(os.environ, WAYLAND_DISPLAY=instance['wl_socket'],
               HYPRLAND_INSTANCE_SIGNATURE=instance['instance'])
    process = subprocess.Popen([shutil.which('kitty'), '--class', class_name,
                                '--title', 'Mode integration test', 'sleep', '600'],
                               env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    address = wait(client)['address']
    for mode in ('writing', 'code', 'relax'):
        primary, secondary = 'mode-' + mode + '-primary', 'mode-' + mode + '-secondary'
        tag = 'mode-return-secondary-' + mode
        lua('hl.dispatch(hl.dsp.window.move({window=hl.get_window(' + json.dumps('address:' + address)
            + '),workspace=' + json.dumps('name:' + secondary) + ',follow=false}))')
        switch(mode)
        wait(lambda: at(primary) and tag in client()['tags'])
        focus_test()
        minimize_restore()
        wait(lambda: at('special:minimized') and 'minimized' in client()['tags'])
        assert tag in client()['tags']
        ctl('output', 'create', 'headless')
        output = wait(lambda: next((m['name'] for m in read('monitors') if m['name'] != original), None))
        switch(mode)
        assert at('special:minimized') and tag in client()['tags']
        # Reload must preserve mode and the minimized origin/return markers.
        before = read('activeworkspace')['name']
        ctl('reload')
        assert not ctl('configerrors')
        assert read('activeworkspace')['name'] == before
        assert at('special:minimized') and tag in client()['tags']
        minimize_restore()
        wait(lambda: at(primary) and 'minimized' not in client()['tags'])
        assert not any(t.startswith('minimized-from-') for t in client()['tags'])
        refresh()
        wait(lambda: at(secondary) and tag not in client()['tags'])
        # Switching modes preserves whichever physical monitor was focused.
        lua('hl.dispatch(hl.dsp.focus({monitor=' + json.dumps(output) + '}))')
        switch(mode)
        assert next(m['name'] for m in read('monitors') if m['focused']) == output
        ctl('output', 'remove', output)
        output = None
        wait(lambda: len(read('monitors')) == 1)
        switch(mode)
        wait(lambda: at(primary) and tag in client()['tags'])
        print('PASS ' + mode + ': native collapse/minimize/reload/expand/focus/disconnect', flush=True)
    print('PASS all three modes on native compositor with headless hotplug', flush=True)
finally:
    if process:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
    if output:
        ctl('output', 'remove', output)
    lua('hl.dispatch(hl.dsp.focus({monitor=' + json.dumps(original) + '})); '
        'hl.dispatch(hl.dsp.focus({workspace=' + json.dumps('name:' + initial_workspace if not initial_workspace.isdigit() else initial_workspace) + '}))')
    if initial_window and any(c['address'] == initial_window for c in read('clients')):
        lua('hl.dispatch(hl.dsp.focus({window=hl.get_window(' + json.dumps('address:' + initial_window) + ')}))')
    # Restore pointer position through compositor API after focus restoration.
    lua('hl.dispatch(hl.dsp.cursor.move({x=' + str(initial_cursor['x']) + ',y=' + str(initial_cursor['y']) + '}))')
    wait(lambda: client() is None)
    assert {m['name'] for m in read('monitors')} == {original}
    assert read('activeworkspace')['name'] == initial_workspace
    for before in initial_clients:
        after = next((c for c in read('clients') if c['address'] == before['address']), None)
        assert after and after['workspace']['name'] == before['workspace']['name'] and after['tags'] == before['tags'], 'Original window state changed'
    print('PASS cleanup: test window/output removed; original workspace/windows/tags restored', flush=True)
