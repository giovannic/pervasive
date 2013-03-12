//## SStarting code for tutorial2 of the wireless sensor network
//## programing module of the pervasive systems course.

#define AM_TYPE 6

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as SensorTimer;
  components new TimerMilliC() as ReceiveLedTimer;
  components new TimerMilliC() as SendLedTimer;
  components new TempC() as Temp_Sensor;
  components new PhotoC() as Light_Sensor;
 
  components ActiveMessageC;
  components new AMSenderC(AM_TYPE);
  components new AMReceiverC(AM_TYPE);

  BlinkC -> MainC.Boot;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.ReceiveLedTimer -> ReceiveLedTimer;
  BlinkC.SendLedTimer -> SendLedTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;
  BlinkC.Light_Sensor -> Light_Sensor;

  BlinkC.Packet -> AMSenderC;
  BlinkC.AMPacket -> AMSenderC;
  BlinkC.AMSend -> AMSenderC;
  BlinkC.Receive -> AMReceiverC;
  BlinkC.AMControl -> ActiveMessageC;
}


// MIG takes a header file with message spec and will generate java classes for it
