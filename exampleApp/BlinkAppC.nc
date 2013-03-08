//## SStarting code for tutorial2 of the wireless sensor network
//## programing module of the pervasive systems course.

configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as SensorTimer;
  components new TimerMilliC() as LedTimer;
  components new TempC() as Temp_Sensor;
 
  // TODO Parametrize that
  components ActiveMessageC;
  components new AMSenderC(6);
  // components new AMReceiverC(6);

  BlinkC -> MainC.Boot;

  BlinkC.SensorTimer -> SensorTimer;
  BlinkC.LedTimer -> LedTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;

  BlinkC.Packet -> AMSenderC;
  BlinkC.AMPacket -> AMSenderC;
  BlinkC.AMSend -> AMSenderC;
  BlinkC.AMControl -> ActiveMessageC;
}


// MIG takes a header file with message spec and will generate java classes for it
