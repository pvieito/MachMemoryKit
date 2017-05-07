#!/usr/bin/env python3
'''amfid_patch.py - Pedro José Pereira Vieito © 2016
    This script can patch macOS 10.12.2 amfid daemon on memory 
    to allow arbitrary entitlements in Developer ID signed binaries.
    
    Killing amfid will make the patch disapear:
    $ sudo kill -9 `pgrep amfid`
    
    You must run the script as a root (sudo) and with SIP disabled.
    
    You can get the PyMach Python module from here:
    PyMach: https://github.com/pvieito/PyMach

Usage:
    amfid_patch.py [-h]
    
Options:
    -h, --help        Show this help
'''

import mach
import sys
import os
import binascii
from subprocess import check_output
from docopt import docopt
from distutils.util import strtobool

args = docopt(__doc__)


def get_pid(name):
    try:
        output = check_output(["pgrep", name])
        return int(output)
    except:
        return None
        
        
def patch_mem(task, address, original_mem, patched_mem):
    print("Patch Address:", hex(address))
    patch_len = len(patched_mem)
    mem = mach.vm_read(task, address, patch_len)

    if mem == original_mem:
        print("Correct process version!")
        print("Patch:", binascii.hexlify(mem).decode(), "->",
                        binascii.hexlify(patched_mem).decode())
        
        if strtobool(input('Continue patching? ')):
            print("Patching amfid...")
            mach.vm_protect(task, address, patch_len, mach.VM_PROT_ALL)
            mach.vm_write(task, address, patched_mem)
            
            mem = mach.vm_read(amfid_task, address, patch_len)
            
            if patched_mem == mem:
                print("🎉  Patch Successfull!")
            else:
                print("Not patched :(")
            
        else:
            exit(0)
    elif mem == patched_mem:
        print("🎉  Already patched!")
    else:
        print("Memory:", binascii.hexlify(mem).decode(), "vs.",
                         binascii.hexlify(original_mem).decode())
        print("Incorrect version of process or ASRL Offset")

    
if os.getuid() != 0:
    print("This script should run as root.")
    exit(0)

amfid_pid = get_pid("amfid")

if not amfid_pid:
    print("Error: amfid not running, start some app to reload amfid")
    exit(0)

try:
    amfid_task = mach.task_for_pid(amfid_pid)
    asrl_offset = mach.vm_asrl_offset(amfid_pid)
    
    if asrl_offset:
        print("PID:", amfid_pid)
        asrl_offset = 0x0000000100000000 + asrl_offset
        print("ASRL Offset:", hex(asrl_offset))
    else:
        print("Error getting the ASRL Offset")
        exit(0)
        
    # Convert `test r14, r14; je` -> `mov r14, r15; jno`
    # So it always jump and r14 becomes 0
    patch_mem(amfid_task, asrl_offset + 0x3462,#0x347D,
              #b"\x45\x85\xF6\x0F\x84", b"\x4D\x89\xFE\x0F\x81")
            #85 C0 0F 84 AF 00 00 00
              b"\x85\xC0\x0F\x84\xAF", b"\x85\xC9\x0F\x81\xAF")
    
except mach.MachError as error:
    print(error)
    print("Memory not accessible probably due to System Integrity Protection.")
