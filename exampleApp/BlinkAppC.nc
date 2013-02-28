configuration BlinkAppC
{
}
implementation
{
  components MainC, BlinkC, LedsC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as FlashTimer;
  components new TempC() as Temp_Sensor;
  components new ActiveMessageC() as Message;
  components new AMSenderC() as Sender;
  components new AMReceiverC() as Receiver;

  BlinkC -> MainC.Boot;

  BlinkC.Timer0 -> Timer0;
  BlinkC.FlashTimer -> FlashTimer;
  BlinkC.Leds -> LedsC;
  BlinkC.Temp_Sensor -> Temp_Sensor;
  BlinkC.Message -> Message;
  BlinkC.Receiver -> Receiver;
  BlinkC.Sender -> Sender;
}
