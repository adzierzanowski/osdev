#!/usr/bin/env bash

echo "Building kernel"
gcc -nostdlib kernel.c -o kernel
#readelf -a kernel
