#version 120

//------------------------------------
//ONLY WATER SHADER byMrY
//http://youtube.com/hdjellybeanlp
//
//You can use my code for what ever you want,
//but don't forget to give credits! :)
//------------------------------------

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

void main() {

	gl_Position = ftransform();
	
	color = gl_Color;
	
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;

	gl_FogFragCoord = gl_Position.z;
}