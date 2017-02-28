/* --------------------------------------------------------------------------
 * SimpleOpenNI User Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect 2 library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/
 * date:  12/12/2012 (m/d/y)
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;

PGraphics    canvas;
color[]      userClr = new color[]
{
    color(255, 0, 0), 
    color(0, 255, 0), 
    color(0, 0, 255), 
    color(255, 255, 0), 
    color(255, 0, 255), 
    color(0, 255, 255)
};

PVector com = new PVector();                                   
PVector com2d = new PVector();                                   

// --------------------------------------------------------------------------------
//  CAMERA IMAGE SENT VIA SYPHON
// --------------------------------------------------------------------------------
int kCameraImage_RGB = 1;                // rgb camera image
int kCameraImage_IR = 2;                 // infra red camera image
int kCameraImage_Depth = 3;              // depth without colored bodies of tracked bodies
int kCameraImage_User = 4;               // depth image with colored bodies of tracked bodies

int kCameraImageMode = kCameraImage_User; // << Set thie value to one of the kCamerImage constants above

// --------------------------------------------------------------------------------
//  SKELETON DRAWING
// --------------------------------------------------------------------------------
boolean kDrawSkeleton = true; // << set to true to draw skeleton, false to not draw the skeleton

// --------------------------------------------------------------------------------
//  OPENNI (KINECT) SUPPORT
// --------------------------------------------------------------------------------

import SimpleOpenNI.*;           // import SimpleOpenNI library

SimpleOpenNI     context;

private void setupOpenNI()
{
    context = new SimpleOpenNI(this);
    if (context.isInit() == false) {
        println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
        exit();
        return;
    }   

    // enable depthMap generation 
    context.enableDepth();
    context.enableUser();

    // disable mirror
    context.setMirror(false);
}

private void setupOpenNI_CameraImageMode()
{
    println("kCameraImageMode " + kCameraImageMode);

    switch (kCameraImageMode) {
    case 1: // kCameraImage_RGB:
        context.enableRGB();
        println("enable RGB");
        break;
    case 2: // kCameraImage_IR:
        context.enableIR();
        println("enable IR");
        break;
    case 3: // kCameraImage_Depth:
        context.enableDepth();
        println("enable Depth");
        break;
    case 4: // kCameraImage_User:
        context.enableUser();
        println("enable User");
        break;
    }
}

private void OpenNI_DrawCameraImage()
{
    switch (kCameraImageMode) {
    case 1: // kCameraImage_RGB:
        canvas.image(context.rgbImage(), 0, 0);
        // println("draw RGB");
        break;
    case 2: // kCameraImage_IR:
        canvas.image(context.irImage(), 0, 0);
        // println("draw IR");
        break;
    case 3: // kCameraImage_Depth:
        canvas.image(context.depthImage(), 0, 0);
        // println("draw DEPTH");
        break;
    case 4: // kCameraImage_User:
        canvas.image(context.userImage(), 0, 0);
        // println("draw DEPTH");
        break;
    }
}

// --------------------------------------------------------------------------------
//  OSC SUPPORT
// --------------------------------------------------------------------------------

import oscP5.*;                  // import OSC library
import netP5.*;                  // import net library for OSC

OscP5            oscP5;                     // OSC input/output object
NetAddress       oscDestinationAddress;     // the destination IP address - 127.0.0.1 to send locally
int              oscTransmitPort = 1234;    // OSC send target port; 1234 is default for Isadora
int              oscListenPort = 9000;      // OSC receive port number

private void setupOSC()
{
    // init OSC support, lisenting on port oscTransmitPort
    oscP5 = new OscP5(this, oscListenPort);
    oscDestinationAddress = new NetAddress("127.0.0.1", oscTransmitPort);
}

private void sendOSCSkeletonPosition(String inAddress, int inUserID, int inJointType)
{
    // create the OSC message with target address
    OscMessage msg = new OscMessage(inAddress);

    PVector p = new PVector();
    float confidence = context.getJointPositionSkeleton(inUserID, inJointType, p);

    // add the three vector coordinates to the message
    msg.add(p.x);
    msg.add(p.y);
    msg.add(p.z);

    // send the message
    oscP5.send(msg, oscDestinationAddress);
}

private void sendOSC(Boolean hasChanged)
{
    // create the OSC message with target address
    OscMessage msg = new OscMessage("/hasMoved");
    Integer rep = (hasChanged)? 1 : 0;
    msg.add(rep);
    // send the message
    oscP5.send(msg, oscDestinationAddress);
}

// --------------------------------------------------------------------------------
//  SYPHON SUPPORT
// --------------------------------------------------------------------------------

import codeanticode.syphon.*;    // import syphon library

SyphonServer     server;     

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

//Keep coordinates
ArrayList<ArrayList<PVector>> listeCoords = new ArrayList<ArrayList<PVector>>();

// --------------------------------------------------------------------------------
//  MAIN PROGRAM
// --------------------------------------------------------------------------------
void setup()
{
    size(640, 480, P3D);
    canvas = createGraphics(640, 480, P3D);

    println("Setup Canvas");

    // canvas.background(200, 0, 0);
    canvas.stroke(0, 0, 255);
    canvas.strokeWeight(3);
    canvas.smooth();
    println("-- Canvas Setup Complete");

    // setup Syphon server
    println("Setup Syphon");
    setupSyphonServer("Depth");

    // setup Kinect tracking
    println("Setup OpenNI");
    setupOpenNI();
    setupOpenNI_CameraImageMode();

    // setup OSC
    println("Setup OSC");
    setupOSC();

    // setup the exit handler
    println("Setup Exit Handerl");
    prepareExitHandler();
    
}

void draw()
{
    // update the cam
    context.update();

    canvas.beginDraw();

   // draw the skeleton if it's available
   

        int[] userList = context.getUsers();
        for (int i=0; i<userList.length; i++)
        {
            if (context.isTrackingSkeleton(userList[i]))
            {
                //canvas.stroke(userClr[ (userList[i] - 1) % userClr.length ] );

                //drawSkeleton(userList[i]);

                if (userList.length == 1) {
                  Boolean hasChanged = storeCoordinates(userList[i]);
                  sendOSC(hasChanged);
                  //sendOSCSkeleton(userList[i]);
                }
            }      

        }
    

    canvas.endDraw();

    image(canvas, 0, 0);

    // send image to syphon
    //server.sendImage(canvas);
}

Boolean storeCoordinates(int userId) {
  Boolean trigger = false;
  ArrayList<PVector> coords = new ArrayList<PVector>();
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_HEAD));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_NECK));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_LEFT_ELBOW));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_LEFT_HAND));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_RIGHT_HAND));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_TORSO));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_LEFT_HIP));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_LEFT_KNEE));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_LEFT_FOOT));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_RIGHT_HIP));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_RIGHT_KNEE));
  coords.add(getCoords(userId, SimpleOpenNI.SKEL_RIGHT_FOOT));
  listeCoords.add(coords);
  if (listeCoords.size()>3) {
    // let's compare movements
    ArrayList<PVector> coords_0 = listeCoords.get(0);
    for (int i=0; i<coords_0.size(); i++) {
      float d = coords_0.get(i).dist(coords.get(i));
      if (d>100) {
        trigger = true;
        i = 50;
      }  
    }
    //remove first element of arraylist
    listeCoords.remove(0);
  }
  return trigger;
}


// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
    canvas.stroke(255, 255, 255, 255);
    canvas.strokeWeight(3);

    drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

    drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

    drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

    drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
    drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

    drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
    drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);
}
PVector getCoords(int userId, int jointType) {
    float  confidence;
    PVector a_3d = new PVector();
    confidence = context.getJointPositionSkeleton(userId, jointType, a_3d);
    return a_3d;
}
void drawLimb(int userId, int jointType1, int jointType2)
{
    float  confidence;

    // draw the joint position
    PVector a_3d = new PVector();
    confidence = context.getJointPositionSkeleton(userId, jointType1, a_3d);
    PVector b_3d = new PVector();
    confidence = context.getJointPositionSkeleton(userId, jointType2, b_3d);

    PVector a_2d = new PVector();
    context.convertRealWorldToProjective(a_3d, a_2d);
    PVector b_2d = new PVector();
    context.convertRealWorldToProjective(b_3d, b_2d);

    canvas.line(a_2d.x, a_2d.y, b_2d.x, b_2d.y);
}

// -----------------------------------------------------------------
// SimpleOpenNI events

void onNewUser(SimpleOpenNI curContext, int userId)
{
    println("onNewUser - userId: " + userId);
    println("\tstart tracking skeleton");

    curContext.startTrackingSkeleton(userId);
}

void onLostUser(SimpleOpenNI curContext, int userId)
{
    println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext, int userId)
{
    //println("onVisibleUser - userId: " + userId);
}


void keyPressed()
{
    switch(key)
    {
    case ' ':
        context.setMirror(!context.mirror());
        println("Switch Mirroring");
        break;
    }
}  
