#!/usr/bin/env python3
"""8K previews and full-text reader, fake notification service on the VM."""
import json, os, shutil, socket, subprocess, tempfile, time
from pathlib import Path
assert socket.gethostname()=='j4n9-proxmox'
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='notification-reading-') as temporary:
    tree=Path(temporary)/'shell';shutil.copytree(source,tree)
    config=tree/'shell.qml'
    config.write_text((tree/'tests/NotificationReading.qml').read_text().replace('"../modules/','"modules/').replace('"../components"','"components"').replace('"../services"','"services"'))
    center=tree/'modules/notifications/NotificationCenter.qml'
    center.write_text(center.read_text().replace('import QtQuick\n','import QtQuick\nimport QtTest\n',1)
        .replace('    Components.Surface {','    Components.Surface {\n        objectName: "notificationFixtureSurface"\n        property TestEvent fixtureEvents: TestEvent {}',1))
    rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True));assert len(rows)==1
    env=dict(os.environ,XDG_STATE_HOME=str(Path(temporary)/'state'),WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    logpath=Path('/tmp/notification-reading-tests.log')
    def call(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','notificationReadingTest',method,*map(str,args)],env=env,capture_output=True,text=True,timeout=6)
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
            wait(lambda s:s['count']==1)
            call('open');wait(lambda s:s['opened']);time.sleep(.2);call('focusRow');wait(lambda s:s['listFocus'])
            s=state();width=s['width']
            assert s['stored']==8192 and s['fullStored']==s['expected']>8192 and s['previewLines']==4 and s['previewHeight']<350 and s['toastLimited'],s
            assert call('clickPreview')=='true';s=wait(lambda s:s['reading'] and s['bodyLength']==s['expected'])
            assert s['width']>width and s['fullSummary'] and s['invoked']==0,s
            assert call('wheel')=='true';wait(lambda s:s['scroll']>0)
            before=state()['scroll'];assert call('key','PageDown')=='true';wait(lambda s:s['scroll']>before+100)
            before=state()['scroll'];call('key','PageUp');wait(lambda s:s['scroll']<before-100)
            call('end');wait(lambda s:s['bodyEnd']<=s['readerHeight']+1)
            subprocess.run(['grim','-o','Virtual-1','/tmp/notification-reader-fixture.png'],env=env,check=True,timeout=6)
            call('key','Escape');wait(lambda s:not s['reading'] and s['opened'] and s['width']==width)
            call('focusRow');time.sleep(.1);call('key','Return');wait(lambda s:s['reading']);assert state()['invoked']==0
            assert call('invokeAction')=='true';assert state()['invoked']==1
            call('archive');wait(lambda s:not s['live']);assert state()['bodyLength']==state()['expected']
            print('PASS compact 8K previews; real click/Enter open wider full text; wheel/PageUp/PageDown/final line; Back/Escape; explicit action only',flush=True)
            generation=state()['generation'];config.write_text(config.read_text()+'\n// full reader reload\n')
            wait(lambda s:s['generation']>generation);call('open');time.sleep(.2);call('focusRow');wait(lambda s:s['listFocus']);assert call('clickPreview')=='true'
            s=wait(lambda s:s['reading'] and s['bodyLength']==s['expected'])
            assert s['stored']==8192 and s['fullAvailable'] and s['fullSummary'],s
            call('removeReading');wait(lambda s:not s['reading'] and s['count']==0);assert call('budget')=='true'
            assert call('clear')=='true';assert call('legacy')=='true';call('key','Escape');wait(lambda s:not s['opened'])
            print('PASS archived full text and real source reload, memory-budget eviction retains full newest text, clear removes full payloads',flush=True)
        finally:
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
    errors=[line for line in logpath.read_text().splitlines() if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no real notification server/history/DND/actions changed',flush=True)
