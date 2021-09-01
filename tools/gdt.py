#!/usr/bin/env python3

import subprocess
import sys

val = str(eval(sys.argv[1]))

ps = subprocess.Popen(('tools/gdt', val, *sys.argv[2:]), stdout=subprocess.PIPE)
out, _ = ps.communicate()

print(out.decode('utf-8'))
