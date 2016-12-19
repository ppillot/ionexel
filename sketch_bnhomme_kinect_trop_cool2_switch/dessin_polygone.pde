class DessinPolygone {
  
  int[] userMap;
  
  DessinPolygone() {
    
  }
  
  void dessine() {
    // fading background : fill with 65% opacity
    //noStroke();
    canvas.fill(0, 65);
    canvas.rect(0, 0, width, height);
    
    // put the image into a PImage
    resultImage = context.userImage();
    // copy the image into the smaller blob image
    blobs.copy(resultImage, 0, 0, resultImage.width, resultImage.height, 0, 0, blobs.width, blobs.height);
    // blur the blob image
    blobs.filter(THRESHOLD, 0.7);
    blobs.filter(BLUR);
    // detect the blobs
    theBlobDetection.computeBlobs(blobs.pixels);
    // clear the polygon (original functionality)
    poly.reset();
    // create the polygon from the blobs (custom functionality, see class)
    poly.createPolygon();
    //drawFlowfield();
    
    canvas.stroke(255);
    if (poly.npoints>1) {
      for (int i=1; i<poly.npoints; i++) {
        canvas.line(poly.xpoints[i-1], poly.ypoints[i-1], poly.xpoints[i], poly.ypoints[i]);
      }
    }
     
     
    //canvas.image(resultImage, 0, 0);
  }
  
  
 
}
