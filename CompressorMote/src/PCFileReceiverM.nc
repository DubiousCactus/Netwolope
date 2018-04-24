#include "PCFileReceiver.h"

module PCFileReceiverM{
  provides {
    interface PCFileReceiver;
  }
  uses {
    interface SplitControl as SerialControl;
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;
    interface AMSend as SerialSend[am_id_t msg_type];
    interface Receive as SerialReceive[am_id_t msg_type];
    interface CircularBufferWriter as Writer;
  }
}
implementation{
  typedef enum {
    STATE_INIT = 1,
    STATE_SENDING_ACK,
    STATE_READY_TO_RECEIVE_DATA,
    STATE_PROCESSING,
    STATE_PROCESSING_EOF
  } InternalState;
  
  enum {
    AM_MSG_BEGIN_FILE         = 128,
    AM_MSG_ACK_BEGIN_FILE     = 129,
    AM_MSG_PARTIAL_DATA       = 130,
    AM_MSG_ACK_PARTIAL_DATA   = 131,
    AM_MSG_EOF                = 132,
    AM_MSG_ACK_EOF            = 133
  };
  
  enum {
    BUFFER_CAPACITY = 128,
    PACKET_CAPACITY = 64
  } Constants;
  
  typedef nx_struct {
    nx_uint16_t width;
  } BeginFileMsg;
  
  
  typedef nx_struct {
    nx_uint32_t length;
  } AckMsg;
  
  
  typedef nx_struct {
    nx_uint8_t data[PACKET_CAPACITY];
  } PartialDataMsg;
  
  InternalState state = STATE_INIT;
  message_t packet;
  uint16_t width = 0;
  bool waitingForReceiveMoreCommand = FALSE;
  
  /**
   * Sends an acknowledge packet to the PC.
   * @param ack_type The type of acknowlegement to send
   * @param length   The size of the packet that is to be acknowledged
   */
  void sendAckMsg(am_id_t ack_type, uint32_t length) {
    AckMsg* msg = (AckMsg*)call SerialPacket.getPayload(&packet, sizeof(AckMsg));
    msg->length = length;
    
    if (call SerialSend.send[ack_type](AM_BROADCAST_ADDR, &packet, sizeof(AckMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_ACK;
      }
    } else {
      signal PCFileReceiver.error(PFR_ERR_SEND_FAILED);
    }
  }

  /**
   * Process a packet from the 
   */
  void processBeginTrasmitMsg(message_t* message) {
    BeginFileMsg* msg = (BeginFileMsg*)call SerialPacket.getPayload(message, sizeof(BeginFileMsg));
    atomic {
      width = msg->width;
      call Writer.clear();
    }
    signal PCFileReceiver.fileBegin(width);
  }
  
  inline void processPartialData(message_t *msg, void *payload, uint8_t len) {
    if (call Writer.getFreeSpace() > len) {
      call Writer.writeChunk((uint8_t *)payload, len);
      waitingForReceiveMoreCommand = TRUE;
      signal PCFileReceiver.receivedData();
    } else {
      signal PCFileReceiver.error(PFR_ERR_BUFFER_FULL);
    }
  }
  
  inline void processEndOfFile() {
    sendAckMsg(AM_MSG_ACK_EOF, 0);
    signal PCFileReceiver.fileEnd();
  }
  
  command void PCFileReceiver.init(){
    call SerialControl.start();
  }
  
  command void PCFileReceiver.receiveMore(){
    atomic {
      waitingForReceiveMoreCommand = FALSE;
      if (state == STATE_PROCESSING) {
        sendAckMsg(AM_MSG_ACK_PARTIAL_DATA, 0);
      } else if (state == STATE_PROCESSING_EOF) {
        sendAckMsg(AM_MSG_ACK_EOF, 0);
        signal PCFileReceiver.fileEnd();
      }
    }
  }
  
  command void PCFileReceiver.sendFileBeginAck() {
    sendAckMsg(AM_MSG_ACK_BEGIN_FILE, width * width);
  }

  event void SerialControl.stopDone(error_t error){ }

  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      signal PCFileReceiver.initDone();
    } else {
      signal PCFileReceiver.error(PFR_ERR_SERIAL_INIT_FAILED);
    }
  }

  event void SerialSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    atomic {
      if (state == STATE_SENDING_ACK) {
        state = STATE_READY_TO_RECEIVE_DATA;
      }
    }
  }

  event message_t * SerialReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    
    atomic {
      // At any point in time, the PC can start the transmission of a file.
      // Whenever the mote receives BEGIN_TRANSMIT, it resets all its
      // buffers and prepares to receive bytes in chunks defined in PACKET_CAPACITY
      if (msg_type == AM_MSG_BEGIN_FILE){
        state = STATE_PROCESSING;
        processBeginTrasmitMsg(msg);
        return msg;
      }

      if (state == STATE_READY_TO_RECEIVE_DATA) {
        if (msg_type == AM_MSG_PARTIAL_DATA) {
          state = STATE_PROCESSING;
          processPartialData(msg, payload, len);
          
        } else if (msg_type == AM_MSG_EOF) {
          state = STATE_PROCESSING_EOF;
          processEndOfFile();
        } else {
          signal PCFileReceiver.error(PFR_ERR_PROGRAMMER);
        }
      } else {
        // We are not in a state to receive data, so
        // just drop the packet and signal an error
        
        if (waitingForReceiveMoreCommand == TRUE) {
          signal PCFileReceiver.error(PFR_ERR_EXPECTED_RECEIVE_MORE);
        } else {
          signal PCFileReceiver.error(PFR_ERR_PACKET_DROPPED);
        }
      }
    }
    return msg;
  }
}