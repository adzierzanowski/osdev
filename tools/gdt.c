#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


#define QC {c();
#define QE e();}

struct gdt_t {
  uint16_t lim_15_0;
  uint16_t addr_15_0;
  uint8_t addr_23_16;
  uint8_t a:1;
  uint8_t rw:1;
  uint8_t ce:1;
  uint8_t type:1;
  uint8_t one:1;
  uint8_t dpl:2;
  uint8_t p:1;
  uint8_t lim_19_16:4;
  uint8_t avl:1;
  uint8_t l:1;
  uint8_t db:1;
  uint8_t g:1;
  uint8_t addr_31_24;
};

union gdt_u {
  struct gdt_t gdt;
  uint64_t num;
};


const char *strbool(int val) {
  return val ? "true" : "false";
}

void c() {
  printf("\e[38;5;8m");
}

void e() {
  printf("\e[0m");
}

int main(int argc, char *argv[]) {

  if (argc < 2) {
    fprintf(stderr, "usage: gdt VALUE64\n");
    return 1;
  }

  uint64_t val = strtoll(argv[1], NULL, 10);
  int verbose = 0;

  if (argc > 2 && strcmp(argv[2], "-v") == 0) {
    verbose = 1;
  }

  union gdt_u gdtu;
  gdtu.num = val;
  struct gdt_t gdt = gdtu.gdt;

  puts("Global Descriptor Table Entry");
  printf("%24s: %016llx\n", "numeric", val);
  puts("");
  printf("%24s: %08x\n", "base address", (gdt.addr_31_24 << 24) | (gdt.addr_23_16 << 16) | gdt.addr_15_0);
  if (verbose) QC printf("%24s  %s", "", "32-bit starting memory address of the segment\n"); QE
  printf("%24s: %05x\n", "segment limit", (gdt.lim_19_16 << 16) | gdt.lim_15_0);
  if (verbose) QC printf("%24s  %s", "", "20-bit length of the segment (+1)\n"); QE
  printf("%24s: %s\n", "granularity", gdt.g ? "pages (4096B)" : "bytes");
  if (verbose) QC printf("%24s  %s", "", "segment limit units\n"); QE
  printf("%24s: %s\n", "default operand size", gdt.db ? "32-bit" : "16-bit");
  printf("%24s: %s\n", "64-bit segment", strbool(gdt.l));
  printf("%24s: %s\n", "available", strbool(gdt.avl));
  if (verbose) QC printf("%24s  %s", "", "for software use only\n"); QE
  printf("%24s: %s\n", "present", strbool(gdt.p));
  if (verbose) QC printf("%24s  %s", "", "if cleared, 'segment not present' exception is thrown on access\n"); QE
  printf("%24s: %d\n", "privilege level (ring)", gdt.dpl);
  printf("%24s: %s\n", "type", gdt.type ? "code segment" : "data segment");
  printf("%24s: %s\n", "conforming/expand down", strbool(gdt.type));
  if (verbose) QC printf("%24s  %s", "", "C: if set, code in the segment may be called from less-privileged levels\n"); QE
  if (verbose) QC printf("%24s  %s", "", "E: if clear, it expands from max offset down to limit\n"); QE
  printf("%24s: %s\n", "readable/writable", strbool(gdt.rw));
  if (verbose) QC printf("%24s  %s", "", "meaning depends on segment type\n"); QE
  printf("%24s: %s\n", "accessed", strbool(gdt.rw));
  if (verbose) QC printf("%24s  %s", "", "hardware sets this bit on access, cleared by software\n"); QE
  printf("%24s: %d\n", "const 1", gdt.one);
  if (verbose) QC printf("%24s  %s", "", "always 1"); QE

  return 0;
}
