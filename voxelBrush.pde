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
int playCount;

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
float loopOffset;
Vec3D perlinOffset;

// initial position
Vec3D pos0, pos;

// arrays for storing audio analysis data
float[][] ftdata;
float[] audioLevels;
float maxLevel, maxft;

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
  
  playCount = 1; // the number of times the audio file loops
  ny *= playCount;
  
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
  pos0 = new Vec3D(0, 0, 0);
  pos = new Vec3D();
  
  // setting up minim for audio playback and analysis
  minim = new Minim(this);
  player = minim.loadFile("Back_Garden.wav", 1024); // 1024: buffer size
  player.play();
  player.loop(playCount - 1);
  
  // creating an FFT object for working with frequency domain representation of the audio file
  // the size of the spectrum is the same as the size of the audio buffer
  fftLog = new FFT(player.bufferSize(), player.sampleRate());
  
  // calculating averages based on minimum octave width of 22 Hz
  // split each octave into 3 bands
  //fftLog.logAverages(5, 6); // check how this works later !!!
  fftLog.linAverages(50);
  
  offlineAnalysis("Back_Garden.wav");
  
  // movement vectors
  perlinOffset = new Vec3D(0,0,0);

}

void draw() 
{ 
  background(0);
  setLights();
  //println(player.position());
  //translate(width/2, height/2, 0);
  //rotateX(frameCount * 0.003);
  //rotateZ(frameCount * 0.002);
  
  // performing a fft on the audio file loaded in player
  currentBuffer = player.mix;
  fftLog.forward(currentBuffer);
  
  //println((playCount - player.loopCount()) * ny/playCount);
  loopOffset = 0; //(playCount - player.loopCount()) * ny/playCount;
  println(player.loopCount());
  // perlin offsets
  float offX, offY, offZ;
  //offX = map(noise(seedX, seedY), 0, 1, -20, 20);
  offY = 0;
  offZ = 0; //map(noise(seedZ, seedY), 0, 1, 0, 10);
  offX = 0; //map(noise(seedX, seedY), 0, 1, -5, 5);
  
  //getting the level of the current buffer
  float[] samples = currentBuffer.toArray();
  float rms = 0;
  for(int i=0; i<samples.length; i++)
  {
      rms += sq(samples[i]);
  }
  rms = sqrt(rms);
  
  // iterating over the spectrum elements
  for(int i = 0; i < fftLog.avgSize(); i++)
  { 
    // mapping the position of the frequency band to the x position of the brush
    pos.x = map(i, 0, fftLog.avgSize(), 0, nx);
    
    // mapping the time stamp of the buffer to y position
    pos.y = map(player.position(), 0, player.length(), 0, ny/playCount);
    
    //pos.y = map(frameCount, 0, 1000, 0, ny);
    
    // mapping the level of the buffer to z position
    pos.z = map(fftLog.getBand(i), 0, maxft, 0, nz);
    //println(currentBuffer.level());
    
    // mapping the amplitude of the frequency band to brush size 
    
    float brushSize = map(rms, 0, maxLevel, 0.0, 0.8);
    //float brushSize = map(currentBuffer.level(), 0, maxLevel, 0.0, 2.5);
    //println(fftLog.getBand(i));
    brush.setSize(brushSize);
    //println(brushSize, pos.x, pos.y, pos.z);

    //perlinOffset.add(new Vec3D(5 * noise(seedX), 0, 5 * noise(seedZ)));
    //pos.add(loopOffset);
    //pos.add(perlinOffset);
    brush.drawAtGridPos(pos.x + offX, pos.y + loopOffset + offY, pos.z + offZ, density);
    connectPoints(new Vec3D(pos0.x, pos0.y, pos0.z), new Vec3D(pos.x + offX, pos.y + loopOffset + offY, pos.z + offZ), brushSize);
    pos0 = new Vec3D(pos.x + offX, pos.y + loopOffset + offY, pos.z + offZ);
    
    //brush.setSize(noise(seedX, seedY, seedZ) + 0.2);
    //brush.drawAtGridPos(map(mouseX, 0, width, 0, nx), map(mouseY, 0, height, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
    //pos = new Vec3D(pos0.x + map(noise(seedX), 0, 1, 0, 1), pos0.y + map(noise(seedY), 0, 1, 0, 0.5), pos0.z + map(noise(seedZ), 0, 1, 0, 0.5));
    //brush.drawAtGridPos(pos.x, pos.y, pos.z, density);
    //brush.drawAtGridPos(map(noise(seedX), 0, 1, 0, nx), map(noise(seedY), 0, 1, 0, ny), map(noise(seedZ), 0, 1, 0, nz), density);
    //pos0 = pos;
  }
  
  //if(player.isPlaying() == false)
  //{
    volume.closeSides();
    surface.reset();
    surface.computeSurfaceMesh(mesh, iso_threshold);
    //mesh.toWEMesh().subdivide();
    setPerspective();
    gfx.mesh(mesh);
  //}
  
  if(save)
  {
    //mesh.toWEMesh().subdivide();
    //mesh.toWEMesh().subdivide();
    mesh.saveAsSTL(sketchPath("meshes/mesh" + (System.currentTimeMillis()/1000)+ ".stl"));
    mesh.saveAsOBJ(sketchPath("meshes/mesh" + (System.currentTimeMillis()/1000)+ ".obj"));
    save = false; 
  }
  
  seedX += 0.05;
  seedY += 0.02;
  seedZ += 0.005;
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

void offlineAnalysis(String audioFilename)
{
  // loading the audio sample from file
  audio = minim.loadSample(audioFilename, 1024);
  
  // getting the left and right channels and computing the mix of the audio as float array
  float[] leftChannel = audio.getChannel(AudioSample.LEFT);
  float[] rightChannel = audio.getChannel(AudioSample.RIGHT);
  float[] mixChannel = new float[leftChannel.length]; // can also use right channel since the lengths are same
  for(int i=0; i<mixChannel.length; i++)
  {
    mixChannel[i] = (leftChannel[i] + rightChannel[i])/2.0;
  }
  
  // array for loading sample data as per fft size
  float[] fftSamples = new float[player.bufferSize()];
  
  // total number of discrete audio units that need to be analyzed
  int totalUnits = (mixChannel.length/fftSamples.length) + 1;
  
  // 2d array storing the Fourier transform data for all audio units
  ftdata = new float[totalUnits][fftLog.avgSize()];
  
  // array to store the levels for each audio unit
  audioLevels = new float[totalUnits];
  
  // analyzing the individual audio units
  int unitStartPos, unitSize;
  float level;
  for(int unit = 0; unit < totalUnits; unit++)
  {
    unitStartPos = unit * fftSamples.length;
    unitSize =  min(mixChannel.length - unitStartPos, fftSamples.length); // to account for the last unit which can be shorter than audio window
  
    // copying the unit into the analysis array
    System.arraycopy(mixChannel, // source of the copy
                     unitStartPos, // index to start in the source
                     fftSamples, // destination of the copy
                     0, // index to copy to
                     unitSize // how many samples to copy
                     );
     
    // if the audio unit was smaller than the size of the audio buffer, pad it with zeroes
    if(unitSize < fftSamples.length) 
    {
      java.util.Arrays.fill(fftSamples, unitSize, fftSamples.length - 1, 0.0);
    }
    
    // analyzing the audio unit
    // calculating the unit level as rms of samples
    level = 0;
    for(int i=0; i<unitSize; i++)
    {
      level += sq(fftSamples[i]);
    }
    audioLevels[unit] = sqrt(level);
    
    // fourier transform
    fftLog.forward(fftSamples);
    
    // copying the analysis results back into our ftdata array
    for(int i=0; i<fftLog.avgSize(); i++)
    {
      ftdata[unit][i] = fftLog.getBand(i);
    }
  }
  
  audio.close();
  
  // finding the maximum level
  maxLevel = max(audioLevels);
  
  // finding the maximum Fourier Transform value
  maxft = ftdata[0][0];
  for(int i=1; i<totalUnits; i++)
  {
     for(int j=0; j<fftLog.avgSize(); j++)
     {
       if(ftdata[i][j] > maxft) maxft = ftdata[i][j];
     }
  }
}

void connectPoints(Vec3D p0, Vec3D p1, float brushSize)
{
  float t = 0;
  Vec3D p = new Vec3D();
  float seed = random(100);
  
  while(t < 1)
  {
    brush.setSize(brushSize - map(t, 0, 1, 0, 0.6 * brushSize));
    p.x = ((1-t) * p0.x) + (t * p1.x) + map(noise(seed), 0, 1, -2, 2);
    p.y = ((1-t) * p0.y) + (t * p1.y) + map(noise(seed), 0, 1, -2, 2);
    p.z = ((1-t) * p0.z) + (t * p1.z);
    brush.drawAtGridPos(p.x, p.y, p.z, density);
    t += 0.05;
    seed += 0.5;
  }
}