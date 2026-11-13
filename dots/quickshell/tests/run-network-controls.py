#!/usr/bin/env python3
"""VM network controls regression. Writes only to an isolated mock backend."""
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
with tempfile.TemporaryDirectory(prefix='network-controls-') as directory:
    tree = Path(directory) / 'quickshell'
    shutil.copytree(source, tree)
    config = tree / 'shell.qml'
    config.write_text((tree / 'tests/NetworkControls.qml').read_text()
        .replace('"../modules/', '"modules/').replace('"../services"', '"services"'))
    env = dict(os.environ)
    instances = json.loads(subprocess.check_output(['hyprctl', 'instances', '-j'], text=True, timeout=5))
    if len(instances) != 1:
        raise SystemExit('Exactly one Hyprland instance required')
    env.update(WAYLAND_DISPLAY=instances[0]['wl_socket'], HYPRLAND_INSTANCE_SIGNATURE=instances[0]['instance'])
    log_path = Path('/tmp/network-controls-tests.log')
    def ipc(method, *args):
        result = subprocess.run(['qs', 'ipc', '-p', str(config), 'call', 'networkTest', method,
                                 *map(str, args)], capture_output=True, text=True, timeout=5, env=env)
        if result.returncode:
            raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def state():
        return json.loads(ipc('status'))
    def wait(predicate):
        deadline = time.monotonic() + 12
        last = None
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError(log_path.read_text())
            try:
                last = state()
                if predicate(last): return last
            except (ValueError, RuntimeError) as error:
                last = str(error)
            time.sleep(.15)
        raise AssertionError(str(last) + '\n' + log_path.read_text())
    def check(stage):
        result = int(ipc('uiCheck', stage))
        assert result >= 20, (stage, state(), log_path.read_text())
    with log_path.open('w') as log:
        process = subprocess.Popen(['qs', '-p', str(config)], stdout=log, stderr=log, env=env)
        try:
            print('NATIVE read-only: ' + json.dumps(wait(lambda row: row['loaded'])), flush=True)
            ipc('mocks'); wait(lambda row: row['available'])
            assert int(ipc('serviceTests')) >= 19, log_path.read_text()
            print('PASS scanner ownership/hotplug, saved/open-only connection, failure, stale/busy guards', flush=True)
            ipc('click','dashboardNetworks'); time.sleep(.25); check('expanded')
            ipc('focus','dashboardNetwork_0'); time.sleep(.1)
            assert ipc('key','Return')=='true'; time.sleep(.2); check('selection')
            # A connecting row is disabled; focus the detail toggle to close by Escape.
            ipc('focus','dashboardNetworks'); time.sleep(.1)
            assert ipc('key','Escape')=='true'; time.sleep(.2); check('escape')
            assert ipc('key','Backtab')=='true'; time.sleep(.2)
            assert state()['focus']==['dashboardNetworkSettings'], state()
            assert ipc('key','Return')=='true'; time.sleep(.15); check('settings')
            assert ipc('key','Tab')=='true'; time.sleep(.15)
            assert state()['focus']==['dashboardNetworks'], state()
            ipc('click','dashboardWifi'); time.sleep(.2); check('off')
            ipc('click','dashboardWifi'); ipc('clearBusy')
            print('PASS Enter/Escape/Tab/Backtab, Settings routing, Wi-Fi toggle', flush=True)
            ipc('click','dashboardNetworks'); wait(lambda row: row['scanning'])
            ipc('popupOpen'); time.sleep(.3)
            assert int(ipc('popupCheck')) >= 30
            ipc('popupClose'); wait(lambda row: row['owners']==['dashboard-network'] and row['scanning'])
            ipc('loseAdapter'); time.sleep(.25); check('lost')
            ipc('restoreAdapter'); wait(lambda row: row['available'] and row['scanning'])
            for width in (340, 420):
                ipc('resize',width); wait(lambda row: row['width']==width)
            ipc('unload'); wait(lambda row: not row['loaded'] and not row['scanning'] and row['owners']==[])
            for _ in range(5):
                ipc('load'); wait(lambda row: row['loaded'])
                ipc('click','dashboardNetworks'); wait(lambda row: row['scanning'])
                ipc('unload'); wait(lambda row: not row['loaded'] and not row['scanning'])
            print('PASS popup/dashboard shared scanner, adapter removal/recovery, narrow layout and 5 lifecycle cycles', flush=True)
            ipc('fullOpen'); time.sleep(.6)
            assert json.loads(ipc('fullStatus'))['loaded'], ipc('fullStatus')
            ipc('fullMocks')
            ipc('fullClick','dashboardDnd')
            ipc('fullClick','dashboardNetworks'); time.sleep(.2)
            assert int(ipc('fullCheck')) >= 35, (ipc('fullStatus'),log_path.read_text())
            ipc('fullFocus','dashboardNetworks'); time.sleep(.1)
            assert ipc('key','Tab')=='true'; time.sleep(.15)
            assert json.loads(ipc('fullStatus'))['focus']==['dashboardNetwork_0']
            assert ipc('key','Escape')=='true'; time.sleep(.2)
            full=json.loads(ipc('fullStatus'))
            assert full['opened'] and full['focus']==['dashboardNetworks'] and full['owners']==[], full
            assert ipc('key','Escape')=='true'; time.sleep(.2)
            full=json.loads(ipc('fullStatus'))
            assert not full['opened'] and not full['loaded'] and full['owners']==[], full
            print('PASS full dashboard DND, network Tab order, two-stage Escape and lazy cleanup', flush=True)
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill(); process.wait(timeout=5)
    errors = [line for line in log_path.read_text().splitlines()
              if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors, '\n'.join(errors)
    print('PASS no QML errors; real network state untouched', flush=True)
