#!/usr/bin/env python3

import subprocess
import sys

if len(sys.argv) < 2:
  print('usage: gdt.py EXPR')
  print('for example:')
  print('  gdt.py \'((10 << 8) | (1 << 12) | (1 << 15) | (0xf << 16) | (1 << 22) | (1 << 23)) << 32 | 0x0000ffff\'')
  sys.exit(1)

val = eval(sys.argv[1])

print('VAL',  val)
ps = subprocess.Popen(('tools/gdt', str(val), *sys.argv[2:]), stdout=subprocess.PIPE)
out, _ = ps.communicate()

print(out.decode('utf-8'))
