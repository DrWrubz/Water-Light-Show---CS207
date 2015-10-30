/*You'll need 6 LEDS to make it work, connected to the PWM pins on the arduino duemilanove.
If you have the arduino mega, you could put more LEDs, feel free to change the code.

I used a 100 ohm resistor, you can watch the LEDs I used (and a demo) on this video:

http://www.youtube.com/watch?v=pH9U5miKfcc

*/

const int vectledPin[]={3,5,6,9,10,11};

/*These are the values that will be given to the PWM ports on the arduino. The arduino will receive values between 0 and 30,
that measures the "volume" linearlly. However, the LED's don't bright linearlly, so I tested it a bit and put these values
as my own testing. I used the DIMMER sketch example on the arduino program to know what values to use.
Feel free to change them. One small change would be to make two vectors, as I used two different types of LEDs.*/

const int vectbright[]={0,1,2,3,4,6,8,19,14,18,22,27,32,38,47,56,66,76,86,96,105,114,122,130,138,148,162,190,222,255,255};
int i=0;

void setup()
{
  // initialize the serial communication:
  Serial.begin(9600);
  // initialize the ledPin as an output:
  for (i=0;i<6;i++)
    pinMode(vectledPin[i], OUTPUT);
  i=0;
}

void loop() {
  byte brightness;
  byte led;

  // check if data has been sent from the computer:
  if (Serial.available()) {
    // read the most recent byte (which will be from 0 to 255):
    brightness = Serial.read();
    led=(brightness>>5);
    //This reads what LED it is (it is stored on the 3 high bits)
    
    brightness=((brightness)&0x1F);
    //and this reads the 5 lower bits only. It puts a 0 in the higher ones.
    
   analogWrite(vectledPin[led], vectbright[brightness]);
   //and finally, using both vectors and the brightness index, the PWM value is sent
  }
} 

