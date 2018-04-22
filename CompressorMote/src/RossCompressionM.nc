#include "OnlineCompressionAlgorithm.h"
#include "printf.h"

#define HASH_LEN  24    /* # hash table entries (at least 4 times smaller than the buffer size) */
#define BUFF_LEN  50    /* Output buffer size (should be roughly equal to the input buffer size */

module RossCompressionM {
	provides interface OnlineCompressionAlgorithm;
} implementation {

	uint8_t *hash_tbl[HASH_LEN];        /* hash table */
	uint16_t hash_len;
	
	command void OnlineCompressionAlgorithm.init() {
		hash_len = HASH_LEN;
		signal OnlineCompressionAlgorithm.initDone();
	}

	command void OnlineCompressionAlgorithm.fileBegin(uint32_t totalLength) {

	}

	/* ROSS Data compression algorithm
	 * Written by Ed Ross, 1/92
	 * compress length bytes of data into outbuff
	 * using hash_len entries in hash_tbl.
	 */
	command void OnlineCompressionAlgorithm.compress(uint8_t *data, uint16_t length) {
	
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

		/* skip the compression for a small buffer */
		if (length <= 18) {
			memcpy(outbuff, data, length);
			signal OnlineCompressionAlgorithm.compressed(outbuff, 0 - length);
			return;
		}

		/* adjust # hash entries so hash algorithm can
		 use 'and' instead of 'mod' */
		hash_len--;

		/* scan through input buffer */
		while (in_idx < data_end)
		{
			/* make room for the control bits
			and check for outbuff overflow */
			if (ctrl_cnt++ == 16) {
				*ctrl_idx = ctrl_bits;
				ctrl_cnt = 1;
				ctrl_idx = (uint *) out_idx;
				out_idx += 2;

				if (out_idx > outbuff_end) {
					memcpy(outbuff, data, length);
					signal OnlineCompressionAlgorithm.error(OCA_ERR_BUFFER_OVERFLOW);
					return;
				}
			}

			/* look for rle */
			anchor = in_idx;
			c = *in_idx++;

			while (in_idx < data_end && *in_idx == c && (in_idx - anchor) < 4114)
				in_idx++;

			/* store compression code if character is
			repeated more than 2 times */
			if ((cnt = in_idx - anchor) > 2) {
				/* short rle */
				if (cnt <= 18) {
					*out_idx++ = cnt - 3;
					*out_idx++ = c;
				} else { /* long rle */
					cnt -= 19;
					*out_idx++ = 16 + (cnt & 0x00F);
					*out_idx++ = cnt >> 4;
					*out_idx++ = c;
				}
				ctrl_bits = (ctrl_bits << 1) | 1;

				continue;
			}

			/* look for pattern if 2 or more characters
				 remain in the input buffer */
			in_idx = anchor;

			if ((data_end - in_idx) > 2)
			{
				/* locate offset of possible pattern
				in sliding dictionary */
				hash = ((((in_idx[0] & 15) << 8) | in_idx[1]) ^ ((in_idx[0] >> 4) | (in_idx[2] << 4))) & hash_len;

				pat_idx = hash_tbl[hash];
				hash_tbl[hash] = in_idx;

				/* compare characters if we're within 4098 bytes */
				if ((gap = in_idx - pat_idx) <= 4098) {
					while (in_idx < data_end && pat_idx < anchor && *pat_idx == *in_idx && (in_idx - anchor) < 271) {
						in_idx++;
						pat_idx++;
					}

					/* store pattern if it is more than 2 characters */
					if ((cnt = in_idx - anchor) > 2) {
						gap -= 3;

						if (cnt <= 15) { /* short pattern */
							*out_idx++ = (cnt << 4) + (gap & 0x0F);
							*out_idx++ = gap >> 4;
						} else { /* long pattern */
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
			*out_idx++ = c;
			in_idx = ++anchor;
			ctrl_bits <<= 1;
		}

		/* save last load of control bits */
		ctrl_bits <<= (16 - ctrl_cnt);
		*ctrl_idx = ctrl_bits;

		/* and return size of compressed buffer */
		signal OnlineCompressionAlgorithm.compressed(outbuff, out_idx - outbuff);
	}

	command void OnlineCompressionAlgorithm.fileEnd() {
		signal OnlineCompressionAlgorithm.compressDone();
	}

	command uint8_t OnlineCompressionAlgorithm.getCompressionType() {
		return COMPRESSION_TYPE_NONE;
	}
}
