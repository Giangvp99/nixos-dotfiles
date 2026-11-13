#!/usr/bin/env python3
"""Native dialog policy checks on VM; only temporary windows, no saves/downloads."""
import json, os, socket, subprocess, tempfile, time
from pathlib import Path
assert socket.gethostname()=='j4n9-proxmox'
fixture=Path(__file__).with_name('Dialogs.qml')
rows=json.loads(subprocess.check_output(['hyprctl','instances','-j'],text=True));assert len(rows)==1
instance=rows[0]
env=dict(os.environ,HYPRLAND_INSTANCE_SIGNATURE=instance['instance'],WAYLAND_DISPLAY=instance['wl_socket'])
def ctl(*args):
 result=subprocess.run(['hyprctl',*args],env=env,capture_output=True,text=True,timeout=8)
 if result.returncode:raise RuntimeError(result.stderr+result.stdout)
 return result.stdout.strip()
def data(name):return json.loads(ctl(name,'-j'))
initial=data('clients');active=data('activewindow').get('address');cursor=data('cursorpos')
assert not ctl('configerrors')
monitors=data('monitors');assert len(monitors)==1
monitor=monitors[0];assert not monitor['specialWorkspace']['name']
w=monitor['width']/monitor['scale'];h=monitor['height']/monitor['scale']
if monitor['transform']%2:w,h=h,w
logpath=Path('/tmp/hypr-dialog-tests.log')
with tempfile.TemporaryDirectory(prefix='hypr-dialogs-') as temporary:
 config=Path(temporary)/'shell.qml';config.write_text(fixture.read_text())
 def ipc(method,*args):
  result=subprocess.run(['qs','ipc','-p',str(config),'call','dialogTest',method,*args],env=env,capture_output=True,text=True,timeout=6)
  if result.returncode:raise RuntimeError(result.stderr+result.stdout)
  return result.stdout.strip()
 def test_clients():return [c for c in data('clients') if c['pid']==process.pid]
 def wait(predicate):
  end=time.monotonic()+12;last=None
  while time.monotonic()<end:
   if process.poll() is not None:raise RuntimeError(logpath.read_text())
   last=predicate()
   if last:return last
   time.sleep(.1)
  raise AssertionError('timeout\n'+logpath.read_text())
 def get(title):return next((c for c in test_clients() if c['title']==title),None)
 def close():
  ipc('close');wait(lambda:len(test_clients())==1)
 def check(c,kind):
  assert c['floating'],c
  assert any(tag.rstrip('*')==kind for tag in c['tags']),(kind,c)
  assert c['size'][0]<=w*.86+4 and c['size'][1]<=h*.80+4,c
  x,y=c['at'];cw,ch=c['size'];mx,my=monitor['x'],monitor['y']
  assert x>=mx and y>=my+monitor['reserved'][1]-3 and x+cw<=mx+w and y+ch<=my+h,c
  left,top,right,bottom=monitor['reserved']
  assert abs((x+cw/2)-(mx+left+(w-left-right)/2))<8 and abs((y+ch/2)-(my+top+(h-top-bottom)/2))<8,c
 with logpath.open('w') as log:
  process=subprocess.Popen(['qs','-p',str(config)],env=env,stdout=log,stderr=log)
  try:
   wait(lambda:get('Dialog fixture parent'))
   ipc('regular');plain=wait(lambda:get('Save As'))
   assert not any(t.rstrip('*') in ('file-dialog','temporary-dialog') for t in plain['tags']),plain
   assert not plain['floating'],plain
   close()
   for title,kind,ratio in [('Save As','file-dialog',(.66,.70)),('Open File','file-dialog',(.66,.70)),('Chọn tệp','file-dialog',(.66,.70)),('Downloads','download-dialog',(.52,.46)),('Are you sure?','temporary-dialog',None),('Confirmation','temporary-dialog',None)]:
    ipc('open',title)
    c=wait(lambda:get(title));time.sleep(.4);c=get(title);check(c,kind)
    if ratio:
     assert abs(c['size'][0]-w*ratio[0])<8 and abs(c['size'][1]-h*ratio[1])<8,(title,c)
    elif title=='Are you sure?':assert c['size'][0]<=350 and c['size'][1]<=200,c
    print('PASS',title,c['size'],c['at'],c['tags'],flush=True)
    if title=='Save As':
     subprocess.run(['grim','-o',monitor['name'],'/tmp/hypr-save-dialog.png'],env=env,check=True,timeout=6)
     ipc('grow');time.sleep(.5);grown=get(title)
     assert grown['size'][0]<=w*.86+4 and grown['size'][1]<=h*.80+4,grown
    close()
   ipc('picker');c=wait(lambda:get('Save As'));time.sleep(.5);check(get('Save As'),'file-dialog');close()
   print('PASS real Qt file chooser opened/cancelled; no save, no normal-window title false positive',flush=True)
   assert not ctl('configerrors')
  finally:
   process.terminate()
   try:process.wait(timeout=5)
   except subprocess.TimeoutExpired:process.kill();process.wait(timeout=5)
   if active and any(c['address']==active for c in data('clients')):
    code='local w=hl.get_window('+json.dumps('address:'+active)+'); if w then hl.dispatch(hl.dsp.focus({window=w})) end'
    ctl('eval',code)
   ctl('dispatch','movecursor',str(cursor['x']),str(cursor['y']))
 errors=[line for line in logpath.read_text().splitlines() if any(word in line for word in ('ReferenceError','TypeError','Binding loop','Unable to assign','Error:','Failed to load'))]
 assert not errors,'\n'.join(errors)
 original_ids={c['address'] for c in initial}
 assert original_ids.issubset({c['address'] for c in data('clients')}),'Original windows lost'
 print('PASS cleanup/focus restored; no original app closed or file saved; no config/QML errors',flush=True)
