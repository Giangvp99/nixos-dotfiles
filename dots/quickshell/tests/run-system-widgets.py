#!/usr/bin/env python3
"""Test in a disposable copy on the VM. No real battery/network changes."""
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
instances = json.loads(subprocess.check_output(['hyprctl', 'instances', '-j'], text=True, timeout=5))
if len(instances) != 1:
    raise SystemExit('Exactly one Hyprland instance required')
test_env = dict(os.environ, WAYLAND_DISPLAY=instances[0]['wl_socket'],
                HYPRLAND_INSTANCE_SIGNATURE=instances[0]['instance'])
source = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='system-widgets-') as directory:
    tree = Path(directory) / 'quickshell'
    shutil.copytree(source, tree)
    # Place imports within the disposable shell root scanned by Quickshell.
    config = tree / 'shell.qml'
    config.write_text((tree / 'tests/SystemWidgets.qml').read_text()
        .replace('"../modules/', '"modules/').replace('"../services"', '"services"')
        .replace('"../utils/', '"utils/').replace('"../config"', '"config"'))
    sensors = Path(directory) / 'sensors'
    sensors.mkdir()
    for name, value in [('temp1_input', '45000'), ('temp2_input', '55000')]:
        (sensors / name).write_text(value)
    settings = tree / 'config/Config.qml'
    settings.write_text(settings.read_text().replace('networkRateInterface: ""', 'networkRateInterface: "test0"')
        .replace('temperatureSensorPaths: []', 'temperatureSensorPaths: ["/sys/class/hwmon/hwmon999/temp1_input", "/sys/class/hwmon/hwmon999/temp2_input"]'))
    monitor = tree / 'services/SystemMonitor.qml'
    monitor.write_text(monitor.read_text().replace('path: modelData.path',
        'path: ' + json.dumps(str(sensors) + '/') + ' + modelData.path.split("/").pop()'))
    audio_file=tree / 'modules/bar/widgets/Audio.qml'
    audio_text=audio_file.read_text().replace('    id: root','    id: root\n    property int wheelEvents: 0',1)
    start=audio_text.index('    onScrolled: delta => {')
    end=audio_text.index('\n    }',start)+len('\n    }')
    audio_file.write_text(audio_text[:start]+'    onScrolled: delta => { wheelEvents++ }'+audio_text[end:])
    log_path = Path('/tmp/system-widgets-tests.log')
    def ipc(method, *args):
        result = subprocess.run(['qs', 'ipc', '-p', str(config), 'call', 'systemWidgetsTest', method,
                                 *map(str, args)], capture_output=True, text=True, timeout=8, env=test_env)
        if result.returncode:
            raise RuntimeError(result.stderr or result.stdout)
        return result.stdout.strip()
    def state():
        time.sleep(.12)
        return json.loads(ipc('state'))
    def wait(predicate):
        value=None
        for _ in range(60):
            try:
                value=state()
                if predicate(value): return value
            except (ValueError, RuntimeError): pass
            time.sleep(.1)
        raise AssertionError('Expected state unavailable: ' + str(value))
    with log_path.open('w') as log:
        process = subprocess.Popen(['qs', '-p', str(config)], stdout=log, stderr=log, env=test_env)
        try:
            wait(lambda row: row['temperatureAvailable'])
            print(ipc('unitTests'), flush=True)
            ipc('metrics')
            data=state()
            assert data['cpuAvailable'] and data['cpu']==95 and data['memory']==92, data
            assert data['network'] and data['download']==1048576 and data['upload']==524288, data
            assert data['temperature']==55, data
            widgets=json.loads(ipc('widgetState'))
            assert next(w for w in widgets['widgets'] if w['name']=='resourceUsage')['foreground']==widgets['warning'], widgets
            assert widgets['cpuIcon']!=widgets['ramIcon'],widgets
            for availability, expected in [('none',set()),('cpu',{'resourceUsage'}),('memory',{'resourceUsage'}),('idleNetwork',{'networkSpeed'})]:
                ipc('availability',availability);widget_data=json.loads(ipc('widgetState'))['widgets']
                assert {w['name'] for w in widget_data if w['visible']}==expected,(availability,widget_data)
                if availability in ('cpu','memory'):
                    assert next(w for w in widget_data if w['name']=='resourceUsage')['width']==60,widget_data
            ipc('metrics');ipc('reloadSensors');wait(lambda row: row['temperatureAvailable'])
            print('PASS distinct CPU/RAM icons, missing data hidden, partial resources compact, zero traffic remains visible',flush=True)
            cases={
                'charging': {'percent':78,'charging':True,'plugged':True,'status':'Charging'},
                'full': {'percent':100,'charging':False,'plugged':True,'status':'Full'},
                'paused': {'charging':False,'plugged':True,'status':'Charge paused'},
                'low': {'percent':10,'onBattery':True,'low':True,'critical':False},
                'critical': {'percent':4,'critical':True},
                'tiny': {'percent':1,'critical':True},
                'acDrain': {'plugged':True,'status':'Discharging','low':True},
                'unknown': {'status':'Unknown'},
                'absent': {'available':False},'mouse': {'available':False},'unready': {'available':False},
                'invalid': {'available':True,'known':False}
            }
            fixed_widths={w['name']:w['width'] for w in json.loads(ipc('widgetState'))['widgets']}
            for name, expected in cases.items():
                ipc('powerCase', name); data=state()['battery']
                assert all(data[key]==value for key,value in expected.items()), (name,data)
                widgets=json.loads(ipc('widgetState')); widget=next(w for w in widgets['widgets'] if w['name']=='batteryStatus')
                assert 'NaN' not in widget['text'], widget
                assert all(w['width']==fixed_widths[w['name']] for w in widgets['widgets']),widgets
                if name=='critical': assert widget['foreground']==widgets['critical'], widget
                if name=='paused': assert 'AC' in widget['text'] and '‖' in widget['text'], widget
            print('PASS battery charging/full/paused/low/critical/<1%/AC drain/unknown/missing/invalid states', flush=True)
            (sensors/'temp1_input').write_text('99000'); ipc('reloadSensors')
            wait(lambda row: row['temperature']==99)
            widgets=json.loads(ipc('widgetState'))
            assert next(w for w in widgets['widgets'] if w['name']=='temperatureStatus')['foreground']==widgets['critical'],widgets
            (sensors/'temp1_input').unlink(); (sensors/'temp2_input').unlink(); ipc('reloadSensors')
            wait(lambda row: not row['temperatureAvailable'])
            (sensors/'temp2_input').write_text('42000'); ipc('reloadSensors')
            wait(lambda row: row['temperatureAvailable'] and row['temperature']==42)
            print('PASS native FileView sensor loading, maximum, disappearance and recovery', flush=True)
            ipc('powerCase','charging')
            for width in (480,640,800,1600):
                ipc('resize',width); data=wait(lambda row: row['barWidth']==width)
                for item in data['essential']:
                    if item['visible']:
                        assert item['x']>=-.1 and item['x']+item['width']<=width+.1, (width,item)
                if width==480:
                    assert ipc('wheelMetrics')=='true'
                    assert state()['viewport'][2]>0, 'Vertical wheel did not scroll metrics'
                    wheel=json.loads(ipc('wheelAudio'))
                    assert wheel['delivered'] and wheel['count']==1 and wheel['before']==wheel['after'],wheel
                power_control=next(item for item in data['essential'] if item['name']=='barPowerMenu')
                assert abs(power_control['x']+power_control['width']-(width-data['rightInset']))<.1,(width,power_control)
                ipc('scrollEnd'); data=state()
                assert data['viewport'][2]>=0, data
            ipc('openMetricsPopup'); time.sleep(.3)
            anchor=json.loads(ipc('popupAnchor')); assert anchor['visible'] and anchor['x']==anchor['expected'],anchor
            before={w['name']:(w['width'],w['x']) for w in json.loads(ipc('widgetState'))['widgets']}
            ipc('shrinkRate'); time.sleep(.3)
            after={w['name']:(w['width'],w['x']) for w in json.loads(ipc('widgetState'))['widgets']}
            assert before==after,(before,after)
            print('PASS fixed widths across power states and stable widget positions across rate changes',flush=True)
            anchor=json.loads(ipc('popupAnchor')); assert anchor['x']==anchor['expected'],anchor
            ipc('resize',640);wait(lambda row: row['barWidth']==640);ipc('scrollEnd');time.sleep(.3)
            anchor=json.loads(ipc('popupAnchor')); assert anchor['x']==anchor['expected'],anchor
            ipc('closeMetricsPopup');ipc('resize',1600);wait(lambda row: row['barWidth']==1600)
            print('PASS popup anchor follows changing metric widths, resize and horizontal scroll',flush=True)
            subprocess.run(['grim','/tmp/system-widgets-fixture.png'],check=True,env=test_env)
            print('PASS fixed notification/date/clock/keyboard/power controls at 480/640/800/1600; vertical wheel scrolls metrics and audio wheel is preserved', flush=True)
        finally:
            if process.poll() is None:
                process.terminate(); process.wait(timeout=5)
    # Exercise the literal discovery script too, using a fake sysfs tree in the copy.
    settings.write_text(settings.read_text().replace('temperatureSensorPaths: ["/sys/class/hwmon/hwmon999/temp1_input", "/sys/class/hwmon/hwmon999/temp2_input"]', 'temperatureSensorPaths: []'))
    fake_sys=Path(directory)/'fake-sys'
    for folder, driver, values in [('hwmon0','nvme',[('temp1','99000','Composite')]),
                                    ('hwmon1','coretemp',[('temp1','45000','Package id 0'),('temp2','80000','Core 0')])]:
        base=fake_sys/'sys/class/hwmon'/folder
        base.mkdir(parents=True)
        (base/'name').write_text(driver+'\n')
        for sensor,value,label in values:
            (base/(sensor+'_input')).write_text(value+'\n')
            (base/(sensor+'_label')).write_text(label+'\n')
    native_monitor=(source/'services/SystemMonitor.qml').read_text()
    native_monitor=native_monitor.replace('/sys/class/',str(fake_sys)+'/sys/class/')
    native_monitor=native_monitor.replace('path: modelData.path','path: '+json.dumps(str(fake_sys))+' + modelData.path')
    native_monitor=native_monitor.replace('Metrics.sensors(text)','Metrics.sensors(text.split('+json.dumps(str(fake_sys))+').join(""))')
    monitor.write_text(native_monitor)
    with log_path.open('a') as log:
        process=subprocess.Popen(['qs','-p',str(config)],stdout=log,stderr=log,env=test_env)
        try:
            data=wait(lambda row: row['temperatureAvailable'] and row['temperature']==45)
            assert len(data['sensors'])==1 and data['sensors'][0]['driver']=='coretemp',data
            (fake_sys/'sys/class/hwmon/hwmon1/temp1_input').unlink()
            ipc('rescan');wait(lambda row: row['temperature']==80)
            (fake_sys/'sys/class/hwmon/hwmon1/temp2_input').unlink()
            ipc('rescan');data=wait(lambda row: row['temperature']==99)
            assert data['sensors'][0]['driver']=='nvme',data
            (fake_sys/'sys/class/hwmon/hwmon0/temp1_input').unlink()
            ipc('rescan');wait(lambda row: not row['temperatureAvailable'])
            print('PASS native discovery/package priority, CPU fallback, generic sensor fallback and hotplug rescan',flush=True)
        finally:
            if process.poll() is None:
                process.terminate();process.wait(timeout=5)
    text=log_path.read_text()
    assert all(message not in text for message in ('TypeError','ReferenceError','Binding loop','invalid context')), text
    print('PASS no new QML runtime warnings; real device state untouched', flush=True)
