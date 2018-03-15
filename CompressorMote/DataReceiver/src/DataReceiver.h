#ifndef DATA_RECEIVER_H
#define DATA_RECEIVER_H


typedef nx_struct FrameMsg {
	nx_uint8_t type; //if type is 00 then its data otherwise it is end of message.
	nx_uint8_t dataLength;
	nx_uint8_t data[20];
} FrameMsg;

#endif /* DATA_RECEIVER_H */
