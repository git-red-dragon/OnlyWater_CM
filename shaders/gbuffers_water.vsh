#version 120

//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

#define WAVING_WATER

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 wpos;
varying float iswater;

attribute vec4 mc_Entity;


uniform vec3 cameraPosition; // A vec3 indicating the position in world space of the entity to which the camera is attached.
uniform mat4 gbufferModelView; // The 4x4 modelview matrix after setting up the camera transformations. This uniform previously had a slightly different purpose in mind, so the name is a bit ambiguous.
uniform mat4 gbufferModelViewInverse; // The inverse of gbufferModelView.
uniform int worldTime; // An integer indicating the current world time. For the over-world this number ranges from 0 to 24000 and loops.
uniform float frameTimeCounter;
uniform int isEyeInWater;

const float PI = 3.1415927;//pi



float wavefunction(vec3 worldpos)
{
 float Amplitude = 1.8;
 
 float Wavelength = (frameTimeCounter*0.65 + worldpos.x /  10.0 + worldpos.z / 9.0);
 float Wavelength2 = (frameTimeCounter*0.55 + worldpos.x /  9.0 + worldpos.z / 8.0);
 float Wavelength3 = (frameTimeCounter*0.45 + worldpos.x /  8.0 + worldpos.z / 7.0);
 float Wavelength4 = (frameTimeCounter*0.35 + worldpos.x /  7.0 + worldpos.z / 6.0);

 float Speed = sin(2 * PI * Wavelength);
 float Speed1 = sin(2 * PI * Wavelength2);
 float Speed2 = sin(2 * PI * Wavelength3);
 float Speed3 = sin(2 * PI * Wavelength4);
 
float wave = Amplitude * Speed + Amplitude* Speed2+ Amplitude* Speed3;
return wave;
}

void main(){
	//positionierung das Objets im raum an die richtige stelle
	vec4 vertexEyeSpace = gl_ModelViewMatrix * gl_Vertex;//verschiebung in den View Eye
	float displacement = 0.0;
	
	// un-rotate */
	vec4 viewpos = gbufferModelViewInverse * vertexEyeSpace; //wieder zurpck setzen  ohne das schwebt das wasser

    //viewpos  ist position im viewspase
	vec3 worldpos = viewpos.xyz; 
	wpos = worldpos; //ÜBergabe der Worldpos an den fsh
	iswater = 1.0f;
	float fy = fract(worldpos.y + 0.1);
	float wave = wavefunction(worldpos);

	displacement = clamp(wave, -fy, 1.0-fy); //Clamp um nur die wellen zwischen fy und 1-fy zu zeigen die auch sichtbar sind
	viewpos.y += displacement*0.5;
	
	// re-rotate */
	viewpos = gbufferModelView * viewpos;

	// projectify */
	gl_Position = gl_ProjectionMatrix * viewpos; //gl_Position ist wichtiger bestantteil von GLSL
	
	color = gl_Color;
	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st; //wird bis ins final geschleift

	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
	

	//Surface Normals	
	tangent = vec3(0.0);//beliebige richtung
	binormal = vec3(0.0);// unter dem Vertexs 

	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));

	if (gl_Normal.x > 0.5) {
		//  1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.x < -0.5) {
		// -1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.y > 0.5) {
		//  0.0,  1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.y < -0.5) {
		//  0.0, -1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.z > 0.5) {
		//  0.0,  0.0,  1.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.z < -0.5) {
		//  0.0,  0.0, -1.0
		tangent  = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}	
	//Ende Normalisieren
}


