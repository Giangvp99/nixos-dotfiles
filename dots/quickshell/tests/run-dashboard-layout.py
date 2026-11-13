#!/usr/bin/env python3
"""No-scroll dashboard geometry, paging and reload on Proxmox, fake backends only."""
import json, os, shutil, socket, subprocess, tempfile, time
from pathlib import Path
assert socket.gethostname() == 'j4n9-proxmox'
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='dashboard-layout-') as temporary:
    tree=Path(temporary)/'shell';shutil.copytree(source,tree)
    config=tree/'shell.qml'
    content=config.read_text().replace('import Quickshell\n','import Quickshell\nimport Quickshell.Io\nimport QtTest\n',1)
    config.write_text(content[:content.rfind('}')]+(tree/'tests/DashboardLayoutHarness.inc').read_text()+'}\n')
    rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True));assert len(rows)==1
    env=dict(os.environ,XDG_STATE_HOME=str(Path(temporary)/'state'),WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    logpath=Path('/tmp/dashboard-layout-tests.log')
    def ipc(target,method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call',target,method,*map(str,args)],env=env,capture_output=True,text=True,timeout=6)
        if result.returncode:raise RuntimeError(result.stderr+result.stdout)
        return result.stdout.strip()
    def call(method,*args):return ipc('layoutTest',method,*args)
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
    def geometry():
        time.sleep(.15);s=state()
        assert s['fits'] and not s['scroll'],s
        for card in s['cards']:
            assert card['x']>=-1 and card['y']>=-1 and card['x']+card['w']<=s['width']+1 and card['y']+card['h']<=s['height']+1,(card,s)
            required = 230 if card['name']=='dashboardCalendarCard' else 180 if card['name']=='dashboardNotes' else card['natural']
            assert card['h']+1>=required,(card,s)
        for i,a in enumerate(s['cards']):
            for b in s['cards'][i+1:]:
                overlap=min(a['x']+a['w'],b['x']+b['w'])-max(a['x'],b['x'])>1 and min(a['y']+a['h'],b['y']+b['h'])-max(a['y'],b['y'])>1
                assert not overlap,(a,b)
        return s
    with logpath.open('w') as log:
        process=subprocess.Popen(['qs','-p',str(config)],env=env,stdout=log,stderr=log)
        try:
            # IPC becomes available before the lazy content is created.
            until=time.monotonic()+12
            while True:
                try:ipc('dashboard','open');break
                except RuntimeError:
                    if time.monotonic()>until:raise RuntimeError(logpath.read_text())
                    time.sleep(.1)
            wait(lambda s:s['loaded']);call('inject');s=geometry()
            assert s['overview'] and len(s['cards'])==6,s
            # All top and bottom card boundaries line up.
            top=[c for c in s['cards'] if c['name'] in ('dashboardFocus','dashboardAudio','dashboardNotes')]
            assert max(c['y'] for c in top)-min(c['y'] for c in top)<1
            assert max(c['h'] for c in top)-min(c['h'] for c in top)<1
            for name,card,row,last in (
                ('dashboardOutputDevices','dashboardAudio','dashboardOutputDevice_2','selectedOutput'),
                ('dashboardInputDevices','dashboardAudio','dashboardInputDevice_2',None),
                ('dashboardNetworks','dashboardNetworkCard','dashboardNetwork_2','selectedNetwork'),
                ('mediaChoosePlayer','dashboardMedia','mediaPlayer_2','selectedPlayer')):
                assert call('expand',name)=='true';geometry()
                assert call('nextChoices',card)=='true';geometry()
                assert row in state()['targets'],state()
                assert call('expand',row)=='true'
                if last:assert state()[last]==2,state()
                geometry()
            subprocess.run(['grim','-o','Virtual-1','/tmp/dashboard-layout-mocks.png'],env=env,check=True,timeout=6)
            print('PASS three-column aligned rows, no outer scroll, expanded selectors, all choices via pagination',flush=True)
            assert call('focus','dashboardClose')=='true'
            seen=set()
            for _ in range(len(state()['targets'])+1):
                call('key','Tab');s=geometry();assert s['focus'],s
                seen.update(s['focus'])
            assert {'dashboardClose','focusPrimary','quickNotesEditor','dashboardShortcuts'}.issubset(seen),seen
            call('selectPage',3)
            generation=state()['generation'];config.write_text(config.read_text()+'\n// dashboard layout reload\n')
            wait(lambda s:s['loaded'] and s['generation']>generation);call('inject');geometry()
            assert state()['page']==3,state()
            print('PASS complete keyboard cycle and production live reload',flush=True)
            for width,height in ((1000,708),(720,600),(340,600)):
                call('resize',width,height)
                for page in range(6):
                    call('selectPage',page);s=geometry()
                    assert not s['overview'] and len(s['cards'])==1,(width,height,page,s)
                call('selectPage',2);call('expand','dashboardNetworks');geometry()
                assert state()['scanning']
                assert call('focus','dashboardPage_3')=='true'
                call('key','Return');geometry();assert state()['page']==3 and not state()['scanning']
            print('PASS 1000/720/340px no-scroll pages and scan stops on page change',flush=True)
            ipc('dashboard','close');wait(lambda s:not s['loaded'])
        finally:
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
    errors=[line for line in logpath.read_text().splitlines() if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no real audio/network/media/DND/note actions',flush=True)
