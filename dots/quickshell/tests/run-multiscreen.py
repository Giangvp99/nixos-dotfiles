#!/usr/bin/env python3
"""Native screen-routing regression on the VM with temporary headless outputs."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

if socket.gethostname()!='j4n9-proxmox': raise SystemExit('Run only on j4n9-proxmox')
def run(*args,env=None):
    result=subprocess.run(args,text=True,capture_output=True,timeout=10,env=env)
    if result.returncode or result.stdout.strip().startswith('error:'):
        raise RuntimeError(result.stderr or result.stdout)
    return result.stdout.strip()
instances=json.loads(run('hyprctl','instances','-j'))
if len(instances)!=1: raise SystemExit('Exactly one compositor required')
instance=instances[0]
def hypr(*args): return run('hyprctl','-i',instance['instance'],*args)
def read(name): return json.loads(hypr('-j',name))
def lua(body): return hypr('dispatch','function() '+body+' end')
initial_monitors=read('monitors')
if len(initial_monitors)!=1: raise SystemExit('Requires one initial monitor')
original=initial_monitors[0]['name']
workspace=initial_monitors[0]['activeWorkspace']['name']
active=read('activewindow').get('address')
cursor=read('cursorpos')
original_clients=read('clients')
source=Path(__file__).resolve().parents[1]
env=dict(os.environ,WAYLAND_DISPLAY=instance['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=instance['instance'])
owned=set()
output=None
process=None
terminal=None
log_path=Path('/tmp/multiscreen-tests.log')
def focus(name):
    monitor=next(m for m in read('monitors') if m['name']==name)
    x=round(monitor['x']+monitor['width']/monitor['scale']/2)
    y=round(monitor['y']+monitor['height']/monitor['scale']/2)
    lua('hl.dispatch(hl.dsp.cursor.move({x='+str(x)+',y='+str(y)+'})); '
        'local monitor=hl.get_monitor('+json.dumps(name)+'); assert(monitor); hl.dispatch(hl.dsp.focus({monitor=monitor}))')
def output_create(scale):
    names={m['name'] for m in read('monitors')}
    hypr('output','create','headless')
    deadline=time.monotonic()+8
    while time.monotonic()<deadline:
        new=[m['name'] for m in read('monitors') if m['name'] not in names]
        if new:
            name=new[0];owned.add(name)
            lua('hl.monitor({output='+json.dumps(name)+',mode="1920x1080@60",position="auto",scale='+str(scale)+'})')
            return name
        time.sleep(.1)
    raise AssertionError('Headless output did not appear')
def output_remove(name):
    hypr('output','remove',name)
    owned.discard(name)
with tempfile.TemporaryDirectory(prefix='multi-screen-') as directory:
    tree=Path(directory)/'quickshell'
    shutil.copytree(source,tree)
    config=tree/'shell.qml'
    text=config.read_text().replace('import QtQuick','import Quickshell.Hyprland\nimport Quickshell.Io\nimport QtQuick',1)
    text=text.replace('ShellRoot {','ShellRoot {\n'+(tree/'tests/MultiScreenHarness.inc').read_text(),1)
    text=text.replace('id: keybinds','id: keybinds\n        shortcutAppId: "multi-screen-test"',1)
    text=text.replace('id: launcher','id: launcher\n        shortcutAppId: "multi-screen-test"',1)
    config.write_text(text)
    def ipc(method,*args):
        return run('qs','ipc','-p',str(config),'call','screenTest',method,*map(str,args),env=env)
    def state(): return json.loads(ipc('status'))
    def wait(predicate):
        deadline=time.monotonic()+12
        last=None
        while time.monotonic()<deadline:
            if process.poll() is not None: raise RuntimeError(log_path.read_text())
            try:
                last=state()
                if predicate(last): return last
            except (ValueError,RuntimeError) as error:last=str(error)
            time.sleep(.1)
        raise AssertionError(str(last)+'\n'+log_path.read_text())
    def focus_and_wait(name):
        focus(name)
        try: wait(lambda s:s['focused']==name)
        except AssertionError as error:
            raise AssertionError({'nativeFocused':[m['name'] for m in read('monitors') if m['focused']], 'shell':state()}) from error
    def bar(s,name): return next(row for row in s['bars'] if row['screen']==name)
    def fits(s,which):
        item=s[which];x,y,w,h=item['surface'];ww,wh=item['size']
        assert x>=0 and y>=0 and x+w<=ww+1 and y+h<=wh+1,(which,item)
    with log_path.open('w') as log:
        try:
            process=subprocess.Popen(['qs','-p',str(config)],stdout=log,stderr=log,env=env)
            wait(lambda s:len(s['bars'])==1 and len(s['centers'])==1)
            for scale in (1,2):
                output=output_create(scale)
                wait(lambda s:len(s['bars'])==2 and len(s['centers'])==2)
                focus_and_wait(output)
                lua('hl.dispatch(hl.dsp.focus({workspace="name:mode-code-secondary",on_current_monitor=true}))')
                wait(lambda s:bar(s,output)['workspace']=='mode-code-secondary' and bar(s,output)['mode']=='code')
                assert bar(state(),original)['workspace']==workspace
                # Window model belongs to its workspace even when another monitor has focus.
                if terminal is None:
                    test_class='multiscreen-'+str(os.getpid())
                    terminal=subprocess.Popen(['kitty','--class',test_class,'--title','Screen test','sleep','600'],
                                              env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                    deadline=time.monotonic()+8
                    address=None
                    while time.monotonic()<deadline:
                        address=next((c['address'] for c in read('clients') if c['class']==test_class),None)
                        if address:break
                        time.sleep(.1)
                    assert address,'Test terminal did not map'
                lua('hl.dispatch(hl.dsp.window.move({window=hl.get_window('+json.dumps('address:'+address)+'),workspace="name:mode-code-secondary",follow=false}))')
                wait(lambda s:address.replace('0x','') in [a.replace('0x','') for a in bar(s,output)['apps']])
                focus_and_wait(original)
                s=wait(lambda s:bar(s,output)['mode']=='code')
                assert address.replace('0x','') not in [a.replace('0x','') for a in bar(s,original)['apps']]
                assert address.replace('0x','') in [a.replace('0x','') for a in bar(s,output)['apps']]
                # The minimized tail follows its recorded origin monitor, not global focus.
                lua('local window=hl.get_window('+json.dumps('address:'+address)+'); '
                    'hl.dispatch(hl.dsp.window.tag({window=window,tag="+minimized"})); '
                    'hl.dispatch(hl.dsp.window.tag({window=window,tag="+minimized-from-name:mode-code-secondary"})); '
                    'hl.dispatch(hl.dsp.window.move({window=window,workspace="special:minimized",follow=false}))')
                wait(lambda s:address.replace('0x','') in [a.replace('0x','') for a in bar(s,output)['apps']])
                assert address.replace('0x','') not in [a.replace('0x','') for a in bar(state(),original)['apps']]
                lua('local window=hl.get_window('+json.dumps('address:'+address)+'); '
                    'hl.dispatch(hl.dsp.window.move({window=window,workspace="name:mode-code-secondary",follow=false})); '
                    'hl.dispatch(hl.dsp.window.tag({window=window,tag="-minimized"})); '
                    'hl.dispatch(hl.dsp.window.tag({window=window,tag="-minimized-from-name:mode-code-secondary"}))')
                focus_and_wait(output)
                for which in ('launcher','dashboard','keybinds'):
                    ipc('open',which)
                    s=wait(lambda s:s[which]['opened'] and s[which]['screen']==output and s[which]['surface'][2]>0)
                    fits(s,which)
                    if which=='dashboard':
                        time.sleep(.2)
                        subprocess.run(['grim','-o',output,'/tmp/multiscreen-dashboard-scale-'+str(scale)+'.png'],env=env,check=True,timeout=5)
                    focus_and_wait(original)
                    assert state()[which]['screen']==output,(which,state())
                    # An open() call must not silently move the existing overlay.
                    ipc('open',which);assert state()[which]['screen']==output
                    ipc('closeAll');focus_and_wait(output)
                # Bar origin takes priority over global focus; handoff preserves capture.
                ipc('dashboardFromBar',original)
                wait(lambda s:s['dashboard']['opened'] and s['dashboard']['screen']==original)
                ipc('closeAll');focus_and_wait(output)
                ipc('open','dashboard');wait(lambda s:s['dashboard']['screen']==output and s['dashboard']['opened'])
                focus_and_wait(original);ipc('help')
                wait(lambda s:s['keybinds']['opened'] and s['keybinds']['screen']==output and not s['dashboard']['opened'])
                ipc('closeAll');focus_and_wait(output)
                ipc('date',output)
                s=wait(lambda s:s['popup'] and s['popup']['visible'])
                assert s['popup']['screen']==output and s['popup']['anchor']==output,s
                ipc('closeAll')
                # QML reload preserves the chosen screen while focus is elsewhere.
                focus_and_wait(output);ipc('open','dashboard');wait(lambda s:s['dashboard']['opened'])
                focus_and_wait(original);generation=state()['generation']
                config.write_text(config.read_text()+'\n// multi-screen reload '+str(scale)+'\n')
                s=wait(lambda s:s['generation']>generation and s['dashboard']['opened'] and s['dashboard']['surface'][2]>0)
                assert s['dashboard']['screen']==output,s
                ipc('closeAll')
                subprocess.run(['grim','-o',output,'/tmp/multiscreen-scale-'+str(scale)+'.png'],env=env,check=True,timeout=5)
                focus_and_wait(output);ipc('osd',60+scale)
                wait(lambda s:s['osd']['shown'] and s['osd']['screen']==output)
                focus_and_wait(original);assert state()['osd']['screen']==output
                focus_and_wait(output);ipc('open','launcher');wait(lambda s:s['launcher']['opened'])
                output_remove(output);output=None
                s=wait(lambda s:len(s['bars'])==1 and not s['launcher']['opened'] and not s['osd']['shown'] and len(s['centers'])==1)
                assert not s['centerOpen']
                print('PASS scale '+str(scale)+': per-screen bars/windows, captured overlays, origin/handoff, popup, reload, OSD and hot-unplug',flush=True)
            for which in ('dashboard','keybinds','popup','center'):
                output=output_create(1)
                wait(lambda s:len(s['bars'])==2 and len(s['centers'])==2)
                focus_and_wait(output)
                if which in ('dashboard','keybinds'):
                    ipc('open',which);wait(lambda s:s[which]['opened'])
                elif which=='popup':
                    ipc('date',output);wait(lambda s:s['popup'] and s['popup']['visible'])
                else:
                    ipc('center',output);wait(lambda s:s['centerOpen'])
                output_remove(output);output=None
                s=wait(lambda s:len(s['bars'])==1 and len(s['centers'])==1 and not s['dashboard']['opened'] and not s['keybinds']['opened'] and not s['popup'] and not s['centerOpen'])
                print('PASS unplug cleanup: '+which,flush=True)
            ipc('closeAll')
        finally:
            if terminal:
                terminal.terminate()
                try:terminal.wait(timeout=5)
                except subprocess.TimeoutExpired:terminal.kill();terminal.wait(timeout=5)
            if process:
                process.terminate()
                try:process.wait(timeout=5)
                except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
            for name in list(owned):
                if any(m['name']==name for m in read('monitors')):output_remove(name)
            # Clear only temporary in-memory monitor rules via the existing config.
            hypr('reload')
            focus(original)
            selector=workspace if workspace.isdigit() else 'name:'+workspace
            lua('hl.dispatch(hl.dsp.focus({workspace='+json.dumps(selector)+',on_current_monitor=true}))')
            if active and any(c['address']==active for c in read('clients')):
                lua('hl.dispatch(hl.dsp.focus({window=hl.get_window('+json.dumps('address:'+active)+')}))')
            lua('hl.dispatch(hl.dsp.cursor.move({x='+str(cursor['x'])+',y='+str(cursor['y'])+'}))')
    assert len(read('monitors'))==1
    for before in original_clients:
        after=next((c for c in read('clients') if c['address']==before['address']),None)
        assert after and after['workspace']==before['workspace'] and after['tags']==before['tags'],'Original client state changed'
    errors=[line for line in log_path.read_text().splitlines() if any(word in line for word in
        ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; test outputs/window removed, original focus/workspace/clients restored',flush=True)
