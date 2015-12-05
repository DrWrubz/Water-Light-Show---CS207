/*A very important note. You have first to compile and upload the arduino code, otherwise
it will give you a serial error.

Also, if you want the stereo mix as an input (the sound that is going through your speakers), you
have to change it in windows (or mac and linux as well, i'm not sure) as the main input for recording.
This is easily done in windows vista and 7 right clicking the general volume button, choosing recording
options, and selecting stereo mix as the main one. You'll probably have to switch off (software) the
microphone input, too. If you don't see this options, right click your microphone, and check all
options to make sure stereo mix (or something like that) is shown. You'll have to restart this Processing
sketch in order to make it work.

The things you need to make it work are told in the arduino code.
*/
import processing.serial.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

Serial port;

AudioInput in;
Minim minim;
FFT fftLin;
//I used an example of FFT as a base, and tweaked it a bit.

float vectormedias[]=new float[5]; // this keeps the averages of the 5 bands of frequency.
float magnitud=4; //general setting, it multiplies all volume signal.
float volumen;  // this measures the general volume, but it changes slowly (like a P control) to avoid noise
int volcaptado; // this is the final volume sent to arduino for a certain led. It gives the index to the brightness vector.

void setup()
{
  println(Serial.list());
  if (port==null)
    port = new Serial(this, Serial.list()[1], 9600);
    //perhaps in your case is Serial.list()[0]
  size(512, 300, P3D);
  volumen=1;

  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 2048);
  fftLin = new FFT(in.bufferSize(), in.sampleRate());
  fftLin.linAverages(240);
  //It takes 240 bands of frequency (linear). This is to avoid noise or strange sounds. (perhaps not needed)
 // Later, the maximum of a certain range of this bars will be taken.
  rectMode(CORNERS);
}

void draw()
{
  background(0);
  // perform a forward FFT on the samples in jingle's mix buffer
  // note that if jingle were a MONO file, this would be the same as using jingle.left or jingle.right
  fftLin.forward(in.mix);

  noStroke();
  fill(255);
  int w = int(width/5);
  //next follows a for that gets the maximum of certain ranges of bars, for 6 LEDs
  for(int i = 0; i < 120; i++)
  {
    if (i<=1)
    {
      if (vectormedias[0]<2*fftLin.getAvg(i))
        vectormedias[0]=2*fftLin.getAvg(i);
      // Each range has a multiplier, to adjust the visual response. This is based on tests, feel free to change it.
      // I changed them a lot, feel free to change what bars are included too. Some will be OK for certain music, or not.
    }
    else if (i<=10)
    {
      if (vectormedias[1]<1.2*fftLin.getAvg(i))
        vectormedias[1]=1.2*fftLin.getAvg(i);
    }
    else if (i<=12)
    {
      if (vectormedias[2]<1.6*fftLin.getAvg(i))
        vectormedias[2]=1.6*fftLin.getAvg(i);
    }
    else if (i<=15)
    {
      if (vectormedias[3]<1.75*fftLin.getAvg(i))
        vectormedias[3]=1.75*fftLin.getAvg(i);
    }
    
    if (i<=200)
    {
      //This is the last one. It is multiplied by the bar index, to give more weight to the final frequencies (that tend to be lower always).
      //This gives good feedback for noise, high pitch sounds, or percusion instruments.
      vectormedias[4]=i*fftLin.getAvg(i)/300+vectormedias[5];
    }
    if (i==119)
    {
      for (byte k=0;k<5;k++)
      { delay(10);
        fill(255);
          //The following number is important. It is the level that is taken as real input, if you catch noise
         //you will have to make it a bit bigger. If you don't have any noise, perhaps a lower number is better
          if (in.mix.level()>0.001)
          { /*This keeps the volume changing with the in.mix level. However, we don't want it to change
             very fast, because in.mix.level is very variable. Otherwise, you'll see low sounds as big as high sounds.
             And we don't want it to be constant, otherwise when the volume is low you won¡t see anything.
             Feel free to change the values to change faster or slower though (keeping the sum as 1.00, don't mind the *10)*/
            volumen=volumen*0.998+in.mix.level()*0.002*10; // the *10 is cause the in.mix.level is usually 0.1. I wanted it to be closer to 1.
              //println(in.mix.level());  //uncomment this if you want to try to change the volume control
             volcaptado=int(magnitud*vectormedias[k]/volumen);
             //This is the last step. It gives the amount of volume to the graphic bars and the arduino.
              if (volcaptado>300)
                volcaptado=300;
                //we don't want it to be VERY big.
              volcaptado=volcaptado/10;
              //the arduino will get a value between 0 and 30 as the volume input. A same, but it is necessary as we'll need 3 bits to select the LED,
              //and we have 5 more (up to 31). I could have used 0 to 31, but I was lazy.
            
             port.write((k<<5)|byte(volcaptado));
             //This gives the arduino wich led it is with K, and the value of volcaptado.
             // it works like this:  XXX | XXXXX
             // first the number of the LED, and last the amount of volume. The serial port only send one byte (eight bits) so it has to be like that.
             // Another option would be giving a certain number to sync arduino and processing, like 0, v1, v2, v3, v4, v5, v6 ,  (and repeat).
             // However, the LED's change so fast that with 30 values I found it enough. Feel free to change it, though.
             rect(k*w, height, k*w + w, height - magnitud*vectormedias[k]/volumen);
             //and this draws the rectangles in your processing window If you don't want this feedback, just comment the line above.
          }
          else{
            //We get here if the in.mix.level is very low. So no sound is received. You'll receive noise only.
            volumen=0.4;
            //We put a low volume as a base (so when a sound comes in, the LED will bright more than usual)
            port.write((k<<5));
            // We tell the arduino to put all LED's with a volume of 0.
            delay(100);
            // change the delay if you want, or even delete it.
          }
      
        vectormedias[k]=0;
        // we delete the previous maximums, to make new ones in the next iteration.

      }
    }

  }

}

void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  // always stop Minim before exiting
  minim.stop();

  super.stop();
  // send led=0 before exiting
  port.write(0);
} 

