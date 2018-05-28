module BetterRadioSenderM {
  provides interface BetterRadioSender;

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
          break;
        case READY:
          signal BetterRadioSender.initDone();
          break;
        case BEGIN_TRANSFER:
          switch (_subState) {
            case SENDING:
              /* TODO: Call Packet.getPayload() here or what ?? */
              if (call RadioSend.send[AM_MSG_BEGIN_FILE](AM_BROADCAST_ADDR, &packet, sizeof(BeginFileMsg)) != SUCCESS) {
                _error = RS_ERR_SEND_FAILED;
                changeState(ERROR);
                break;
              }
              changeSubState(RECEIVING);
              break;
            case RECEIVING:
              if (_msgType == AM_MSG_ACK_BEGIN_FILE) {
                _msgType = 0;
                signal BetterRadioSender.fileBeginAcknowledged();
                changeSubState(WAITING); //Wait for compression
                changeState(SENDING_CHUNK);
                break;
              }
          }
          break;
        case SENDING_CHUNK:
          if (_msgType == AM_MSG_NACK_PARTIAL_DATA) {
            _msgType = 0;
            changeState(RECOVERY);
            break;
          }

          switch (_subState) {
            case WAITING:
              if (availableBytes > 0) {
                changeSubState(SENDING);
                break;
              }
              break;
            case SENDING:
              if (availableBytes <= 0) {
                signal BetterRadioSender.sendDone();
                break;
              }

              /* Only send what we can afford to */
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
              break;
            case RECEIVING:
              /* Not used here */
              break;
          }
          break;
        case RECOVERY:
          /* Recover the requested packet */
          //PSEUDO CODE:
          /*packet = null;
          recoverSeq = _msgPayload;
          for (i = 0; i < sizeof(recoveryBuffer); i++)
            if (i == (currentSeq - recoverSeq) //something like that but it's a stupid guess
              packet = recoveryBuffer[i];*/

          msg = (PartialDataMsg *) call Packet.getPayload(&packet, sizeof(PartialDataMsg));
          if (call RadioSend.send[AM_MSG_RECOVERY](AM_BROADCAST_ADDR, &packet, transferSize) != SUCCESS) {
            _error = RS_ERR_SEND_FAILED;
            changeState(ERROR);
            break;
          }

          changeSubState(RECEIVING);
          break;
        case END_OF_CHUNK:
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
                _msgType = 0;
                changeSubState(SENDING);
                changeState(SENDING_CHUNK);
              }
          }
          break;
        case END_OF_FILE:
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
                _msgType = 0;
                changeSubState(SENDING);
                changeState(IDLE);
              }
          }
          break;
        case ERROR:
          signal BetterRadioSender.error(_error);
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
      signal BetterRadioSender.error(RS_ERR_INVALID_STATE);
      return;
    }

    _state = newState;
    post protocolIteration();
  }

  void changeSubState(SubState newState) {
    bool invalid = FALSE;
    switch (newState) {
      case WAITING:
        invalid = (_state != BEGIN_TRANSFER && _subState != RECEIVING);
        break;
      case SENDING:
        invalid = (_state != READY &&_state != BEGIN_TRANSFER && _state != RECOVERY && _state != END_OF_CHUNK && _state != END_OF_FILE && _subState != RECEIVING && _subState != WAITING);
        break;
      case RECEIVING:
        invalid = (_state != BEGIN_TRANSFER && _state != RECOVERY && _state != END_OF_CHUNK && _state != END_OF_FILE && _subState != SENDING);
    }

    if (invalid) {
      signal BetterRadioSender.error(RS_ERR_INVALID_STATE);
      return;
    }

    _subState = newState;
    post protocolIteration();
  }

  /* TODO: Move the call to RadioControl.start() to somewhere when we NEED the radio ON
   * and then remove the READY state. Do the same for RadioControl.stop(). Use the events
   * to switch states.
   */
  command void BetterRadioSender.init() {
    /* TODO: Move this to the IDLE State !!*/
    if (_state == IDLE)
      call RadioControl.start();
  }

  command void BetterRadioSender.sendFileBegin(uint32_t uncompressedSize, uint8_t compressionType) {
    beginFileMsg = (BeginFileMsg *) call Packet.getPayload(&packet, sizeof(BeginFileMsg));
    beginFileMsg->uncompressedSize = uncompressedSize;
    beginFileMsg->compressionType = compressionType;

    changeSubState(SENDING);
    changeState(BEGIN_TRANSFER);
  }

  command bool BetterRadioSender.canSend() {
    return (call Reader.available() > 0);
  }

  command bool BetterRadioSender.canSendFullPacket() {
    return (call Reader.available() >= PACKET_CAPACITY);
  }

  command void BetterRadioSender.sendPartialData() {
    post protocolIteration();
  }

  command void BetterRadioSender.sendEOF() {
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
      _msgType = msg_type;
      _msgPayload = (uint16_t) payload; //The payload can only be a sequence number
      post protocolIteration();
    }
    return msg;
  }
}
