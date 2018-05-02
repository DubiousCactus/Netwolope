#include "RadioSender.h" 
#include "printf.h"

module RadioSenderM {
  provides interface RadioSender;

  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as RadioSend[am_id_t msg_type];
  uses interface Receive as RadioReceive[am_id_t msg_type];
  uses interface SplitControl as RadioControl;
  uses interface CircularBufferReader as Reader;

} implementation {

  /* Functions and tasks definitions */
  void changeState(State newState);
  void changeSubState(SubState newState);

  State _state = IDLE;
  SubState _subState;
  RadioSenderError _error;
  MessageType _msgType;
  uint16_t _msgPayload;
  message_t packet;
  BeginFileMsg *beginFileMsg;

  /* Runs through the state machine to execute the appropriate actions */
  task void protocolIteration() {
      PartialDataMsg *msg;
      uint16_t availableBytes = call Reader.available();
      uint8_t transferSize = availableBytes;

      switch (_state) {
        case IDLE:
          call RadioControl.stop();
          printf("IDLE\n");
          break;
        case READY:
          printf("READY\n");
          signal RadioSender.initDone();
          break;
        case BEGIN_TRANSFER:
          printf("BEGIN_TRANSFER\n");
          switch (_subState) {
            case SENDING:
              /* TODO: Call Packet.getPayload() here or what ?? */
              printf("\tSending AM_MSG_BEGIN_FILE\n");
              if (call RadioSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &packet, sizeof(BeginFileMsg)) != SUCCESS) {
                _error = RS_ERR_SEND_FAILED;
                changeState(ERROR);
                break;
              }
              printf("\tSetting sub state to RECEIVING\n");
              changeSubState(RECEIVING);
              break;
            case RECEIVING:
              if (_msgType == AM_MSG_ACK_BEGIN_FILE) {
                printf("\tReceived AM_MSG_ACK_BEGIN_FILE\n");
                _msgType = 0;
                printf("\tChanging state to SENDING_CHUNK\n");
                changeSubState(SENDING);
                changeState(SENDING_CHUNK);
                break;
              }
          }
          break;
        case SENDING_CHUNK:
          printf("SENDING_CHUNK\n");
          if (_msgType == AM_MSG_NACK_PARTIAL_DATA) {
            printf("\tReceived AM_MSG_NACK_PARTIAL_DATA\n");
            _msgType = 0;
            changeState(RECOVERY);
            break;
          }

          switch (_subState) {
            case WAITING:
              printf("\tAvailable bytes: %d\n", availableBytes);
              if (availableBytes > 0) {
                changeSubState(SENDING);
                break;
              } else {
                printf("\tNo more bytes available. Signaling ((done))\n");
                signal RadioSender.sendDone();
              }
              break;
            case SENDING:
              if (availableBytes < 0) {
                changeSubState(WAITING);
                break;
              }
              if (availableBytes > PACKET_CAPACITY) {
                transferSize = PACKET_CAPACITY;
              }

              msg = (PartialDataMsg *) call Packet.getPayload(&packet, sizeof(PartialDataMsg));
              printf("\tReading %d bytes from the circular buffer\n", transferSize);
              if (call Reader.readChunk((uint8_t *) msg->data, (uint16_t) transferSize) != SUCCESS) {
                _error = RS_ERR_PROGRAMMER;
                changeState(ERROR);
                break;
              }

              printf("\tSending AM_MSG_PARTIAL_DATA\n");
              if (call RadioSend.send[AM_MSG_PARTIAL_DATA](AM_BROADCAST_ADDR, &packet, transferSize) != SUCCESS) {
                _error = RS_ERR_SEND_FAILED;
                changeState(ERROR);
                break;
              }
              break;
            case RECEIVING:
              break;
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

          printf("\tSending AM_MSG_RECOVERY\n");
          msg = (PartialDataMsg *) call Packet.getPayload(&packet, sizeof(PartialDataMsg));
          if (call RadioSend.send[AM_MSG_RECOVERY](AM_BROADCAST_ADDR, &packet, transferSize) != SUCCESS) {
            _error = RS_ERR_SEND_FAILED;
            changeState(ERROR);
            break;
          }

          //TODO: Use another state to wait for the ACK ?
          changeSubState(RECEIVING);
          break;
        case END_OF_CHUNK:
          printf("END_OF_CHUNK\n");
          switch (_subState) {
            case SENDING:
              if (call RadioSend.send[AM_MSG_END_OF_CHUNK](AM_BROADCAST_ADDR, &packet, 0) != SUCCESS) {
                _error = RS_ERR_SEND_FAILED;
                changeState(ERROR);
                break;
              }
              changeSubState(RECEIVING);
              break;
            case RECEIVING:
              if (_msgType == AM_MSG_ACK_END_OF_CHUNK) {
                printf("\tReceived AM_MSG_ACK_END_OF_CHUNK\n");
                _msgType = 0;
                changeSubState(SENDING);
                changeState(SENDING_CHUNK);
              }
          }

          //TODO: Use another state to wait for AM_MSG_ACK_END_OF_CHUNK ?
          /*changeSubState(RECEIVING);*/
          break;
        case END_OF_FILE:
          printf("END_OF_FILE\n");
          switch (_subState) {
            case SENDING:
              if (call RadioSend.send[AM_MSG_EOF](AM_BROADCAST_ADDR, &packet, 0) != SUCCESS) {
                _error = RS_ERR_SEND_FAILED;
                changeState(ERROR);
                break;
              }
              changeSubState(RECEIVING);
            case RECEIVING:
              if (_msgType == AM_MSG_ACK_EOF) {
                printf("\tReceived AM_MSG_ACK_EOF\n");
                _msgType = 0;
                changeSubState(SENDING);
                changeState(IDLE);
              }
          }
          break;
        case ERROR:
          printf("ERROR\n");
          signal RadioSender.error(_error);
          changeState(IDLE);
      }
    printfflush();
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
        break;
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
        break;
      case ERROR:
        //Everyone is welcome !
    }

    if (invalid) {
      signal RadioSender.error(RS_ERR_INVALID_STATE);
      return;
    }

    _state = newState;
    post protocolIteration();
  }

  void changeSubState(SubState newState) {
    bool invalid = FALSE;
    switch (newState) {
      case SENDING:
        invalid = (_state != BEGIN_TRANSFER && _state != RECOVERY && _state != END_OF_CHUNK && _state != END_OF_FILE && _subState != RECEIVING);
        break;
      case RECEIVING:
        invalid = (_state != BEGIN_TRANSFER && _state != RECOVERY && _state != END_OF_CHUNK && _state != END_OF_FILE && _subState != SENDING);
    }

    if (invalid) {
      signal RadioSender.error(RS_ERR_INVALID_STATE);
      return;
    }

    _subState = newState;
    post protocolIteration();
  }

  /* TODO: Move the call to RadioControl.start() to somewhere when we NEED the radio ON
   * and then remove the READY state. Do the same for RadioControl.stop(). Use the events
   * to switch states.
   */
  command void RadioSender.init() {
    if (_state == IDLE)
      call RadioControl.start();
  }

  command void RadioSender.sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType) {
    beginFileMsg = (BeginFileMsg *) call Packet.getPayload(&packet, sizeof(BeginFileMsg));
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
    printf("\t* RadioSender.sendPartialData(): post protocolIteration();\n");
    post protocolIteration();
  }

  command void RadioSender.sendEOF() {
    printf("\t* RadioSender.sendEOF(): changeState(END_OF_FILE);\n");
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
    atomic {
      if (error != SUCCESS) {
        _error = RS_ERR_SEND_FAILED;
        changeState(ERROR);
      }
    }
  }

  event message_t* RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len) {
    atomic {
      printf("\t* Receiving message of type %d\n", msg_type);
      _msgType = msg_type;
      _msgPayload = (uint16_t) payload; //The payload can only be a sequence number
      post protocolIteration();
    }
    return msg;
  }
}
