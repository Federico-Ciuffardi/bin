#!/usr/bin/env python

import subprocess
from functools import partial


cmd_run = partial(subprocess.Popen, text=True, shell=True)


def cmd_output(cmd):
    try:
        out = subprocess.check_output(cmd, text=True, shell=True).strip()
    except Exception:
        out = ''
    return out


def execute(cmd):
    popen = subprocess.Popen(cmd, stdout=subprocess.PIPE,
                             universal_newlines=True, text=True, shell=True)
    for stdout_line in iter(popen.stdout.readline, ""):
        yield stdout_line
    popen.stdout.close()
    return_code = popen.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, cmd)


def is_fullscreen(wid):
    return cmd_output(f'bspc query -N -n {wid}.fullscreen').strip()


def is_floating(wid):
    return cmd_output(f'bspc query -N -n {wid}.floating').strip()
    


def get_pid(wid):
    out = cmd_output(f'xprop -id {wid} | grep WM_PID')
    if out:
        return out.split(' = ')[1]
    else:
        return ''


def is_child(pid, child_pid):
    tree = cmd_output(f'pstree -T -p {pid}')
    for line in tree.split('\n'):
        if child_pid in line:
            return True
    return False


terminal = cmd_output("echo $TERMINAL | awk -F \"/\" '{print $NF}'")


def is_terminal(wid):
    pid = cmd_output('xdotool getwindowpid '+wid)
    p_name = cmd_output("ps -e | grep "+pid+" | awk '{print $4}'")
    #print(pid)
    #print(p_name)
    return p_name == 'st'



swallowed = {}
for event in execute('bspc subscribe all'):
    event = event.split()
    if event[0] == 'node_add':
        new_wid = event[-1]
        last_wid = cmd_output('bspc query -N -d -n last.window')
        if any([is_floating(new_wid), is_floating(last_wid),
                is_fullscreen(new_wid), is_fullscreen(last_wid), not is_terminal(last_wid)]):
            continue
        new_pid = get_pid(new_wid)
        last_pid = get_pid(last_wid)
        if not all([new_pid, last_pid]):
            continue
        if is_child(last_pid, new_pid):
            #cmd_run(f'bspc node --swap {last_wid} --follow')
            #cmd_run(f'bspc node {new_wid} --flag private=on')
            #cmd_run(f'bspc node {last_wid} --flag hidden=on')
            #cmd_run(f'bspc node {last_wid} --flag private=on')
            cmd_run(f'bspc node {last_wid} -d M')
            cmd_run(f'bspc node {last_wid} -g hidden=on')
            swallowed[new_wid] = last_wid
    if event[0] == 'node_remove':
        removed_wid = event[-1]
        if removed_wid in swallowed.keys():
            swallowed_id = swallowed[removed_wid]
            cmd_run(f'bspc node {swallowed_id} -d focused -g hidden=off -f')
            #cmd_run(f'bspc node {swallowed_id} --flag hidden=off')
            #cmd_run(f'bspc node --focus {swallowed_id}')
