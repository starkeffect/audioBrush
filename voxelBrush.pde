import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.volume.*;
import toxi.processing.*;

import ddf.minim.*;
import ddf.minim.analysis.*;
FFT fftLog;

Minim minim;
AudioPlayer player;
AudioBuffer currentBuffer;
AudioSample audio;

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

// arrays for storing successive brush position
float[] x,y,z;
float[] brushSize;

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
  pos = new Vec3D();
  
  // setting up minim for audio playback and analysis
  minim = new Minim(this);
  player = minim.loadFile("Back_Garden.wav", 1024); // 1024: buffer size
  player.play();
  player.loop();
  
  // creating an FFT object for working with frequency domain representation of the audio file
  // the size of the spectrum is the same as the size of the audio buffer
  fftLog = new FFT(player.bufferSize(), player.sampleRate() );
  
  // calculating averages based on minimum octave width of 22 Hz
  // split each octave into 3 bands
  fftLog.logAverages(5, 3); // check how this works later !!!
  
  //offlineAnalysis("Back_Garden.wav");

}

void draw() 
{
  if(frameCount > 1000)
  {
    noLoop();
    player.pause();
  }
  
  
  background(0);
  setLights();
  println(player.position());
  
  // performing a fft on the audio file loaded in player
  currentBuffer = player.mix;
  fftLog.forward(currentBuffer);
  
  // sending the buffer for analysis
  
  // iterating over the spectrum elements
  for(int i = 0; i < fftLog.avgSize(); i++)
  {
    // getting general information for frequeny band at index i
    //float centerFrequency = fftLog.getAverageCenterFrequency(i);
    //float averageWidth = fftLog.getAverageBandWidth(i);
    
    // getting the min and the max
    
    // mapping the position of the frequency band to the x position of the brush
    pos.x = map(i, 0, fftLog.avgSize(), 0, nx);
    
    // mapping the time stamp of the buffer to y position
    //pos.y = map(player.position(), 0, player.length(), 0, ny);
    pos.y = map(frameCount, 0, 1000, 0, ny);
    
    // mapping the level of the buffer to z position
    pos.z = map(currentBuffer.level(), 0, 0.2, nz, 0);
    //println(currentBuffer.level());
    
    // mapping the amplitude of the frequency band to brush size 
    float brushSize = map(fftLog.getBand(i), 0, 15, 0.2, 1.5);
    //println(fftLog.getBand(i));
    brush.setSize(brushSize);
    
    
    // drawing at the mapped locations
    brush.drawAtGridPos(pos.x, pos.y, pos.z, density);
    
    
    
    //brush.setSize(noise(seedX, seedY, seedZ) + 0.2);
    //brush.drawAtGridPos(map(mouseX, 0, width, 0, nx), map(mouseY, 0, height, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
    //pos = new Vec3D(pos0.x + map(noise(seedX), 0, 1, 0, 1), pos0.y + map(noise(seedY), 0, 1, 0, 0.5), pos0.z + map(noise(seedZ), 0, 1, 0, 0.5));
    //brush.drawAtGridPos(pos.x, pos.y, pos.z, density);
    //brush.drawAtGridPos(map(noise(seedX), 0, 1, 0, nx), map(noise(seedY), 0, 1, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
    //pos0 = pos;
    
    volume.closeSides();
  }
  
  surface.reset();
  surface.computeSurfaceMesh(mesh, iso_threshold);
  //mesh.toWEMesh().subdivide();
  
  setPerspective();
  gfx.mesh(mesh);
  
  if(save)
  {
    mesh.toWEMesh().subdivide();
    mesh.toWEMesh().subdivide();
    mesh.saveAsSTL(sketchPath("mesh" + (System.currentTimeMillis()/1000)+ ".stl"));
    //mesh.saveAsOBJ(sketchPath("mesh" + (System.currentTimeMillis()/1000)+ ".obj"));
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

void bufferAnalysis(String audioFilename)
{
  // loading the audio sample from file
  audio = minim.loadSample(audioFilename, 1024);
  fftLog = new FFT(audio.bufferSize(), audio.sampleRate() );
  fftLog.logAverages(22, 3); 
  
  // calculating x positions for the brush
  x = new float[fftLog.avgSize()];
  for(int i=0; i<fftLog.avgSize(); i++)
  {
    x[i] = map(i, 0, fftLog.avgSize(), 0, nx);
  }
  
  // calculating y positions for the brush
  
  
}