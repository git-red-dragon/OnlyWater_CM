#version 120

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


float wavefunction(vec3 worldpos)
{
 float Amplitude = 0.8;
 float Wavelength = (frameTimeCounter*0.75 + worldpos.x /  7.0 + worldpos.z / 13.0);
 float Wavelength2 = (frameTimeCounter*0.65 + worldpos.x /  6.0 + worldpos.z / 11.0);
 float Wavelength3 = (frameTimeCounter*0.55 + worldpos.x /  5.0 + worldpos.z / 9.0);
 float Wavelength4 = (frameTimeCounter*0.45 + worldpos.x /  4.0 + worldpos.z / 8.0);

 float Speed = sin(2 * PI * Wavelength);
 float Speed1 = sin(2 * PI * Wavelength2);
 float Speed2 = sin(2 * PI * Wavelength3);
 float Speed3 = sin(2 * PI * Wavelength4);
 
float wave = Amplitude * Speed + Amplitude* Speed2+ Amplitude* Speed3;
return wave;
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
	

	
	vec3 waterpos = wpos.xyz;//Weltposition 
	waterpos.x -= (waterpos.x-frameTimeCounter*0.15)*7.0;
	waterpos.z -= (waterpos.z-frameTimeCounter*0.15)*7.0;
		float deltaPos = 0.4;
	float h0 = wavefunction(waterpos);
	float h1 = wavefunction(waterpos + vec3(deltaPos,0.0,0.0));
	float h2 = wavefunction(waterpos + vec3(-deltaPos,0.0,0.0));
	float h3 = wavefunction(waterpos + vec3(0.0,0.0,deltaPos));
	float h4 = wavefunction(waterpos + vec3(0.0,0.0,-deltaPos));
	
	float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
	float yDelta = ((h3-h0)+(h0-h4))/deltaPos;
	
	vec3 newnormal = normalize(vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta));	
	vec4 frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);		
		
		
		//Bump filter
	//iswater>0.9 für die Überprüfung ob das element wasser ist  
	if (iswater > 0.9) {
		vec3 bump = newnormal;
			//bump = bump;
			
		float bumpmult = 0.05;	
		//shading Wasser
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		//binormal sind die Binormalen des Wassers aus dem Water Vragmentshalder
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);
		

		frag2 = vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0);
 
		//vec3 noise =vec3(noise(normal.xy),noise(normal.xy),noise(normal.xy));
		//frag2 = vec4(normalize(noise*tbnMatrix)* 0.5 + 0.5, 1.0);
		}

		
	gl_FragData[0] = tex;//(muss immer ein vec4 sein)//newnormal;//vec4(newnormal,1);
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}