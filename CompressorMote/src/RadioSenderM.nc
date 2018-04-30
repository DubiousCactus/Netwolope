#include "RadioSender.h"

module RadioSenderM {
  provides interface RadioSender;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as RadioSend[am_id_t msg_type];
  uses interface Receive as RadioReceive[am_id_t msg_type];
  uses interface SplitControl as RadioControl;
  uses interface CircularBufferReader as Reader;

} implementation {

  State _state = IDLE;
  SubState _subState;
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
        case READY:
          printf("READY\n");
          /* TODO: Use the state machine if this event isn't actually needed */
          signal RadioSender.initDone();
          break;
        case BEGIN_TRANSFER:
          printf("BEGIN_TRANSFER\n");

          if (_subState == SENDING) {
            if (call RadioSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &packet, sizeof(BeginFileMsg)) != SUCCESS) {
              _error = RS_ERR_SEND_FAILED;
              changeState(ERROR);
              break;
            }
          } else if (_subState == WAITING) {
            if (_msgType == AM_MSG_ACK_BEGIN_FILE) {
              _msgType = NULL;
              changeSubState(SENDING);
              changeState(SENDING_CHUNK);
              break;
            }
          }
          break;
        case SENDING_CHUNK:
          printf("SENDING_CHUNK\n");
          PartialDataMsg *msg;
          uint16_t availableBytes = call Reader.available();
          uint8_t transferSize = availableBytes;

          if (_msgType == AM_MSG_NACK_PARTIAL_DATA) {
            _msgType = NULL;
            changeState(RECOVERY);
            break;
          }

          if (availableBytes > 0) {
            if (availableBytes > PACKET_CAPACITY) {
              transferSize = PACKET_CAPACITY;
            }

            msg = (PartialDataMsg *) call Packet.getPayload(&packet, sizeof(PartialDataMsg));
            if (call Reader.readChunk((uint8_t *) msg->data, (uint16_t) transferSize) != SUCCESS) {
              _error = RS_ERR_PROGRAMMER;
              changeState(ERROR);
              break;
            }

            if (call RadioSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &packet, transferSize) != SUCCESS) {
              _error = RS_ERR_SEND_FAILED;
              changeState(ERROR);
              break;
            }
          } else {
            /* TODO: Use the state machine */
            signal RadioSender.sendDone();
          }
          break;
        case RECOVERY:
          printf("RECOVERY\n");
          /* Recover the requested packet */
          //PSEUDO CODE:
          /*packet = null;
          recoverSeq = _msgPayload;
          for (i = 0; i < sizeof(recoveryBuffer); i++)
            if (i == (currentSeq - recoverSeq) //something like that but it's a stupid guess
              packet = recoveryBuffer[i];*/

          msg = (PartialDataMsg *) call Packet.getPayload(&packet, sizeof(PartialDataMsg));
          if (call RadioSenderError.send[AM_MSG_RECOVERY](AM_BROADCAST_ADDR, &packet, transferSize) != SUCCESS) {
            _error = RS_ERR_SEND_FAILED;
            changeState(ERROR);
            break;
          }

          //TODO: Use another state to wait for the ACK ?
          changeSubState(WAITING);
          break;
        case END_OF_CHUNK:
          printf("END_OF_CHUNK\n");
          if (call RadioSend.send[AM_MSG_END_OF_CHUNK](AM_BROADCAST_ADDR, &packet, 0) != SUCCESS) {
            _error = RS_ERR_SEND_FAILED;
            changeState(ERROR);
            break;
          }

          //TODO: Use another state to wait for AM_MSG_ACK_END_OF_CHUNK ?
          changeSubState(WAITING);
          break;
        case END_OF_FILE:
          printf("END_OF_FILE\n");
          if (call RadioSend.send[AM_MSG_EOF](AM_BROADCAST_ADDR, &packet, 0) != SUCCESS) {
            _error = RS_ERR_SEND_FAILED;
            changeState(ERROR);
            break;
          }
          changeSubState(WAITING);
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
        invalid = (_state != ERROR);
        break;
      case READY:
        invalid = (_state != IDLE);
      case BEGIN_TRANSFER:
        invalid = (_state != READY);
        break;
      case SENDING_CHUNK:
        invalid = (_state != BEGIN_TRANSFER && _state != END_OF_CHUNK && _state != RECOVERY);
        break;
      case RECOVERY:
        invalid = (_state != SENDING_CHUNK && _state != END_OF_CHUNK);
        break;
      case END_OF_CHUNK:
        invalid = (_state != SENDING_CHUNK);
        break;
      case END_OF_FILE:
        invalid = (_state != SENDING_CHUNK);
    }

    if (invalid) {
      signal RadioSenderError.error(RS_ERR_INVALID_STATE);
      return;
    }

    _state = newState;
    post protocolIteration();
  }

  void changeSubState(SubState newState) {
    bool invalid = FALSE;
    switch (newState) {
      case SENDING:
        invalid = (_state != BEGIN_TRANSFER && _state != RECOVERY && _state != END_OF_CHUNK && _state != END_OF_FILE && _subState != WAITING);
        break;
      case WAITING:
        invalid = (_state != BEGIN_TRANSFER && _state != RECOVERY && _state != END_OF_CHUNK && _state != END_OF_FILE && _subState != SENDING);
    }

    if (invalid) {
      signal RadioSenderError.error(RS_ERR_INVALID_STATE);
      return;
    }

    _subState = newState;
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

    changeState(BEGIN_TRANSFER);
  }

  command bool RadioSender.canSend() {
    return (call Reader.available() > 0);
  }

  command bool RadioSender.canSendFullPacket() {
    return (call Reader.available() >= PACKET_CAPACITY);
  }

  command void RadioSender.sendPartialData() {
    if (_state != SENDING_CHUNK) {
      changeState(SENDING_CHUNK);
    } else {
      post protocolIteration();
    }
  }

  command void RadioSender.sendEOF() {
    changeState(END_OF_FILE);
  }

  event void RadioControl.startDone(error_t error) {
    if (error != SUCCESS) {
      _error = RS_ERR_INIT_FAILED;
      changeState(ERROR);
    }

    changeState(READY);
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

  event message_t* RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len) {
    atomic {
      _msgType = msg_type;
      _msgPayload = payload;
      /*if (_state == BEGIN_TRANSFER && msg_type == AM_MSG_ACK_BEGIN_FILE) {
        changeState(SENDING_CHUNK); //TODO: We might not want to run this iteration...
      } else if (_state == END_OF_CHUNK && msg_type == AM_MSG_ACK_END_OF_CHUNK) {
        changeState(SENDING_CHUNK); //TODO: We might not want to run this iteration...
      } else if (_state == SENDING_CHUNK && msg_type == AM_MSG_NACK_PARTIAL_DATA) {
        _recoverSeq = (uint16_t) payload; //TODO: Check this (just a random guess at midnight...)
        changeState(RECOVERY);
      } else if (_state == RECOVERY && msg_type == AM_MSG_ACK_RECOVERY) {
        changeState(SENDING_CHUNK);
      } else {
        _error = RS_ERR_INVALID_STATE;
        changeState(ERROR);
      }*/
    }
    return msg;
  }
}
