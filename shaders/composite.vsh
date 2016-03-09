#version 120

//------------------------------------
//ONLY WATER SHADER byMrY
//http://youtube.com/hdjellybeanlp
//
//You can use my code for what ever you want,
//but don't forget to give credits! :)
//------------------------------------

varying vec4 texcoord;
varying float iswater;

void main() {
	gl_Position = ftransform();
	
	texcoord = gl_MultiTexCoord0;
}
