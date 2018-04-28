#include "OnlineCompressionAlgorithm.h"
#include "printf.h"

#define HASH_LEN  256    /* # hash table entries (at least 4 times smaller than the buffer size) */
#define BUFF_LEN  1024    /* Output buffer size (should be roughly equal to the input buffer size */

module RossCompressionM {
	provides interface OnlineCompressionAlgorithm;
	uses {
		interface CircularBufferReader as InBuffer;
		interface CircularBufferWriter as OutBuffer;
	}
} implementation {

	uint8_t *hash_tbl[HASH_LEN];        /* hash table */
	uint16_t hash_len;

	command void OnlineCompressionAlgorithm.fileBegin(uint16_t imageWidth) {
		hash_len = HASH_LEN;
		call OutBuffer.clear();
	}

	/* ROSS Data compression algorithm
	 * Written by Ed Ross, 1/92
	 * compress length bytes of data into outbuff
	 * using hash_len entries in hash_tbl.
	 */
	command void OnlineCompressionAlgorithm.compress(bool last) {
	
		/* ABOUT THE BUG: In the resulting compressed file of the PC version, 8 bytes are added at the beginning of the output buffer
		 * (somewhere in the code I would guess...). However, 16 bytes are added in this version.... This results in a bad reading
		 * of the block size !
		 */
		uint8_t data[1024]; //Data to compress
		uint16_t length = call InBuffer.available(); //Number of bytes to compress
		uint8_t outbuff[BUFF_LEN];	
		uint8_t *in_idx = data;
		uint8_t *data_end = data + length;
		uint8_t *anchor;
		uint8_t *pat_idx;
		uint16_t cnt;
		uint16_t gap;
		uint16_t c;
		uint16_t hash;
		uint16_t *ctrl_idx = (uint16_t *) outbuff;
		uint16_t ctrl_bits = 0;
		uint16_t ctrl_cnt = 0;
		uint8_t *out_idx = outbuff + sizeof(uint16_t);
		uint8_t *outbuff_end = outbuff + (length - 48);

		printf("Compressing %d bytes\n", length);

		while (call InBuffer.available() > 0) {
			/* Read from the buffer */
			length = call InBuffer.available();
			call InBuffer.readChunk(data, length);

			/* Might need to reset the initial values (since the buffer would change here) */
			in_idx = &data[0];
			data_end = &data[0] + length;
			ctrl_idx = (uint16_t *) outbuff;
			ctrl_bits = 0;
			ctrl_cnt = 0;
			out_idx = &outbuff[0] + sizeof(uint16_t); //16 = sizeof(uint16_t)
			outbuff_end = &outbuff[0] + (length - 48);

			printf("Buffer length: %d\n", length);
			printf("in_idx: %p\ndata_end: %p\nout_idx: %p\n", in_idx, data_end, out_idx);

			/* skip the compression for a small buffer */
			if (length <= 18) {
				call OutBuffer.writeChunk(data, length);
				continue; //Skip this buffer
			}

			/* Adjust number of hash entries so hash algorithm can
			 use 'and' instead of 'mod' */
			hash_len--;

			/* Scan through input buffer */
			while (in_idx < data_end) {
				/* Make room for the control bits and check for outbuff overflow */
				if (ctrl_cnt++ == 16) {
					*ctrl_idx = ctrl_bits;
					ctrl_cnt = 1;
					ctrl_idx = (uint16_t *) out_idx;
					out_idx += 2;

					if (out_idx > outbuff_end) {
						signal OnlineCompressionAlgorithm.error(OCA_ERR_BUFFER_OVERFLOW);
						return;
					}
				}

				/* Look for rle */
				anchor = in_idx;
				c = *in_idx++;

				/*printf("Reading character '%02X' at in_idx = %p\n", c, in_idx);*/
				/* While the character at the index pointer is the same, read forward */
				while (in_idx < data_end && *in_idx == c && (in_idx - anchor) < (HASH_LEN + 18))
					in_idx++;

				/*printfflush();*/
				/* Store compression code if character is repeated more than 2 times */
				if ((cnt = in_idx - anchor) > 2) {
					/* short rle */
					if (cnt <= 18) {
						printf("Found short rle '%02X' of size %d at in_idx = %p. Writing at out_idx = %p.\n", c, cnt, in_idx, out_idx);
						*out_idx++ = cnt - 3;
						*out_idx++ = c;
					} else { /* long rle */
						printf("Found long rle '%02X' of size %d at in_idx = %p. Writing at out_idx = %p.\n", c, cnt, in_idx, out_idx);
						cnt -= 19;
						*out_idx++ = 16 + (cnt & 0x0F);
						*out_idx++ = cnt >> 4;
						*out_idx++ = c;
					}
					ctrl_bits = (ctrl_bits << 1) | 1;

					continue;
				}

				/* Look for pattern if 2 or more characters remain in the input buffer */
				in_idx = anchor;

				if ((data_end - in_idx) > 2) {
					/* Locate offset of possible pattern in sliding dictionary */
					hash = ((((in_idx[0] & 15) << 8) | in_idx[1]) ^ ((in_idx[0] >> 4) | (in_idx[2] << 4))) & hash_len;

					pat_idx = hash_tbl[hash];
					hash_tbl[hash] = in_idx;

					/* Compare characters if we're within 258 bytes */
					if ((gap = in_idx - pat_idx) <= 258) {
						while (in_idx < data_end && pat_idx < anchor && *pat_idx == *in_idx && (in_idx - anchor) < 171) {
							in_idx++;
							pat_idx++;
						}

						/* store pattern if it is more than 2 characters */
						if ((cnt = in_idx - anchor) > 2) {
							gap -= 3;

							if (cnt <= 15) { /* short pattern */
								printf("Found short pattern '%02X' in hash table at in_idx = %p. Writing at out_idx = %p.\n", hash, in_idx, out_idx);
								*out_idx++ = (cnt << 4) + (gap & 0x0F);
								*out_idx++ = gap >> 4;
							} else { /* long pattern */
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
				
				/* can't compress this character so copy it to outbuff */
				printf("Writing uncompressed character '%02X' at out_idx = %p.\n", c, out_idx);
				*out_idx++ = c;
				in_idx = ++anchor;
				ctrl_bits <<= 1;
				printfflush();
			}

			/* save last load of control bits */
			ctrl_bits <<= (16 - ctrl_cnt);
			*ctrl_idx = ctrl_bits;

			/* Write compressed bytes to circular buffer */
			if (call OutBuffer.getFreeSpace() < length) {
				/* TODO: Implement retry timer */
				signal OnlineCompressionAlgorithm.error(OCA_ERR_OUT_OF_MEMORY);
				return;
			}

			length = out_idx - outbuff;
			printf("Done processing buffer. Output length: %d\n\n", length);
			/*printfflush();*/
			call OutBuffer.writeChunk(outbuff, length);
		}
		
		signal OnlineCompressionAlgorithm.compressed();
	}

	command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
		return COMPRESSION_TYPE_ROSS;
	}
}
