#!/usr/bin/env python3
"""VM OSD regression using only an injected mock PipeWire backend."""
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
with tempfile.TemporaryDirectory(prefix='audio-osd-') as directory:
    tree = Path(directory) / 'quickshell'
    shutil.copytree(source, tree)
    config = tree / 'shell.qml'
    config.write_text((tree / 'tests/AudioOsd.qml').read_text()
        .replace('"../modules/', '"modules/').replace('"../services"', '"services"')
        .replace('"../config"', '"config"'))
    rows = json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True,timeout=5))
    if len(rows) != 1:
        raise SystemExit('Exactly one compositor instance required')
    env = dict(os.environ,WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    log_path = Path('/tmp/audio-osd-tests.log')
    def ipc(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','osdTest',method,*map(str,args)],
                              text=True,capture_output=True,env=env,timeout=5)
        if result.returncode: raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def state(): return json.loads(ipc('status'))
    def wait(predicate):
        deadline=time.monotonic()+10
        last=None
        while time.monotonic()<deadline:
            if process.poll() is not None: raise RuntimeError(log_path.read_text())
            try:
                last=state()
                if predicate(last): return last
            except (ValueError,RuntimeError) as error: last=str(error)
            time.sleep(.06)
        raise AssertionError(str(last)+'\n'+log_path.read_text())
    def change(channel,percent,muted=False):
        ipc('change',channel,percent,str(muted).lower())
    with log_path.open('w') as log:
        process=subprocess.Popen(['qs','-p',str(config)],stdout=log,stderr=log,env=env)
        try:
            wait(lambda s:s['width']>0)
            time.sleep(.3)
            s=state(); assert not s['shown'] and not s['timer'] and s['presentations']==0,s
            ipc('inputFocus'); wait(lambda s:s['focus'])
            change('output',55)
            s=wait(lambda s:s['shown'] and s['percent']==55)
            assert s['visible'] and not s['focusable'] and s['mask']==[0,0] and s['screen'],s
            assert s['focus'],s
            assert ipc('key')=='true'
            wait(lambda s:s['text']=='a' and s['focus'])
            subprocess.run(['grim','-o',s['screen'],'/tmp/audio-osd-fixture.png'],env=env,check=True,timeout=5)
            time.sleep(.35); change('output',60)
            wait(lambda s:s['shown'] and s['percent']==60)
            time.sleep(.5); assert state()['shown'],'timer not restarted'
            wait(lambda s:not s['shown'] and not s['timer'])
            print('PASS startup silent, volume display, empty input mask, keyboard focus preserved, timeout reset',flush=True)
            before=state()['presentations']; change('output',60)
            time.sleep(.15); assert state()['presentations']==before
            change('output',60,True); wait(lambda s:s['shown'] and s['muted'])
            ipc('replace'); wait(lambda s:not s['shown'])
            before=state()['presentations']; time.sleep(.15)
            assert state()['presentations']==before
            change('output',20); wait(lambda s:s['shown'] and s['percent']==20)
            ipc('unavailable'); wait(lambda s:not s['shown'])
            ipc('recover'); time.sleep(.15); assert not state()['shown']
            ipc('nodeReady','false'); change('output',30); time.sleep(.15); assert not state()['shown']
            ipc('nodeReady','true'); time.sleep(.15); assert not state()['shown']
            ipc('backendReady','false'); change('output',35); time.sleep(.15); assert not state()['shown']
            ipc('backendReady','true'); time.sleep(.15); assert not state()['shown']
            print('PASS mute, duplicate suppression, default-device changes, node/backend disappearance and recovery',flush=True)
            change('input',25,True); wait(lambda s:s['shown'] and s['channel']=='input' and s['muted'])
            ipc('enabled','false'); wait(lambda s:not s['shown'] and not s['timer'])
            change('input',40); time.sleep(.15); assert not state()['shown']
            ipc('enabled','true'); time.sleep(.15); assert not state()['shown']
            ipc('reduced','true'); change('output',45)
            wait(lambda s:s['shown'] and s['motion'] and s['channel']=='output')
            ipc('overAmplified'); wait(lambda s:s['shown'] and s['percent']==125)
            # Reload while visible: no presentation replay or timer in the new tree.
            config.write_text(config.read_text()+"\n// OSD live reload regression\n")
            time.sleep(.7)
            s=wait(lambda s:not s['shown'] and s['presentations']==0 and not s['timer'])
            for i in range(5):
                change('output',51+i)
                wait(lambda s:s['shown'] and s['percent']==51+i)
                wait(lambda s:not s['shown'] and not s['timer'])
            print('PASS microphone, disable/re-enable, reduced motion, >100%, silent live reload and 5 cycles',flush=True)
        finally:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill(); process.wait(timeout=5)
    errors=[line for line in log_path.read_text().splitlines()
            if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no real audio changes',flush=True)
