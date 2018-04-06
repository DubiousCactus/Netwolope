#ifndef RECEIVE_PACKAGE_H
#define RECEIVE_PACKAGE_H

typedef nx_struct ReceivePackageMsg {
  nx_uint8_t type; //if type is 00 then its data otherwise it is end of message.
  nx_uint8_t datalength;
  nx_uint8_t data[20];
} ReceivePackageMsg;

#endif /* RECEIVE_PACKAGE_H */
