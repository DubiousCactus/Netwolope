// $Id: BlinkAppC.nc,v 1.5 2009/10/26 07:34:10 vlahan Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Blink is a basic application that toggles a mote's LED periodically.
 * It does so by starting a Timer that fires every second. It uses the
 * OSKI TimerMilli service to achieve this goal.
 *
 * @author tinyos-help@millennium.berkeley.edu
 **/
#include "RadioHeader.h"
configuration Program
{
}
implementation
{
	/*
  components MainC, ReceiverTest, LedsC;
  components RadioReceiverM as RR;
  components new TimerMilliC() as Timer2;

  components ActiveMessageC;
  components new AMSenderC(COMMUNICATION_ADDRESS);
  components new AMReceiverC(COMMUNICATION_ADDRESS);

  ReceiverTest -> MainC.Boot;
  
  ReceiverTest.RR -> RR;
  
  RR.Packet -> AMSenderC;
  RR.AMPacket -> AMSenderC;
  RR.AMSend -> AMSenderC;
  RR.Receive -> AMReceiverC;
  RR.Leds -> LedsC;
  RR.AMControl -> ActiveMessageC;

  ReceiverTest.Timer2 -> Timer2;
  ReceiverTest.Leds -> LedsC;
  /**/
  
  /**/
  components MainC, SenderTest, LedsC;
  components RadioSenderM as RS;
  components new TimerMilliC() as Timer2;

  components ActiveMessageC;
  components new AMSenderC(COMMUNICATION_ADDRESS);
  components new AMReceiverC(COMMUNICATION_ADDRESS);

  SenderTest -> MainC.Boot;
  
  SenderTest.RS -> RS;
  
  RS.Packet -> AMSenderC;
  RS.AMPacket -> AMSenderC;
  RS.AMSend -> AMSenderC;
  RS.Receive -> AMReceiverC;
  RS.Leds -> LedsC;
  RS.AMControl -> ActiveMessageC;

  SenderTest.Timer2 -> Timer2;
  SenderTest.Leds -> LedsC;
  /**/
}

