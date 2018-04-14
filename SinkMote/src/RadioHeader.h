#ifndef DATA_PACKAGE_COMMUNICATION_H
#define DATA_PACKAGE_COMMUNICATION_H

enum {
  DATA_SIZE = 50,
  TIMEOUT = 30000,
  TIMER_PERIOD_MILLI = 1000,
  COMMUNICATION_ADDRESS = 6
};

typedef nx_struct DataPackage {
  nx_uint16_t sequenceNumber;
  nx_uint8_t last;
  nx_uint8_t request;
  nx_uint8_t dataSize;
  nx_uint8_t data[DATA_SIZE];
} DataPackage;

#endif /* DATA_PACKAGE_COMMUNICATION_H */
