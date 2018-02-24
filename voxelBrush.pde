import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.volume.*;
import toxi.processing.*;

import peasy.*;
import peasy.org.apache.commons.math.*;
import peasy.org.apache.commons.math.geometry.*;

ToxiclibsSupport gfx;  // for rendering ToxicLibs objects in P3D
VolumetricSpace volume; // the global volumetric space
VolumetricBrush brush; // voxel brush
IsoSurface surface; // reads the values from the volumetric space and extracts the voxels below a certain threshold (ISO_THRESHOLD), converting them to a TriangleMesh
TriangleMesh mesh; // output: final mesh for rendering for export

// dimensions and scale of the global volumetric space 
int nx, ny, nz; 
Vec3D scale; //

PeasyCam cam;

float iso_threshold;
float density;

boolean save;
float seedZ;

void setup() 
{
  size(800, 800, P3D);

  noStroke();
  fill(255);

  cam = new PeasyCam(this, 50);
  cam.setMinimumDistance(1);
  cam.setMaximumDistance(100);
  
  // setting the dimensions and scale of the global volumetric space
  nx = 200;
  ny = 200;
  nz = 50;
  scale = new Vec3D(1, 1, 0.1).scaleSelf(50);
  
  // intializing the global volumetric space using the parameters above
  volume = new VolumetricSpaceArray(scale, nx, ny, nz);
  
  // initializing renderer
  gfx = new ToxiclibsSupport(this);
  
  // initializing the voxel brush
  brush = new RoundBrush(volume, 0.1);
  
  surface = new ArrayIsoSurface(volume);
  
  mesh = new TriangleMesh();
  
  iso_threshold = 0.5;
  density = 0.5;
  
  save = false;
  seedZ = random(20);
}

void draw() 
{
  background(0);
  setLights();
  
  brush.setSize(1);
  brush.drawAtGridPos(map(mouseX, 0, width, 0, nx), map(mouseY, 0, height, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
  
  volume.closeSides();
  
  surface.reset();
  surface.computeSurfaceMesh(mesh, iso_threshold);
  
  setPerspective();
  gfx.mesh(mesh);
  
  if(save)
  {
    mesh.saveAsSTL(sketchPath("mesh" + (System.currentTimeMillis()/1000)+ ".stl"));
    mesh.saveAsOBJ(sketchPath("mesh" + (System.currentTimeMillis()/1000)+ ".obj"));
    save = false; 
  }
  
  seedZ += 0.1;
}

void keyPressed()
{
  if(key == 's') save = true;
}

void setPerspective()
{
  // for avoiding view field clipping
  float fov = PI/3.0;
  float cameraZ = (height/2.0) / tan(fov/2.0);
  perspective(fov, float(width)/float(height), cameraZ/500.0, cameraZ*10.0);
}

void setLights()
{
  directionalLight(240, 240, 240, 0.25, 0.25, 1);
  directionalLight(240, 240, 240, 0, 0, -1);
  lightSpecular(240, 240, 240);
  shininess(1);
}