//  SYPHON SUPPORT
// --------------------------------------------------------------------------------

import codeanticode.syphon.*;    // import syphon library

SyphonServer     server;     
PGraphics    canvas;

private void setupSyphonServer(String inServerName)
{
    // Create syhpon server to send frames out.
    server = new SyphonServer(this, inServerName);
}
// --------------------------------------------------------------------------------
//  EXIT HANDLER
// --------------------------------------------------------------------------------
// called on exit to gracefully shutdown the Syphon server
private void prepareExitHandler()
{
    Runtime.getRuntime().addShutdownHook(
    new Thread(
    new Runnable()
    {
        public void run () {
            try {
                if (server.hasClients()) {
                    server.stop();
                }
            } 
            catch (Exception ex) {
                ex.printStackTrace(); // not much else to do at this point
            }
        }
    }
    )
        );
}
import processing.opengl.*; 
import SimpleOpenNI.*;
//install this on your machine and also the library in processing
//http://code.google.com/p/simple-openni/wiki/Installation


SimpleOpenNI kinect;
//based on Greg's Book Making things see.
boolean tracking = false; 
int userID; int[] userMap; 
// declare our images 
PImage backgroundImage; 
PImage resultImage;

//-------------------------------------------------------
//  BLOB DETECTION
// from blobscanner Antonio Molinaro (c) 20/07/2013
//-------------------------------------------------------
import blobscanner.*;
PImage blobs;
Detector bs;
PVector []  edge  ; 
int i;

void setup() {
  size(640*2, 480, P3D);
  canvas = createGraphics(640, 480, P3D);
  
  // load the background image 
  backgroundImage = loadImage("http://iwallpapers2.free.fr/images/Photographie/Black_Collection/Lumiere_fond_noir_HD.jpg");
  kinect = new SimpleOpenNI(this);
  if(kinect.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
    // setup Syphon server
    println("Setup Syphon");
    setupSyphonServer("Depth");
      // setup the exit handler
    println("Setup Exit Handerl");
    prepareExitHandler();
  
  // enable depthMap generation 
 kinect.enableDepth();
   
  // enable skeleton generation for all joints
  kinect.enableUser();
  // enable color image from the Kinect
  kinect.enableRGB();
  //enable the finding of users but dont' worry about skeletons

  // turn on depth/color alignment
  kinect.alternativeViewPointDepthToImage();
  //create a buffer image to work with instead of using sketch pixels
  resultImage = new PImage(640, 480, RGB);
  
  //setup blob detector
  bs = new Detector( this, 0 );
  blobs = createImage(640/3, 480/3, RGB);
    
}
void draw() {
  kinect.update();
  // get the Kinect color image
  PImage rgbImage = kinect.rgbImage();

  image(rgbImage, 640, 0);
  if (tracking) {
    //ask kinect for bitmap of user pixels
    loadPixels();
    userMap = kinect.userMap();
    for (int i =0; i < userMap.length; i++) {
      // if the pixel is part of the user
      if (userMap[i] != 0) {
        // set the pixel to the color pixel
        resultImage.pixels[i] = color(255,255,255);//rgbImage.pixels[i];
      }
      else {
        //set it to the background
        resultImage.pixels[i] = color (0, 0, 0);//backgroundImage.pixels[i];
      }
    }
    
    //update the pixel from the inner array to image
     resultImage.updatePixels();
     
     //copy the image in a smaller blob image
     blobs.copy(resultImage, 0, 0, resultImage.width, resultImage.height, 0, 0, blobs.width, blobs.height);
     
     bs.imageFindBlobs(blobs);
     bs.loadBlobsFeatures();
   
     //For each blob
     for (int i = 0; i < bs.getBlobsNumber (); i++) {
   
       //gets the edge's pixels coordinates  
       edge  = bs.getEdgePoints(i);
       if (edge.length < 100) {
        continue;
       } 
       canvas.stroke(0, 255, 0); 
         
       for (int k = 0; k < edge .length; k++) {
         canvas.point(edge[k] .x*3, edge[k] .y*3 );
       }
       //and sends to the std. output an ok. 
       println("Tile " + (i+1) + " size " + edge .length +" --OK");
   
     }
    image(canvas, 0, 0, 640, 480);
  }  // send image to syphon
  canvas.image(resultImage, 0, 0);
    server.sendImage(canvas);
}


void onNewUser(SimpleOpenNI curContext, int userId)
{
 userID = userId;
  tracking = true;
  println("tracking");
  //curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
  //println("onVisibleUser - userId: " + userId);
}
