#!/usr/bin/env python3
"""Media UI/service regression on VM; no commands sent to real players."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

if socket.gethostname()!='j4n9-proxmox':raise SystemExit('Run only on j4n9-proxmox')
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='media-controls-') as directory:
    tree=Path(directory)/'quickshell';shutil.copytree(source,tree)
    config=tree/'shell.qml'
    config.write_text((tree/'tests/MediaControls.qml').read_text().replace('"../modules/','"modules/').replace('"../services"','"services"'))
    art=Path(directory)/'cover.svg'
    art.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" fill="#89b4fa"/><path d="M18 42V19h28v23M18 24h28" fill="none" stroke="#1e1e2e" stroke-width="5"/></svg>')
    rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True,timeout=5))
    if len(rows)!=1:raise SystemExit('Exactly one compositor required')
    env=dict(os.environ,WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    log_path=Path('/tmp/media-controls-tests.log')
    def ipc(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','mediaTest',method,*map(str,args)],
                              capture_output=True,text=True,env=env,timeout=6)
        if result.returncode:raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def state():return json.loads(ipc('status'))
    def wait(predicate):
        deadline=time.monotonic()+12;last=None
        while time.monotonic()<deadline:
            if process.poll() is not None:raise RuntimeError(log_path.read_text())
            try:
                last=state()
                if predicate(last):return last
            except (ValueError,RuntimeError) as error:last=str(error)
            time.sleep(.1)
        raise AssertionError(str(last)+'\n'+log_path.read_text())
    def key(name):
        assert ipc('key',name)=='true';time.sleep(.15)
    def check(stage):
        assert int(ipc('uiCheck',stage))>=18,(stage,state(),log_path.read_text())
    with log_path.open('w') as log:
        process=subprocess.Popen(['qs','-p',str(config)],stdout=log,stderr=log,env=env)
        try:
            wait(lambda s:s['loaded']);time.sleep(.5)
            native=state();print('NATIVE read-only MPRIS: players='+str(native['count'])+', available='+str(native['available']),flush=True)
            ipc('mocks');wait(lambda s:s['count']==3 and s['name']=='Playing player')
            assert int(ipc('serviceTests'))==17,log_path.read_text()
            print('PASS auto/manual selection, playback reactivity, capabilities, stale/missing players and metadata fallback',flush=True)
            ipc('reset');wait(lambda s:s['name']=='Playing player')
            for control in ('mediaNext','mediaPrevious','mediaPlayPause'):
                ipc('focus',control);time.sleep(.1);key('Return')
            check('controls')
            ipc('click','mediaChoosePlayer');time.sleep(.2)
            ipc('focus','mediaPlayer_0');time.sleep(.1);key('Return');check('selected');check('returned')
            key('Tab');wait(lambda s:s['focus']==['mediaPrevious'])
            key('Backtab');wait(lambda s:s['focus']==['mediaChoosePlayer'])
            key('Return');time.sleep(.1);ipc('focus','mediaPlayer_1');time.sleep(.1);key('Escape');check('escape')
            ipc('lockPlayer');wait(lambda s:not s['canToggle']);check('blocked')
            ipc('single');wait(lambda s:s['count']==1 and s['name']=='Paused player')
            for width in (340,420):
                ipc('resize',width);wait(lambda s:s['width']==width)
                ipc('metadata','false');height=state()['height']
                ipc('metadata','true');time.sleep(.15)
                assert state()['height']==height,state()
            ipc('artwork',art.as_uri());wait(lambda s:s['art']==1)
            subprocess.run(['grim','-o','Virtual-1','/tmp/media-card-fixture.png'],env=env,check=True,timeout=5)
            ipc('artwork',(Path(directory)/'missing.png').as_uri());wait(lambda s:s['art']==3)
            ipc('removeAll');wait(lambda s:not s['available']);check('hidden')
            ipc('reset');wait(lambda s:s['available'])
            ipc('click','mediaChoosePlayer');time.sleep(.1);ipc('focus','mediaPlayer_0');time.sleep(.1)
            ipc('removeAll');wait(lambda s:not s['visible'])
            ipc('reset');wait(lambda s:s['visible'])
            for _ in range(5):
                ipc('unload');wait(lambda s:not s['loaded'])
                ipc('load');wait(lambda s:s['loaded'])
            print('PASS keyboard, player chooser, fixed metadata layout, artwork/fallback and 5 view lifecycles',flush=True)
            ipc('fullOpen');time.sleep(.5)
            full=json.loads(ipc('fullStatus'));assert full['cardVisible'] and 'mediaPlayPause' in full['targets'],full
            ipc('fullArtwork',art.as_uri());time.sleep(.3)
            subprocess.run(['grim','-o','Virtual-1','/tmp/media-dashboard-fixture.png'],env=env,check=True,timeout=5)
            generation=full['generation']
            config.write_text(config.read_text()+'\n// media dashboard live reload regression\n')
            deadline=time.monotonic()+12
            while time.monotonic()<deadline:
                try:
                    full=json.loads(ipc('fullStatus'))
                    if full['generation']>generation and full['opened'] and full['cardVisible']:break
                except (ValueError,RuntimeError):
                    pass
                time.sleep(.15)
            else:raise AssertionError((full,log_path.read_text()))
            ipc('fullFocus','mediaPlayPause');time.sleep(.1)
            ipc('removeAll');time.sleep(.25)
            full=json.loads(ipc('fullStatus'));assert not full['cardVisible'] and full['focus']==['dashboardClose'],full
            key('Escape');time.sleep(.2)
            full=json.loads(ipc('fullStatus'));assert not full['opened'] and not full['loaded'],full
            print('PASS full dashboard Tab integration, live reload, focus recovery on player removal and lazy destruction',flush=True)
        finally:
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
    errors=[line for line in log_path.read_text().splitlines() if any(word in line for word in
        ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no real playback changes',flush=True)
