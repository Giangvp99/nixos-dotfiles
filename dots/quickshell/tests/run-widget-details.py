#!/usr/bin/env python3
"""VM popup and real mouse gesture tests; all actions use fake providers."""
import json, os, shutil, socket, subprocess, tempfile, time
from pathlib import Path
assert socket.gethostname()=='j4n9-proxmox'
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='widget-details-') as temporary:
    tree=Path(temporary)/'shell';shutil.copytree(source,tree)
    config=tree/'shell.qml'
    config.write_text((tree/'tests/WidgetDetails.qml').read_text().replace('"../modules/','"modules/').replace('"../services"','"services"').replace('"../components"','"components"').replace('"../config"','"config"'))
    rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True));assert len(rows)==1
    env=dict(os.environ,XDG_STATE_HOME=str(Path(temporary)/'state'),WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    logpath=Path('/tmp/widget-details-tests.log')
    def call(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','widgetDetailsTest',method,*map(str,args)],env=env,capture_output=True,text=True,timeout=6)
        if result.returncode:raise RuntimeError(result.stderr+result.stdout)
        return result.stdout.strip()
    def state():return json.loads(call('status'))
    def wait(predicate):
        end=time.monotonic()+12;last=None
        while time.monotonic()<end:
            if process.poll() is not None:raise RuntimeError(logpath.read_text())
            try:
                last=state()
                if predicate(last):return last
            except (ValueError,RuntimeError) as error:last=str(error)
            time.sleep(.1)
        raise AssertionError((last,logpath.read_text()))
    with logpath.open('w') as log:
        process=subprocess.Popen(['qs','-p',str(config)],env=env,stdout=log,stderr=log)
        try:
            wait(lambda s:s['netWidth']>0)
            assert int(call('units'))==13
            assert len(set(state()['padding']))==1,state()
            call('focusAudio');time.sleep(.15);call('key','Return');wait(lambda s:s['audioLoaded']);call('close')
            volumeWidth=state()['volumeWidth']
            width=state()['netWidth'];call('kind','wifi');wait(lambda s:s['netKind']=='wifi');call('rates',1000000000)
            assert state()['netWidth']==width;call('kind','lan')
            assert call('click','ordinary','false')=='true';wait(lambda s:s['singles']==1)
            call('click','gesture','true');wait(lambda s:s['doubles']==1)
            time.sleep(state()['doubleInterval']/1000+.1);assert state()['singles']==1,state()
            call('click','ordinary','true');call('click','baseline','true')
            assert state()['singles']==1+state()['baseline'],state()
            call('click','audio','true');wait(lambda s:s['toggles']==1)
            time.sleep(state()['doubleInterval']/1000+.1);assert not state()['audio'] and state()['volumeWidth']==volumeWidth,state()
            call('click','audio','false');wait(lambda s:s['audio'] and s['audioLoaded'])
            assert state()['toggles']==1,state()
            call('key','Tab');assert state()['focus'],state()
            assert call('uiClick','dashboardInputMute')=='true'
            assert call('uiClick','dashboardOutputDevices')=='true';assert call('uiClick','dashboardOutputDevice_2')=='true'
            call('key','Escape');call('key','Escape');wait(lambda s:not s['audioLoaded'])
            call('wheel');assert state()['wheels']==1
            print('PASS real single/double mouse clicks, keyboard, audio card, volume wheel and lazy popup destruction',flush=True)
            call('click','network','false');wait(lambda s:s['networkLoaded'])
            assert call('uiClick','networkRefresh')=='true';assert state()['refreshes']==1
            call('click','cpu','false');wait(lambda s:s['resourcesLoaded'] and not s['networkLoaded'] and s['segments']==2)
            call('gap');wait(lambda s:s['segments']==3)
            subprocess.run(['grim','-o','Virtual-1','/tmp/widget-resources-fixture.png'],env=env,check=True,timeout=6)
            call('key','Escape');wait(lambda s:not s['resourcesLoaded'])
            print('PASS LAN/Wi-Fi exact-interface icon, fixed size, equal padding, exclusive popups and CPU/RAM gap rendering',flush=True)
            call('read','success');wait(lambda s:not s['readerBusy'] and bool(s['readerDetails']))
            assert state()['readerDetails']['GENERAL.CONNECTION']=='Test: profile'
            call('read','failure');wait(lambda s:not s['readerBusy'] and bool(s['readerError']))
            call('read','timeout');wait(lambda s:not s['readerBusy'] and 'timed out' in s['readerError'])
            print('PASS bounded history, rollback/malformed guards, network parsing/read failure/timeout',flush=True)
        finally:
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
    errors=[line for line in logpath.read_text().splitlines() if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no real mute, volume or network changes',flush=True)
