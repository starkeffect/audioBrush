import wblut.math.*;
import wblut.processing.*;
import wblut.core.*;
import wblut.hemesh.*;
import wblut.geom.*;

// HEMESH CLASSES & OBJECTS
HE_Mesh mesh; // Our mesh object
WB_Render render; // Our render object

// CAM
import peasy.*;
PeasyCam CAM;

// SAVE FLAG
boolean save;

void setup() 
{
  size(800, 800, P3D);
  CAM = new PeasyCam(this, 50);  
  CAM.setMinimumDistance(1);
  CAM.setMaximumDistance(100);
  
  // Importing the obj output from the "voxelBrush" audio vis script
  HEC_FromOBJFile objmesh = new HEC_FromOBJFile(sketchPath("data/untitled.obj"));
  mesh = new HE_Mesh(objmesh);

  // Defining modifiers
   
  // Extrusion
  HEM_Extrude extrude = new HEM_Extrude().setDistance(100);
  extrude.setRelative(false);
  //extrude.setChamfer(2);
  //MESH.modify( extrude ); // ADD OUR MODIFIER TO THE MESH
  //MESH.subdivide(catmullClark);
  //MESH.subdivide(catmullClark);
  //MESH.subdivide(catmullClark);
  //MESH.modify( extrude );
  
  //Inflate
  //HEM_Inflate inflate = new HEM_Inflate().setFactor(25);
  //mesh.modify(inflate);
  
  // Twist
  HEM_Twist twist = new HEM_Twist();
  WB_Line K = new WB_Line(-3, 0, 2, 0, 4, -1);
  twist.setTwistAxis(K);
  twist.setAngleFactor(1.2);
  //twist.apply(MESH);
  
  HEM_Skew skew = new HEM_Skew();
  WB_Plane P = new WB_Plane(1, 0, 0, 1, 2, 1);
  skew.setGroundPlane(P);
  //WB_Line L = new WB_Line(5, 0, 1, 1, 0, -1);
  //bend.setBendAxis(L);
  skew.setSkewDirection(0.5, 4, 1);
  //skew.setAngleFactor(0.8);
  skew.setSkewFactor(0.4);
  //bend.setPosOnly(false);
  //MESH.modify(bend);
  //MESH.modify(skew);
  
  // Catmull Clark (CC) Subdivision
  HES_CatmullClark catmullClark = new HES_CatmullClark();
  //mesh.subdivide(catmullClark, 2);
  
  render = new WB_Render(this); // RENDER object initialise
}

void draw() 
{
  background(255);
  CAM.beginHUD(); // this method disables PeasyCam for the commands between beginHUD & endHUD
  directionalLight(255, 255, 255, 1, 1, -1);
  directionalLight(127, 127, 127, -1, -1, 1);
  CAM.endHUD();

  // HEMESH
  // We draw our faces using the RENDER object
  //noFill();
  //render.drawFaces(mesh); // Draw MESH faces

  stroke(0, 0, 0);
  render.drawEdges(mesh); // Draw MESH edges
  
  if(save)
  {
    //Simple stereolithography file format, accepted by many 3D programs and 3D printers
    HET_Export.saveToSTL(mesh, sketchPath("meshes/"), str(System.currentTimeMillis()/1000) + ".stl");
  
    //Basic Wavefront OBJ file format, accepted by many 3D programs and 3D printers
    HET_Export.saveToOBJ(mesh, sketchPath("meshes/"), str(System.currentTimeMillis()/1000) + ".obj"); 
    
    save = false;
  }
}

void keyPressed()
{
  if(key == 's') save = true;
}