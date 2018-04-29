#include "RadioSender.h"

module RadioSenderM {
  provides interface RadioSender;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as RadioSend[am_id_t msg_type];
  uses interface Receive as RadioReceive[am_id_t msg_type];
  uses interface SplitControl as RadioControl;
  uses interface CircularBufferReader as Reader;
}
implementation {
  State _state = IDLE;
  RadioSenderError _error;
  message_t packet;
  BeginFileMsg *beginFileMsg = (BeginFileMsg *) call Packet.getPayload(&packet, sizeof(BeginFileMsg));

  /* Runs through the state machine to execute the appropriate actions */
  task void protocolIteration() {
      switch (_state) {
        case IDLE:
          /* Do nothing */
          printf("IDLE\n");
          break;
        case BEGIN_TRANSFER:
          printf("BEGIN_TRANSFER\n");

          if (call RadioSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &packet, sizeof(BeginFileMsg)) != SUCCESS) {
            _error = RS_ERR_SEND_FAILED;
            changeState(ERROR);
          }
          break;
        case SENDING_CHUNK:
          printf("SENDING_CHUNK\n");
          uint8_t transferSize = 0;
          uint16_t availableBytes = 0;
          PartialDataMsg* msg;

          if (currentState != STATE_READY) {
            return;
          }

          availableBytes = call Reader.available();
          if (availableBytes > 0) {
            if (availableBytes > PACKET_CAPACITY) {
              transferSize = PACKET_CAPACITY;
            } else {
              transferSize = availableBytes;
            }

            msg = (PartialDataMsg*)(call Packet.getPayload(&pkt, sizeof(PartialDataMsg)));
            if (call Reader.readChunk((uint8_t*)msg->data, (uint16_t)transferSize) != SUCCESS) {
              signal RadioSender.error(RS_ERR_PROGRAMMER);
              return;
            }

            currentState = STATE_SENDING_PARTIAL_DATA;
            if (call RadioSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &pkt, transferSize) != SUCCESS) {
              signal RadioSender.error(RS_ERR_SEND_FAILED);
            }
          } else {
            signal RadioSender.sendDone();
          }
          break;
        case RECOVERY:
          printf("RECOVERY\n");
          break;
        case END_OF_CHUNK:
          printf("END_OF_CHUNK\n");
          break;
        case END_OF_FILE:
          printf("END_OF_FILE\n");
          break;
        case ERROR:
          printf("ERROR\n");
          signal RadioSender.error(_error);
          changeState(IDLE);
      }
  }

  /* Switch to new state and run next protocol iteration if the current state allows it */
  void changeState(State newState) {
    bool invalid = FALSE;
    switch (newState) {
      case IDLE:
        if (_state != ERROR) {
          invalid = TRUE;
        }
        break;
      case BEGIN_TRANSFER:
        if (_state != IDLE) {
          invalid = TRUE;
        }
        break;
      case SENDING_CHUNK:
        if (_state != BEGIN_TRANSFER && _state != END_OF_CHUNK && _state != RECOVERY) {
          invalid = TRUE;
        }
        break;
      case RECOVERY:
        if (_state != SENDING_CHUNK && _state != END_OF_CHUNK) {
          invalid = TRUE;
        }
        break;
      case END_OF_CHUNK:
        if (_state != SENDING_CHUNK) {
          invalid = TRUE;
        }
        break;
      case END_OF_FILE:
        if (_state != SENDING_CHUNK) {
          invalid = TRUE;
        }
        break;
      case ERROR:
        if (_state != BEGIN_TRANSFER && _state != END_OF_FILE && _state != RECOVERY) {
          invalid = TRUE;
        }
    }

    if (invalid) {
      signal RadioSenderError.error(RS_ERR_INVALID_STATE);
      return;
    }

    _state = newState;
    post protocolIteration();
}

  command void RadioSender.init() {
    if (_state == IDLE) {
      call RadioControl.start();
    }
  }

  command void RadioSender.sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType) {
    beginFileMsg->uncompressedSize = uncompressedSize;
    beginFileMsg->compressionType = compressionType;

    if (_state == IDLE) {
      changeState(BEGIN_TRANSFER);
    }
  }

  command bool RadioSender.canSend() {
    return (call Reader.available() > 0);
  }

  command bool RadioSender.canSendFullPacket() {
    return (call Reader.available() >= PACKET_CAPACITY);
  }

  command void RadioSender.sendPartialData() {
    /*uint8_t transferSize = 0;
    uint16_t availableBytes = 0;
    PartialDataMsg* msg;

    if (currentState != STATE_READY) {
      signal RadioSender.error(RS_ERR_INVALID_STATE);
      return;
    }

    availableBytes = call Reader.available();
    if (availableBytes > 0) {
      if (availableBytes > PACKET_CAPACITY) {
        transferSize = PACKET_CAPACITY;
      } else {
        transferSize = availableBytes;
      }

      msg = (PartialDataMsg*)(call Packet.getPayload(&pkt, sizeof(PartialDataMsg)));
      if (call Reader.readChunk((uint8_t*)msg->data, (uint16_t)transferSize) != SUCCESS) {
        signal RadioSender.error(RS_ERR_PROGRAMMER);
        return;
      }

      currentState = STATE_SENDING_PARTIAL_DATA;
      if (call RadioSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &pkt, transferSize) != SUCCESS) {
        signal RadioSender.error(RS_ERR_SEND_FAILED);
      }
    } else {
      signal RadioSender.sendDone();
    }*/
  }

  command void RadioSender.sendEOF() {
    /*atomic {
      if (currentState != STATE_READY) {
        signal RadioSender.error(RS_ERR_INVALID_STATE);
        return;
      }

      currentState = STATE_SENDING_EOF;
      if (call RadioSend.send[AM_MSG_EOF](AM_BROADCAST_ADDR, &pkt, 0) != SUCCESS) {
        signal RadioSender.error(RS_ERR_SEND_FAILED);
      }
    }*/
  }

  event void RadioControl.startDone(error_t error){
    /*if (error == SUCCESS) {
      currentState = STATE_READY;
      signal RadioSender.initDone();
    } else {
      signal RadioSender.error(RS_ERR_INIT_FAILED);
    }*/
  }

  event void RadioControl.stopDone(error_t error){
    // TODO Auto-generated method stub
  }

  event void RadioSend.sendDone[am_id_t msg_type](message_t *msg, error_t error) {
    /*if (error != SUCCESS) {
      signal RadioSender.error(RS_ERR_SEND_FAILED);
      return;
    }

    atomic {
      if (currentState == STATE_SENDING_PARTIAL_DATA) {
        currentState = STATE_WAITING_PARTIAL_DATA_ACK;
      } else if (currentState == STATE_SENDING_EOF) {
        currentState = STATE_WAITING_EOF_ACK;
      } else if (currentState == STATE_SENDING_BEGIN_FILE) {
        currentState = STATE_WAITING_BEGIN_FILE_ACK;
      } else {
        signal RadioSender.error(RS_ERR_INVALID_STATE);
      }
    }*/
  }

  event message_t * RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len) {
    /*atomic {
      if (currentState == STATE_WAITING_PARTIAL_DATA_ACK) {
        if (msg_type == AM_MSG_ACK_PARTIAL_DATA) {
          currentState = STATE_READY;
          signal RadioSender.sendDone();
        }
      } else if (currentState == STATE_WAITING_EOF_ACK){
        // TODO: Do something here
        currentState = STATE_READY;
      } else if (currentState == STATE_WAITING_BEGIN_FILE_ACK){
        // TODO: Do something here
        currentState = STATE_READY;
        signal RadioSender.fileBeginAcknowledged();
      } else {
        signal RadioSender.error(RS_ERR_INVALID_STATE);
      }
    }
    return msg;*/
  }
}
