/* DECOMPRS.C - Ross Data Compression (RDC)
 *              decompress function
 *
 * Written by Ed Ross, 1/92
 *
 * decompress inbuff_len bytes of inbuff into outbuff.
   return length of outbuff.                        */


#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

typedef unsigned char uchar;    /*  8 bits, unsigned */
typedef unsigned int uint;      /* 16 bits, unsigned */

#define BUFF_LEN 16384    /* size of disk io buffer  */

uchar   inbuff[BUFF_LEN];           /* io buffers */
uchar   outbuff[BUFF_LEN];
FILE   *infile, *outfile;

int rdc_decompress(uchar *inbuff, uint inbuff_len, uchar *outbuff)
{
	uint   ctrl_bits;
	uint   ctrl_mask = 0;
	uchar  *inbuff_idx = inbuff;
	uchar  *outbuff_idx = outbuff;
	uchar  *inbuff_end = inbuff + inbuff_len;
	uint   cmd;
	uint   cnt;
	uint   ofs;
	uint   len;

	/* process each item in inbuff */
  
  while (inbuff_idx < inbuff_end)
  {
    /* get new load of control bits if needed */

    if ((ctrl_mask >>= 1) == 0)
    {
      ctrl_bits = * (uint *) inbuff_idx;
      inbuff_idx += 2;
      ctrl_mask = 0x8000;
    }

    /* just copy this char if control bit is zero */

    if ((ctrl_bits & ctrl_mask) == 0)
    {
      *outbuff_idx++ == *inbuff_idx++;

      continue;
    }

    /* undo the compression code */

    cmd = (*inbuff_idx >> 4) & 0x0F;
    cnt = *inbuff_idx++ & 0x0F;

    switch (cmd)
    {
    case 0:     /* short rle */
        cnt += 3;
        memset(outbuff_idx, *inbuff_idx++, cnt);
        outbuff_idx += cnt;
        break;

    case 1:     /* long /rle */
        cnt += (*inbuff_idx++ << 4);
        cnt += 19;
        memset(outbuff_idx, *inbuff_idx++, cnt);
        outbuff_idx += cnt;
        break;

    case 2:     /* long pattern */
        ofs = cnt + 3;
        ofs += (*inbuff_idx++ << 4);
        cnt = *inbuff_idx++;
        cnt += 16;
        memcpy(outbuff_idx, outbuff_idx - ofs, cnt);
        outbuff_idx += cnt;
        break;

    default:    /* short pattern */
        ofs = cnt + 3;
        ofs += (*inbuff_idx++ << 4);
        memcpy(outbuff_idx, outbuff_idx - ofs, cmd);
        outbuff_idx += cmd;
        break;
    }
  }

  /* return length of decompressed buffer */

  return outbuff_idx - outbuff;
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


/*--- decompress infile to outfile ---*/
void do_decompress()
{
	int     block_len;
	int     decomp_len;

  /* read infile BUFF_LEN bytes at a time */

  for (;;)
  {
    if (fread(&block_len, sizeof(int), 1, infile) != 1)
        err_exit("Can't read block length.\n");

    /* check for end-of-file flag */

    if (block_len == 0)
      return;

    if (block_len < 0)  /* copy uncompressed chars */
    {
      decomp_len = 0 - block_len;
      if (fread(outbuff, decomp_len, 1, infile) != 1)
        err_exit("Can't read uncompressed block.\n");
    }
    else                /* decompress this buffer */
    {
      if (fread(inbuff, block_len, 1, infile) != 1)
        err_exit("Can't read compressed block.\n");

      decomp_len = rdc_decompress(inbuff, block_len,
                              outbuff);
    }

    /* and write this buffer outfile */

    if (fwrite(outbuff, decomp_len, 1, outfile) != 1)
      err_exit("Error writing uncompressed data.\n");
  }
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

	  if (fclose(infile))
		err_exit("Error closing input file.\n");

	  if (fclose(outfile))
		err_exit("Error closing output file.\n");

	return 0;
}
