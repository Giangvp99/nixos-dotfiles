#!/usr/bin/env python3
"""Production root reload/history and read-only native popup checks on the VM."""
import json, os, shutil, socket, subprocess, tempfile, time
from pathlib import Path
assert socket.gethostname()=='j4n9-proxmox'
source=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='widget-live-') as temporary:
    tree=Path(temporary)/'shell';shutil.copytree(source,tree)
    config=tree/'shell.qml'
    content=config.read_text().replace('import Quickshell\n','import Quickshell\nimport Quickshell.Io\n',1)
    config.write_text(content[:content.rfind('}')]+(tree/'tests/WidgetLiveHarness.inc').read_text()+'}\n')
    rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True));assert len(rows)==1
    env=dict(os.environ,XDG_STATE_HOME=str(Path(temporary)/'state'),WAYLAND_DISPLAY=rows[0]['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=rows[0]['instance'])
    logpath=Path('/tmp/widget-live-tests.log')
    def call(method,*args):
        result=subprocess.run(['qs','ipc','-p',str(config),'call','widgetLiveTest',method,*map(str,args)],env=env,capture_output=True,text=True,timeout=6)
        if result.returncode:raise RuntimeError(result.stderr+result.stdout)
        return result.stdout.strip()
    def state():return json.loads(call('status'))
    def wait(predicate):
        end=time.monotonic()+15;last=None
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
            initial=wait(lambda s:len(s['cpu'])>=2 and len(s['memory'])>=2)
            call('open','networkSpeed');wait(lambda s:s['loaded'] and s['readDone'])
            assert state()['fits'] and not state()['readError'],state()
            print('PASS native '+state()['kind']+' details read for '+state()['interfaceName']+' (no configuration writes)',flush=True)
            subprocess.run(['grim','-o','Virtual-1','/tmp/widget-network-live.png'],env=env,check=True,timeout=6)
            call('close');call('open','resourceUsage');wait(lambda s:s['loaded'])
            assert state()['fits']
            subprocess.run(['grim','-o','Virtual-1','/tmp/widget-resources-live.png'],env=env,check=True,timeout=6)
            cpuTime=state()['cpu'][-1]['at'];memoryTime=state()['memory'][-1]['at'];generation=state()['generation']
            config.write_text(config.read_text()+'\n// history live reload\n')
            restored=wait(lambda s:s['generation']>generation and len(s['cpu'])>=2)
            assert cpuTime in [point['at'] for point in restored['cpu']],restored
            assert memoryTime in [point['at'] for point in restored['memory']],restored
            call('open','barAudio');wait(lambda s:s['loaded']);assert state()['fits']
            subprocess.run(['grim','-o','Virtual-1','/tmp/widget-audio-live.png'],env=env,check=True,timeout=6)
            call('close');final=state()
            assert initial['audio']==final['audio'] and initial['wifi']==final['wifi'],(initial,final)
            assert len(final['cpu'])<=90 and len(final['memory'])<=90
            print('PASS production history survives source reload, native audio/resources popup fit and no volume/mute/Wi-Fi changes',flush=True)
        finally:
            process.terminate()
            try:process.wait(timeout=5)
            except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
    errors=[line for line in logpath.read_text().splitlines() if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:'))]
    assert not errors,'\n'.join(errors)
    print('PASS no new QML errors in production-root reload/read-only smoke',flush=True)
