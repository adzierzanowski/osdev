#!/usr/bin/env python3

from io import SEEK_SET
import sys

with open(sys.argv[1], 'rb+') as f:
  data = f.read()

  datalen = len(data)
  if datalen % 512:
    data += b'\0' * (512 - (datalen % 512))

  f.seek(SEEK_SET)
  f.write(data)

  sz = f.tell()
  print(f'Total size: {sz}')
  print(f'Total sectors: {sz//512}')
