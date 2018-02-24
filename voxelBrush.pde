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
float seedX, seedY, seedZ;

// initial position
Vec3D pos0, pos;

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
  scale = new Vec3D(0.5, 0.5, 0.5).scaleSelf(50);
  
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
  seedX = random(100);
  seedY = random(100);
  seedZ = random(100);
  
  // initial position
  pos0 = new Vec3D(nx/2, ny/2, nz/2);
  
}

void draw() 
{
  background(0);
  setLights();
  
  //brush.setSize(1);
  brush.setSize(noise(seedX, seedY, seedZ) + 0.2);
  //brush.drawAtGridPos(map(mouseX, 0, width, 0, nx), map(mouseY, 0, height, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
  pos = new Vec3D(pos0.x + map(noise(seedX), 0, 1, 0, 1), pos0.y + map(noise(seedY), 0, 1, 0, 0.5), pos0.z + map(noise(seedZ), 0, 1, 0, 0.5));
  //brush.drawAtGridPos(pos.x, pos.y, pos.z, density);
  brush.drawAtGridPos(map(noise(seedX), 0, 1, 0, nx), map(noise(seedY), 0, 1, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
  pos0 = pos;
  
  volume.closeSides();
  
  surface.reset();
  surface.computeSurfaceMesh(mesh, iso_threshold);
  //mesh.toWEMesh().subdivide();
  
  setPerspective();
  gfx.mesh(mesh);
  
  if(save)
  {
    mesh.saveAsSTL(sketchPath("mesh" + (System.currentTimeMillis()/1000)+ ".stl"));
    mesh.saveAsOBJ(sketchPath("mesh" + (System.currentTimeMillis()/1000)+ ".obj"));
    save = false; 
  }
  
  seedX += 0.01;
  seedY += 0.01;
  seedZ += 0.03;
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