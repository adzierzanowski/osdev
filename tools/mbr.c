#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

struct mbr_t {
  uint8_t bootable;
  uint32_t chs_addr_first:24;
  uint8_t partition_type;
  uint32_t chs_addr_last:24;
  uint32_t lba;
  uint32_t sector_cnt;
};

struct chs_t {
  uint16_t cylinder;
  uint8_t head;
  uint8_t sector;
};

union mbr_u {
  uint8_t val[16];
  struct mbr_t mbr;
};

void u32_to_chs(struct chs_t *chs, uint32_t val) {
  //printf("chs_val = %06x\n", val);
  chs->cylinder = ((val >> 16) & 0xff) | ((val >> 14) & 0b11);
  chs->head = val & 0xff;
  chs->sector = (val >> 8) & 0b00111111;
}

void print_chs(struct chs_t *chs) {
  printf("  cylinder %d\n", chs->cylinder);
  printf("  head     %d\n", chs->head);
  printf("  sector   %d\n", chs->sector);
}

void write_mbr(const char* fname, int partition, uint8_t *entry) {
  FILE *f = fopen(fname, "rb+");

  uint8_t buf[512] = {0};
  fread(buf, 1, 512, f);

  memcpy(buf+0x01be + 16*partition, entry, 16);

  /*
  for (int i  = 0; i < 512; i++) {
    if (i != 0 && i % 16 == 0)  {
      puts("");
    }
    printf("%02x ", buf[i]);
  }
  puts("");
  */

  fseek(f, 0, SEEK_SET);
  fwrite(buf, 1, 512, f);

  fclose(f);
}

void usage() {
  puts("usage: mbr [output file]");
}

int main(int argc, char *argv[])
{
  uint8_t val[16] = {
    0x00, 0xFE, 0xFF, 0xFF,
    0x0B, 0xFE, 0xFF, 0xFF,
    0x00, 0x08, 0x00, 0x00,
    0x00, 0xF8, 0x3B, 0x00
  };

  union mbr_u mbru;
  memcpy(mbru.val, val, 16);

  struct mbr_t mbr = mbru.mbr;
  struct chs_t chs = {0};

  mbru.mbr.bootable = 0x80;
  printf("sector count   %d\n", mbr.sector_cnt);
  printf("  disk size    %0.2lf MiB\n", mbr.sector_cnt * 512.0 / 1024 / 1024);
  printf("bootable       %d\n", mbr.bootable);
  printf("lba            0x%08x\n", mbr.lba);
  printf("partition type 0x%02x\n", mbr.partition_type);
  printf("first CHS:\n");
  u32_to_chs(&chs, mbr.chs_addr_first);
  print_chs(&chs);
  printf("last CHS:\n");
  u32_to_chs(&chs, mbr.chs_addr_last);
  print_chs(&chs);

  if (argc > 1) {
    const char *fname = argv[1];


    if (strcmp(fname, "-h") == 0 || strcmp(fname, "--help") == 0) {
      usage();
      return 0;
    }

    if (access(fname, F_OK) == 0) {
      write_mbr(fname, 0, mbru.val);
    } else {
      fprintf(stderr, "The filename provided is not accessible.\n");
      return 1;
    }
  }

  return 0;
}
