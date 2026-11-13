#!/usr/bin/env python3
"""VM integration: isolated note storage and fake DND/mode, production persistence."""
import json, os, shutil, socket, subprocess, tempfile, time
from pathlib import Path
assert socket.gethostname() == 'j4n9-proxmox'
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='focus-notes-') as temporary:
    tree=Path(temporary)/'shell';shutil.copytree(source,tree)
    config=tree/'shell.qml'
    content=config.read_text().replace("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\nimport QtTest\n", 1)
    # Root already imports QtQuick and Quickshell.Io.
    content=content[:content.rfind('}')]+(tree/'tests/FocusNotesHarness.inc').read_text()+'}\n'
    config.write_text(content)
    rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True))
    assert len(rows)==1
    env=dict(os.environ, XDG_STATE_HOME=str(Path(temporary)/'state'),
             WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    logpath=Path('/tmp/focus-notes-tests.log')
    def ipc(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','focusNotesTest',method,*map(str,args)],env=env,capture_output=True,text=True,timeout=6)
        if result.returncode:raise RuntimeError(result.stderr+result.stdout)
        return result.stdout.strip()
    def state():return json.loads(ipc('status'))
    def wait(predicate):
        until=time.monotonic()+12;last=None
        while time.monotonic()<until:
            if process.poll() is not None:raise RuntimeError(logpath.read_text())
            try:
                last=state()
                if predicate(last):return last
            except (ValueError,RuntimeError) as e:last=str(e)
            time.sleep(.1)
        raise AssertionError((last,logpath.read_text()))
    def reload():
        generation=state()['generation'];config.write_text(config.read_text()+'\n// reload test\n')
        return wait(lambda s:s['generation']>generation and s['ready'])
    def launch(log):return subprocess.Popen(['qs','-p',str(config)],env=env,stdout=log,stderr=log)
    with logpath.open('w') as log:
        process=launch(log)
        try:
            wait(lambda s:s['ready'])
            subprocess.run(['qs','ipc','-p',str(config),'call','dashboard','open'],env=env,check=True,capture_output=True,timeout=6)
            time.sleep(.5)
            assert ipc('focusControl','focusPrimary')=='true'
            ipc('key','Return');wait(lambda s:s['status']=='running')
            ipc('key','Return');wait(lambda s:s['status']=='paused')
            assert ipc('focusControl','focusStop')=='true'
            ipc('key','Return');wait(lambda s:s['status']=='idle')
            assert ipc('focusControl','quickNotesEditor')=='true'
            ipc('uiText','UI note');ipc('key','Return');ipc('key','Save')
            wait(lambda s:s['text']=='UI note\n' and not s['dirty'])
            assert ipc('narrow')=='true'
            time.sleep(.2)
            ipc('key','Tab')
            layout=json.loads(ipc('uiLayout'))
            assert layout['width']==340 and layout['fits'] and layout['focus'] and 'quickNotesEditor' not in layout['focus'],layout
            print('PASS dashboard keyboard Start/Pause/End, note newline/Ctrl+S, Tab and narrow layout',flush=True)
            subprocess.run(['qs','ipc','-p',str(config),'call','dashboard','close'],env=env,check=True,capture_output=True,timeout=6)
            for seconds,mode in ((0,''),(10801,''),(25,'invalid')):assert ipc('start',seconds,'false',mode)=='false'
            assert ipc('start',60,'false','')=='true'
            assert ipc('start',60,'false','')=='false'
            assert state()['mode']=='' and not state()['dnd']
            ipc('pause');assert state()['status']=='paused' and not state()['timer']
            reload();assert state()['status']=='paused'
            ipc('resume');assert state()['timer'];ipc('stop')
            assert ipc('start',60,'true','code')=='true'
            assert state()['owned'] and state()['dnd'] and state()['mode']=='code'
            reload();assert state()['owned'] and state()['dnd']
            ipc('stop');assert not state()['dnd']
            ipc('toggle');ipc('start',60,'true','');ipc('stop');assert state()['dnd']
            ipc('toggle');ipc('start',60,'true','');ipc('toggle');ipc('toggle')
            assert not state()['owned'];ipc('stop');assert state()['dnd'];ipc('toggle')
            ipc('start',60,'true','');ipc('expire');assert state()['status']=='completed' and not state()['dnd'] and not state()['timer']
            ipc('start',1,'false','');wait(lambda s:s['status']=='completed')
            print('PASS focus validation, pause/resume, deadlines, DND ownership/manual override and live reload',flush=True)
            note='Ghi chú nhanh\n<b>plain text</b> ✓'
            ipc('edit',note);wait(lambda s:not s['dirty'] and not s['writing'])
            path=Path(state()['path']);assert path.is_relative_to(temporary) and path.read_text()==note
            assert path.parent.stat().st_mode & 0o777 == 0o700
            ipc('edit',note+'\nDraft before reload');reload()
            wait(lambda s:not s['dirty'] and not s['writing'])
            assert path.read_text()==note+'\nDraft before reload'
            path.parent.chmod(0o500)
            ipc('edit','Failed save draft');wait(lambda s:bool(s['error']))
            assert state()['dirty'] and state()['text']=='Failed save draft'
            path.parent.chmod(0o700);ipc('automaticSave');wait(lambda s:not s['dirty'] and not s['error'])
            assert path.read_text()=='Failed save draft'
            process.terminate();process.wait(timeout=5);process=launch(log)
            wait(lambda s:s['ready']);assert state()['text']=='Failed save draft'
            print('PASS Unicode/plain text, autosave, private directory, reload draft, write failure/retry and process restart',flush=True)
        finally:
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
    errors=[line for line in logpath.read_text().splitlines() if any(x in line for x in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no QML errors; no real DND/mode/note changes',flush=True)
