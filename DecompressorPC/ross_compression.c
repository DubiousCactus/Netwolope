/*
 * ross_compression.c
 * Copyright (C) 2018 transpalette <transpalette@translaptop>
 *
 * Distributed under terms of the MIT license.
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

typedef unsigned char uchar;    /*  8 bits, unsigned */
typedef unsigned int uint;      /* 32 bits (SHOULD BE 16 IN THE ORIGINAL CODE), unsigned */

#define HASH_LEN 256
#define BUFF_LEN 1024    /* size of disk io buffer  */

uchar *hash_tbl[HASH_LEN];
uchar   inbuff[BUFF_LEN];           /* io buffers */
uchar   outbuff[BUFF_LEN];
FILE   *infile, *outfile;


int rdc_compress(uchar *inbuff, uint inbuff_len,
              uchar *outbuff,
              uchar *hash_tbl[], uint hash_len)
{
uchar   *in_idx = inbuff;
uchar   *inbuff_end = inbuff + inbuff_len;
uchar   *anchor;
uchar   *pat_idx;
uint    cnt;
uint    gap;
uint    c;
uint    hash;
uint    *ctrl_idx = (uint *) outbuff;
uint    ctrl_bits;
uint    ctrl_cnt = 0;

uchar   *out_idx = outbuff + sizeof(uint);
uchar   *outbuff_end = outbuff + (inbuff_len - 48);

  printf("Buffer length: %d\n", inbuff_len);
  printf("in_idx: %p\ndata_end: %p\nout_idx: %p\n", in_idx, inbuff_end, out_idx);
  /* skip the compression for a small buffer */

  if (inbuff_len <= 18)
  {
    memcpy(outbuff, inbuff, inbuff_len);
    return 0 - inbuff_len;
  }

  /* adjust # hash entries so hash algorithm can
     use 'and' instead of 'mod' */

  hash_len--;

  /* scan thru inbuff */

  while (in_idx < inbuff_end)
  {
    /* make room for the control bits
       and check for outbuff overflow */

    if (ctrl_cnt++ == 16)
    {
      *ctrl_idx = ctrl_bits;
      ctrl_cnt = 1;
      ctrl_idx = (uint *) out_idx;
      out_idx += 2;

      if (out_idx > outbuff_end)
      {
        memcpy(outbuff, inbuff, inbuff_len);
        return 0 - inbuff_len;
      }
    }

    /* look for rle */

    anchor = in_idx;
    c = *in_idx++;

    printf("Reading character '%02X' at in_idx = %p\n", c, in_idx);
    while (in_idx < inbuff_end
          && *in_idx == c
          && (in_idx - anchor) < (HASH_LEN + 18))
        in_idx++;

    /* store compression code if character is
       repeated more than 2 times */

    if ((cnt = in_idx - anchor) > 2)
    {
      if (cnt <= 18)         /* short rle */
      {
        printf("Found short rle '%02X' of size %d at in_idx = %p. Writing at out_idx = %p.\n", c, cnt, in_idx, out_idx);
        *out_idx++ = cnt - 3;
        *out_idx++ = c;
      }
      else                   /* long rle */
      {
        printf("Found long rle '%02X' of size %d at in_idx = %p. Writing at out_idx = %p.\n", c, cnt, in_idx, out_idx);
        cnt -= 19;
        *out_idx++ = 16 + (cnt & 0x0F);
        *out_idx++ = cnt >> 4;
        *out_idx++ = c;
      }
    ctrl_bits = (ctrl_bits << 1) | 1;

    continue;
  }

  /* look for pattern if 2 or more characters
     remain in the input buffer */

  in_idx = anchor;

  if ((inbuff_end - in_idx) > 2)
  {
    /* locate offset of possible pattern
      in sliding dictionary */

    hash = ((((in_idx[0] & 15) << 8) | in_idx[1]) ^
        ((in_idx[0] >> 4) | (in_idx[2] << 4)))
        & hash_len;

    pat_idx = hash_tbl[hash];
    hash_tbl[hash] = in_idx;

    /* compare characters if we're within 4098 bytes */

    if ((gap = in_idx - pat_idx) <= 258)
    {
      while (in_idx < inbuff_end
            && pat_idx < anchor && *pat_idx == *in_idx
            && (in_idx - anchor) < 171)
      {
        in_idx++;
        pat_idx++;
      }

      /* store pattern if it is more than 2 characters */

      if ((cnt = in_idx - anchor) > 2)
      {
        gap -= 3;

        if (cnt <= 15)          /* short pattern */
        {
          printf("Found short pattern '%02X' in hash table at in_idx = %p. Writing at out_idx = %p.\n", hash, in_idx, out_idx);
          *out_idx++ = (cnt << 4) + (gap & 0x0F);
          *out_idx++ = gap >> 4;
        }
        else                    /* long pattern */
        {
          printf("Found long pattern '%02X' in hash table at in_idx = %p. Writing at out_idx = %p.\n", hash, in_idx, out_idx);
          *out_idx++ = 32 + (gap & 0x0F);
          *out_idx++ = gap >> 4;
          *out_idx++ = cnt - 16;
        }

        ctrl_bits = (ctrl_bits << 1) | 1;

        continue;
      }
    }
  }

    /* can't compress this character
      so copy it to outbuff */

    printf("Writing uncompressed character '%02X' at out_idx = %p.\n", c, out_idx);
    *out_idx++ = c;
    in_idx = ++anchor;
    ctrl_bits <<= 1;
  }

  /* save last load of control bits */

  ctrl_bits <<= (16 - ctrl_cnt);
  *ctrl_idx = ctrl_bits;

  /* and return size of compressed buffer */

  return out_idx - outbuff;
}


/*--- post error message and exit ---*/

void err_exit(char *fmt, ...)
{
va_list v;

  va_start(v, fmt);
  vfprintf(stderr, fmt, v);
  va_end(v);

  exit(1);
}

/*--- compress infile to outfile ---*/

void do_compress(void)
{
int     bytes_read;
int     compress_len;

  /* read infile BUFF_LEN bytes at a time */

  while ((bytes_read =
         fread(inbuff, 1, BUFF_LEN, infile)) > 0)
  {
    /* compress this load of bytes */

    compress_len = rdc_compress(inbuff, bytes_read,
                 outbuff, hash_tbl, HASH_LEN);

    /* write length of compressed buffer */

    if (fwrite(&compress_len, sizeof(int),
             1, outfile) != 1)
      err_exit("Error writing block length.\n");

    /*check for negative length indicating the
       buffer could not be compressed */

    if (compress_len < 0)
      compress_len = 0 - compress_len;

    /* write the buffer */

    if (fwrite(outbuff, compress_len, 1, outfile) != 1)
      err_exit("Error writing compressed data.\n");

    /* we're done if less than full buffer was read */

    if (bytes_read != BUFF_LEN)
      break;
  }

  /* add trailer to indicate end of file */

  compress_len = 0;

  if (fwrite(&compress_len, sizeof(int),
           1, outfile) != 1)
      err_exit("Error writing trailer.\n");
}


int main(char argc, char **argv) {
	if (argc < 3) {
		printf("Usage: %s <input_file> <output_file>\n", argv[0]);
		return 1;
	}

	if ((infile = fopen(argv[1], "rb")) == NULL)
		err_exit("Can't open %s for input.\n", argv[1]);

	  if ((outfile = fopen(argv[2], "wb")) == NULL)
		err_exit("Can't open %s for output.\n", argv[2]);

	  do_compress();

	  if (fclose(infile))
		err_exit("Error closing input file.\n");

	  if (fclose(outfile))
		err_exit("Error closing output file.\n");

          printf("sizeof(uint) = %d\n", sizeof(uint));
          printf("sizeof(uchar) = %d\n", sizeof(uchar));
	return 0;
}
