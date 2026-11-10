#!/usr/bin/env python3
"""Measure a disposable dashboard instance; never edit or restart the live shell."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time

SHELL = '''import QtQuick
import Quickshell
import Quickshell.Io
import "modules/dashboard" as Dashboard
ShellRoot {
    id: root
    property int remaining: 0
    property int completed: 0
    PersistentProperties {
        id: memory
        reloadableId: "dashboard-session"
        property bool opened: false
        onLoaded: dashboard.restoreSession(memory)
    }
    Dashboard.Dashboard { id: dashboard }
    Timer {
        id: cycles
        interval: INTERVAL
        repeat: true
        onTriggered: {
            if (dashboard.opened) {
                dashboard.close()
                root.completed++
                if (--root.remaining <= 0) stop()
            } else dashboard.open()
        }
    }
    IpcHandler {
        target: "memoryProbe"
        function run(count: int): void {
            root.remaining = count
            root.completed = 0
            cycles.start()
        }
        function collect(): void { gc() }
        function status(): string {
            return JSON.stringify({pid: Quickshell.processId, running: cycles.running,
                completed: root.completed, opened: dashboard.opened,
                loaded: dashboard.content !== null})
        }
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backend', choices=('offscreen', 'wayland'), default='offscreen')
    parser.add_argument('--batches', default='20,100,100,100')
    parser.add_argument('--interval-ms', type=int, default=120)
    parser.add_argument('--idle-seconds', type=float, default=5)
    parser.add_argument('--reloads', type=int, default=None, help='Defaults to 3 on Wayland, 0 offscreen')
    parser.add_argument('--diagnostic-gc', action='store_true', help='GC only in the disposable instance')
    parser.add_argument('--output', type=Path, required=True, help='New results directory; must not exist')
    args = parser.parse_args()
    if socket.gethostname() != 'j4n9-proxmox':
        parser.error('This project currently permits testing only on j4n9-proxmox')
    try:
        batches = [int(n) for n in args.batches.split(',')]
    except ValueError:
        parser.error('--batches must contain comma-separated integers')
    if args.reloads is None:
        args.reloads = 0 if args.backend == 'offscreen' else 3
    if args.backend == 'offscreen' and args.reloads:
        parser.error('Quickshell reload UI requires PanelWindow; use --backend wayland for reload tests')
    if not batches or min(batches) < 1 or args.interval_ms < 50 or args.idle_seconds <= 0 or args.reloads < 0:
        parser.error('Invalid count, interval, idle duration or reload count')
    qs = shutil.which('qs')
    if not qs:
        parser.error('qs must already be available in PATH')
    args.output.mkdir(parents=True, exist_ok=False)
    log_path = args.output / 'probe.log'
    results = {'host': socket.gethostname(), 'backend': args.backend,
               'interval_ms': args.interval_ms, 'samples': []}
    source = Path(__file__).resolve().parents[1]
    results.update(idle_seconds=args.idle_seconds, batches=batches, reloads=args.reloads,
                   diagnostic_gc=args.diagnostic_gc,
                   quick_backend=os.environ.get('QT_QUICK_BACKEND', 'default'),
                   qs_version=subprocess.run([qs, '-V'], capture_output=True, text=True,
                                             timeout=8).stdout.strip(),
                   source_sha256={name: hashlib.sha256((source / name).read_bytes()).hexdigest()
                                  for name in ('modules/dashboard/Dashboard.qml',
                                               'modules/dashboard/DashboardContent.qml',
                                               'components/MonthCalendar.qml')})

    with tempfile.TemporaryDirectory(prefix='dashboard-memory-') as temporary:
        tree = Path(temporary) / 'quickshell'
        shutil.copytree(source, tree)
        content = tree / 'modules/dashboard/DashboardContent.qml'
        text = content.read_text()
        text = text.replace('    id: root', '''    id: root
    Component.onCompleted: console.log("MEM_CONTENT_CREATE")
    Component.onDestruction: console.log("MEM_CONTENT_DESTROY")''', 1)
        marker = 'SystemClock { id: clock;'
        if marker not in text:
            raise RuntimeError('Update clock instrumentation for the current DashboardContent')
        text = text.replace(marker, '''SystemClock {
        Component.onCompleted: console.log("MEM_CLOCK_CREATE")
        Component.onDestruction: console.log("MEM_CLOCK_DESTROY")
        id: clock;''', 1)
        content.write_text(text)
        env = os.environ.copy()
        if args.backend == 'offscreen':
            # Test QML lifetime separately from layer-shell and GPU/Wayland allocations.
            panel = tree / 'modules/dashboard/Dashboard.qml'
            text = panel.read_text().replace('import QtQuick\n', 'import QtQuick\nimport QtQuick.Window\n', 1)
            text = text.replace('    PanelWindow {', '    Window {\n        width: 1280\n        height: 800', 1)
            for line in ('        focusable: true\n', '        aboveWindows: true\n',
                         '        exclusionMode: ExclusionMode.Ignore\n',
                         '        anchors { top: true; bottom: true; left: true; right: true }\n',
                         '        onBackingWindowVisibleChanged: if (backingWindowVisible) Qt.callLater(root.focusContent)\n'):
                text = text.replace(line, '')
            text = text.replace('window.backingWindowVisible', 'window.visible')
            panel.write_text(text)
            env.update(QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software')
        else:
            env['QT_QPA_PLATFORM'] = 'wayland'
            print('Wayland probe will show/hide its dashboard during each batch.', flush=True)
        config = tree / 'shell.qml'
        config.write_text(SHELL.replace('INTERVAL', str(args.interval_ms)))

        def ipc(target, method, *values):
            call = subprocess.run([qs, 'ipc', '-p', str(config), 'call', target, method,
                                   *map(str, values)], capture_output=True, text=True, timeout=8)
            if call.returncode:
                raise RuntimeError(call.stderr.strip() or call.stdout.strip())
            return call.stdout.strip()

        def state():
            return json.loads(ipc('memoryProbe', 'status'))

        def wait_for(predicate, timeout):
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise RuntimeError(f'Probe exited; inspect {log_path}')
                try:
                    current = state()
                    if predicate(current):
                        return current
                except (ValueError, RuntimeError):
                    pass  # IPC is briefly unavailable during QML reload.
                time.sleep(.2)
            raise TimeoutError(f'Probe did not reach expected state; inspect {log_path}')

        def memory(pid):
            data = {}
            for line in Path(f'/proc/{pid}/smaps_rollup').read_text().splitlines()[1:]:
                fields = line.split()
                if len(fields) >= 3 and fields[1].isdigit():
                    data[fields[0].rstrip(':')] = int(fields[1])
            stat = Path(f'/proc/{pid}/stat').read_text().split(') ')[1].split()
            return {'rss_kib': data['Rss'], 'pss_kib': data['Pss'],
                    'private_dirty_kib': data['Private_Dirty'],
                    'ticks': int(stat[11]) + int(stat[12])}

        def sample(label):
            first = memory(pid)
            start = time.monotonic()
            time.sleep(args.idle_seconds)
            row = memory(pid)
            row['cpu_percent_one_core'] = round((row.pop('ticks') - first['ticks']) /
                os.sysconf('SC_CLK_TCK') / (time.monotonic() - start) * 100, 2)
            log = log_path.read_text()
            row.update(label=label, elapsed_seconds=round(time.monotonic() - probe_started, 3),
                       state=state())
            for kind in ('CONTENT', 'CLOCK'):
                created = log.count(f'MEM_{kind}_CREATE')
                destroyed = log.count(f'MEM_{kind}_DESTROY')
                row[kind.lower() + '_created'] = created
                row[kind.lower() + '_destroyed'] = destroyed
                expected_alive = int(row['state']['loaded'])
                if created - destroyed != expected_alive:
                    raise AssertionError(f'{kind} lifecycle mismatch: {created}/{destroyed}')
            results['samples'].append(row)
            (args.output / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
            print(json.dumps(row), flush=True)

        probe_started = time.monotonic()
        with log_path.open('w') as log:
            process = subprocess.Popen([qs, '-p', str(config)], env=env, stdout=log, stderr=log)
            try:
                pid = wait_for(lambda _: True, 15)['pid']
                sample('idle')
                total = 0
                for count in batches:
                    ipc('memoryProbe', 'run', count)
                    wait_for(lambda row: not row['running'] and row['completed'] == count,
                             max(60, count * (2 * args.interval_ms / 1000 + 2)))
                    total += count
                    sample(f'after_{total}_cycles')
                for number in range(args.reloads):
                    ipc('dashboard', 'open')
                    wait_for(lambda row: row['opened'] and row['loaded'], 10)
                    offset = log_path.stat().st_size
                    config.write_text(config.read_text() + '\n')
                    deadline = time.monotonic() + 15
                    while 'Configuration Loaded' not in log_path.read_text()[offset:]:
                        if time.monotonic() > deadline:
                            raise TimeoutError('QML reload was not observed')
                        time.sleep(.2)
                    wait_for(lambda row: row['opened'] and row['loaded'], 15)
                    ipc('dashboard', 'close')
                    wait_for(lambda row: not row['opened'] and not row['loaded'], 10)
                    sample(f'after_reload_{number + 1}')
                if args.diagnostic_gc:
                    ipc('memoryProbe', 'collect')
                    sample('after_diagnostic_gc')
                print('PASS: all closed samples have balanced content/clock lifetimes.', flush=True)
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()


if __name__ == '__main__':
    main()
