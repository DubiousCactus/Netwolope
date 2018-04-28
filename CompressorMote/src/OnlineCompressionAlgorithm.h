#ifndef ONLINE_COMPRESSION_ALGORITHM_H
#define ONLINE_COMPRESSION_ALGORITHM_H

typedef enum {
  OCA_ERR_INVALID_FILE = 40,
  OCA_ERR_BUFFER_OVERFLOW = 50,
  OCA_ERR_OUT_OF_MEMORY
} CompressionError;

enum {
  COMPRESSION_TYPE_NONE = 0,
  COMPRESSION_TYPE_RUN_LENGTH = 1,
  COMPRESSION_TYPE_BLOCK_TRUNCATION = 2,
  COMPRESSION_TYPE_ROSS = 3,
  COMPRESSION_TYPE_BLOCK = 4,
  COMPRESSION_TYPE_NETWOLOPE = 5,
  COMPRESSION_TYPE_NETWOLOPE2 = 6,
};

#endif /* ONLINE_COMPRESSION_ALGORITHM_H */
