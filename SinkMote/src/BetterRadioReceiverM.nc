module BetterRadioReceiver {
  provides interface BetterRadioReceiver;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend as RadioSend[am_id_t msg_type];
  uses interface Receive as RadioReceive[am_id_t msg_type];
  uses interface SplitControl as RadioControl;

} implementation {

  /* Functions and tasks definitions */
  void changeState(State newState);
  void changeSubState(SubState newState);

  State _state = IDLE;
  SubState _subState;
  RadioReceiverError _error;
  MessageType _msgType;
  BeginFileMsg *_msgBeginFilePayload;
  PartialMsg *_msgPayload;
  NackMsg *nack;
  uint16_t _msgLength;
  uint16_t _msgChunkSize;
  uint32_t _recoverSeq = 0;
  uint32_t _lastSequence = 0;
  message_t packet;
  BeginFileMsg *beginFileMsg;

  task void protocolIteration() {
    switch (_state) {
      case IDLE:
        call RadioControl.stop();
        break;
      case READY:
        signal BetterRadioReceiver.initDone();
        changeSubState(RECEIVING);
        changeState(BEGIN_TRANSFER);
        break;
      case BEGIN_TRANSFER:
        switch (_subState) {
          case RECEIVING:
            if (_msgType != AM_MSG_BEGIN_FILE) {
              _error = RR_ERR_WRONG_MSG;
              changeState(ERROR);
              break;
            }

            signal BetterRadioReceiver.receivedFileBegin(_msgBeginFilePayload->uncompressedSize, _msgBeginFilePayload->compressionType);
            changeSubState(SENDING);
            break;
          case SENDING:
            if (call RadioSend.send[AM_MSG_ACK_EOF](AM_BROADCAST_ADDR, &packet, 0) != SUCCESS) {
              _error = RR_ERR_SEND_FAILED;
              changeState(ERROR);
            }
          break;
      }
      case RECEIVING_CHUNK:
        if (_msgType != AM_MSG_PARTIAL_DATA) {
          _error = RR_ERR_WRONG_MSG;
          changeState(ERROR);
          break;
        }

        if (_msgPayload->seq != (_lastSequence + 1)) {
          _recoverSeq = _lastSequence + 1;
          changeSubState(SENDING);
          changeState(RECOVERY);
          break;
        }

        signal BetterRadioReceiver.receivedData((uint8_t *) _msgPayload->data, (uint16_t) _msgLength);
        break;
      case RECOVERY:
        switch (_subState) {
          case SENDING:
            nack->seq = _recoverSeq;
            nack = (NackMsg *) call Packet.getPayload(&packet, sizeof(NackMsg));
            if (call RadioSend.send[AM_MSG_RECOVERY](AM_BROADCAST_ADDR, &packet, sizeof(uint32_t)) != SUCCESS) {
              _error = RR_ERR_SEND_FAILED;
              changeState(ERROR);
            }

            changeSubState(RECEIVING);
            break;
          case RECEIVING:
            if (_msgType != AM_MSG_ACK_RECOVERY) {
              _error = RR_ERR_WRONG_MSG;
              changeState(ERROR);
              break;
            }

            /* TODO: Recover the packet from the payload */
            changeState(RECEIVING_CHUNK);
            break;
        }
        break;
      case END_OF_CHUNK:
        switch (_subState) {
          case SENDING:
            break;
          case RECEIVING:
            break;
        }
        break;
      case END_OF_FILE:
        switch (_subState) {
          case SENDING:
            break;
          case RECEIVING:
            if (_msgType != AM_MSG_EOF) {
              _error = RR_ERR_WRONG_MSG;
              changeState(ERROR);
              break;
            }

            signal BetterRadioReceiver.receivedEOF();
            break;
        }
        break;
      case ERROR:
          signal BetterRadioReceiver.error(_error);
          changeState(IDLE);
        break;
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
      case RECEIVING_CHUNK:
        invalid = (_state != BEGIN_TRANSFER && _state != END_OF_CHUNK && _state != RECOVERY);
        break;
      case RECOVERY:
        invalid = (_state != RECEIVING_CHUNK && _state != END_OF_CHUNK);
        break;
      case END_OF_CHUNK:
        invalid = (_state != RECEIVING_CHUNK);
        break;
      case END_OF_FILE:
        invalid = (_state != RECEIVING_CHUNK);
        break;
      case ERROR:
        //Everyone is welcome !
    }

    if (invalid) {
      signal BetterRadioReceiver.error(RR_ERR_INVALID_STATE);
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
      signal BetterRadioReceiver.error(RR_ERR_INVALID_STATE);
      return;
    }

    _subState = newState;
    post protocolIteration();
  }

  /* TODO: Move the call to RadioControl.start() to somewhere when we NEED the radio ON
   * and then remove the READY state. Do the same for RadioControl.stop(). Use the events
   * to switch states.
   */
  command void BetterRadioReceiver.init() {
    /* TODO: Move this to the IDLE State !!*/
    if (_state == IDLE)
      call RadioControl.start();
  }

  event void RadioControl.startDone(error_t error) {
    changeState(READY);
  }

  event void RadioControl.stopDone(error_t error) { }

  event void RadioSend.sendDone[am_id_t msg_type](message_t *msg, error_t error) {
    if (error != SUCCESS) {
      _error = RR_ERR_SEND_FAILED;
      changeState(ERROR);
    }
  }

  event message_t * RadioReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len) {
    atomic {
      _msgType = msg_type;

      if (msg_type == AM_MSG_BEGIN_FILE) {
        _msgBeginFilePayload = (BeginFileMsg *) payload;
      } else if (msg_type == AM_MSG_PARTIAL_DATA) {
        _msgPayload = (PartialMsg *) payload;
        _msgLength = len;
      } else if (msg_type == AM_MSG_END_OF_CHUNK) {
        _msgChunkSize = (uint16_t) payload;
      }
    }

    return msg;
  }
}
