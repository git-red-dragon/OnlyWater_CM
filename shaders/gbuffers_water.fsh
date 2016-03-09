#version 120
/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

/* DRAWBUFFERS:024 */


//---------ADJUSTABLE-VARIABLES-------------------

	float RED = 0.0; //Redamount (0 - 255)
	float GREEN = 100.0; //Greenamount (0 - 255)
	float BLUE = 200.0; //Blueamount (0 - 255)
	float OPACITY = 65.0;//65.0; //Opacity (0 - 100)

	//#define MIX_TEX	0.7
	vec4 watercolor = vec4(RED/1000, GREEN/1000, BLUE/1000, OPACITY/100);

//---------END-OF-ADJUSTABLE-VARIABLES------------

const int MAX_OCCLUSION_POINTS = 0;
const float MAX_OCCLUSION_DISTANCE = 0.0;
const float bump_distance = 0.0;				//Bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 0.0;				//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;
const float PI = 3.1415927;

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 wpos;
varying float iswater;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform int worldTime;
uniform float far;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

vec2 dx = dFdx(texcoord.xy);
vec2 dy = dFdy(texcoord.xy);

float wave(float n) {
return sin(2 * PI * (n));
}

float waterH(vec3 posxz) {

	float wave = 0.0;
	float factor = 2.0;
	float amplitude = 0.2;
	float speed = 4.0;
	float size = 0.2;

	float px = posxz.x/50.0 + 250.0;
	float py = posxz.z/50.0  + 250.0;

	//zerlegung in kleine Fractale
	float fpx = abs(fract(px*20.0)-0.5)*2.0;
	float fpy = abs(fract(py*20.0)-0.5)*2.0;

	//längenbestimmung von fpx und fpy
	float d = length(vec2(fpx,fpy));
	
	float S = (1/factor)*px*py*size + 1.0*frameTimeCounter*speed;
	for (int i = 1; i < 4; i++) {
	
	
		wave -= d*factor*cos(S);
		factor /= 2;
	}

	factor = 1.0;
	px = -posxz.x/50.0 + 250.0;
	py = -posxz.z/150.0 - 250.0;

	//abs für nur positive Werte
	fpx = abs(fract(px*20.0)-0.5)*2.0;
	fpy = abs(fract(py*20.0)-0.5)*2.0;

	d = length(vec2(fpx,fpy));
	float wave2 = 0.0;
	for (int i = 1; i < 4; i++) {

		wave2 -= d*factor*cos(S);
		factor /= 2;
	}

	return amplitude*wave2+amplitude*wave;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {	
	
	vec4 tex = vec4((watercolor*length(texture2D(texture, texcoord.xy).rgb*color.rgb)*color).rgb,watercolor.a);
	//iswater <0.1 kein Wasser dann wird das die normale farbe genommen
	if (iswater < 0.1)  tex = texture2D(texture, texcoord.xy)*color;
	
	vec3 posxz = wpos.xyz; //Weltposition 

	posxz.x += sin(posxz.z+frameTimeCounter)*0.25;
	posxz.z += cos(posxz.x+frameTimeCounter*0.5)*0.25;
	
	float deltaPos = 0.4;
	float h0 = waterH(posxz);
	float h1 = waterH(posxz + vec3(deltaPos,0.0,0.0));
	float h2 = waterH(posxz + vec3(-deltaPos,0.0,0.0));
	float h3 = waterH(posxz + vec3(0.0,0.0,deltaPos));
	float h4 = waterH(posxz + vec3(0.0,0.0,-deltaPos));
	
	float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
	float yDelta = ((h3-h0)+(h0-h4))/deltaPos;
	
	vec3 newnormal = normalize(vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta));
	
	vec4 frag2;
		frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);		
		
		
		//Bump filter
	//iswater>0.9 für die Überprüfung ob das element wasser ist  
	if (iswater > 0.9) {
		vec3 bump = newnormal;
			bump = bump;
			
		
		float bumpmult = 0.05;	
		//shading Wasser
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		//binormal sind die Binormalen des Wassers aus dem Water Vragmentshalder
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);
		
		frag2 = vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0);
	}
	gl_FragData[0] = tex;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}