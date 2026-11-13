#!/usr/bin/env python3
"""Read-only binding reference and production-shell overlay regression on VM."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

if socket.gethostname()!='j4n9-proxmox':
    raise SystemExit('Run only on j4n9-proxmox')
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='keybinds-') as directory:
    tree=Path(directory)/'quickshell'
    shutil.copytree(source,tree)
    config=tree/'shell.qml'
    text=config.read_text().replace('import QtQuick','import QtTest\nimport Quickshell.Io\nimport "utils/Keybindings.js" as Bindings\nimport QtQuick',1)
    text=text.replace('ShellRoot {','ShellRoot {\n'+(tree/'tests/KeybindsHarness.inc').read_text(),1)
    text=text.replace('id: keybinds','id: keybinds\n        shortcutAppId: "keybinds-test"',1)
    text=text.replace('id: launcher','id: launcher\n        shortcutAppId: "keybinds-test"',1)
    config.write_text(text)
    data=Path(directory)/'bindings.json'
    rows=[{'modmask':64,'key':'H','description':'Previous app'},
          {'modmask':64,'key':'1','description':'Switch to Writing mode'},
          {'modmask':65,'key':'Return','description':'Open terminal'},
          {'modmask':0,'key':'XF86AudioMute','description':'Toggle output mute','locked':True},
          {'modmask':0,'key':'Print','description':'Capture region'},
          {'modmask':4,'key':'','keycode':38,'description':'<b>plain text</b> '+('long description '*10),'release':True}]
    data.write_text(json.dumps(rows))
    instances=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True,timeout=5))
    if len(instances)!=1: raise SystemExit('Exactly one compositor required')
    env=dict(os.environ,WAYLAND_DISPLAY=instances[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=instances[0]['instance'])
    log_path=Path('/tmp/keybinds-tests.log')
    def ipc(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','keybindTest',method,*map(str,args)],
                              text=True,capture_output=True,env=env,timeout=6)
        if result.returncode: raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def state(): return json.loads(ipc('status'))
    def wait(predicate):
        deadline=time.monotonic()+12
        last=None
        while time.monotonic()<deadline:
            if process.poll() is not None: raise RuntimeError(log_path.read_text())
            try:
                last=state()
                if predicate(last): return last
            except (ValueError,RuntimeError) as error: last=str(error)
            time.sleep(.1)
        raise AssertionError(str(last)+'\n'+log_path.read_text())
    def key(name):
        assert ipc('key',name)=='true',name
        time.sleep(.15)
    with log_path.open('w') as log:
        process=subprocess.Popen(['qs','-p',str(config)],stdout=log,stderr=log,env=env)
        try:
            wait(lambda s:not s['opened'])
            assert int(ipc('parserTests'))==9
            ipc('command','cat',data); ipc('open')
            wait(lambda s:s['count']==6 and not s['loading'] and s['searchFocus'])
            ipc('query','super enter');wait(lambda s:s['results']==1)
            ipc('query','');wait(lambda s:s['results']==6)
            ipc('filter');wait(lambda s:s['results']==2);ipc('filter')
            key('Down');assert state()['listFocus'],state()
            selected=state()['selected']
            key('Down');assert state()['selected']==(selected+1)%6,state()
            key('Return');assert state()['opened'],'reference must not activate commands'
            key('Home');assert state()['selected']==0
            key('End');assert state()['selected']==5
            key('Tab');assert state()['searchFocus']
            key('Backtab');assert state()['listFocus']
            print('PASS parser, search, category, keyboard navigation and read-only Return',flush=True)
            data.write_text('{bad JSON');ipc('refresh');wait(lambda s:s['error'] and not s['loading'] and s['count']==0)
            data.write_text(json.dumps(rows));ipc('refresh');wait(lambda s:s['count']==6 and not s['error'])
            ipc('command','false','');ipc('refresh');wait(lambda s:s['error'] and not s['loading'])
            ipc('command','sleep','10');ipc('refresh');wait(lambda s:s['error'] and 'timed out' in s['error'] and not s['loading'])
            ipc('close');wait(lambda s:not s['loaded'])
            ipc('command','sleep','10');ipc('open');wait(lambda s:s['loading']);ipc('close');wait(lambda s:not s['loaded'])
            ipc('command','cat',data);ipc('open');wait(lambda s:s['count']==6)
            ipc('compact');time.sleep(.2)
            s=state(); x,y,w,h=s['surface'];ww,wh=s['window'];assert x>=0 and y>=0 and x+w<=ww and y+h<=wh,s
            subprocess.run(['grim','-o','Virtual-1','/tmp/keybinds-fixture.png'],env=env,check=True,timeout=5)
            # Use the production PersistentProperties and root handoff wiring.
            generation=state()['generation']
            config.write_text(config.read_text()+'\n// keybind live reload regression\n')
            wait(lambda s:s['generation']>generation and s['loaded'] and s['count']>0 and s['searchFocus'])
            ipc('command','cat',data);ipc('refresh');wait(lambda s:s['count']==6)
            key('Escape');wait(lambda s:not s['opened'] and not s['loaded'])
            ipc('dashboardOpen');wait(lambda s:s['dashboard'])
            ipc('dashboardHelp');wait(lambda s:s['opened'] and not s['dashboard'] and s['count']==6)
            ipc('launcherOpen');wait(lambda s:s['launcher'] and not s['loaded'])
            ipc('open');wait(lambda s:s['opened'] and not s['launcher'])
            ipc('close');wait(lambda s:not s['loaded'])
            ipc('missingScreen');time.sleep(.2)
            assert not state()['opened'] and not state()['dashboard'],state()
            for _ in range(5):
                ipc('close');wait(lambda s:not s['loaded'])
                ipc('open');wait(lambda s:s['count']==6 and not s['loading'])
            ipc('close');wait(lambda s:not s['loaded'])
            print('PASS invalid JSON, command failure, timeout/cancel, compact layout, live reload, dashboard/launcher handoff and 5 cycles',flush=True)
        finally:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill();process.wait(timeout=5)
    errors=[line for line in log_path.read_text().splitlines() if any(word in line for word in
        ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no binding actions executed',flush=True)
