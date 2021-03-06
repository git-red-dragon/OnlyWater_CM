#version 120

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D gaux1;

varying vec4 texcoord;

uniform int worldTime;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 aux = texture2D(gaux1, texcoord.st).rgb;

float land = aux.b;
float iswater = 0.0;
float pixeldepth = texture2D(depthtex0,texcoord.xy).x;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;


float callwaves(vec2 pos) {
	float wsize = 2.9;
	float wspeed = 0.025f;

	//worldTime übergeben von ausen
	float rs0 = abs(sin((worldTime*wspeed/5.0) + (pos.s*wsize) * 20.0)+0.2);
	float rs1 = abs(sin((worldTime*wspeed/7.0) + (pos.t*wsize) * 27.0));
	float rs2 = abs(sin((worldTime*wspeed/2.0) + (pos.t*wsize) * 60.0 - sin(pos.s*wsize) * 13.0)+0.4);
	float rs3 = abs(sin((worldTime*wspeed/1.0) - (pos.s*wsize) * 20.0 + cos(pos.t*wsize) * 83.0)+0.1);

	float wsize2 = 1.7;
	float wspeed2 = 0.017f;

	float rs0a = abs(sin((worldTime*wspeed2/4.0) + (pos.s*wsize2) * 24.0));
	float rs1a = abs(sin((worldTime*wspeed2/11.0) + (pos.t*wsize2) * 77.0 )+0.3);
	float rs2a = abs(sin((worldTime*wspeed2/6.0) + (pos.s*wsize2) * 50.0 - (pos.t*wsize2) * 23.0)+0.12);
	float rs3a = abs(sin((worldTime*wspeed2/14.0) - (pos.t*wsize2) * 4.0 + (pos.s*wsize2) * 98.0));

	float wsize3 = 0.3;
	float wspeed3 = 0.03f;

	float rs0b = abs(sin((worldTime*wspeed3/4.0) + (pos.s*wsize3) * 14.0));
	float rs1b = abs(sin((worldTime*wspeed3/11.0) + (pos.t*wsize3) * 37.0));
	float rs2b = abs(sin((worldTime*wspeed3/6.0) + (pos.t*wsize3) * 47.0 - cos(pos.s*wsize3) * 33.0 + rs0a + rs0b));
	float rs3b = abs(sin((worldTime*wspeed3/14.0) - (pos.s*wsize3) * 13.0 + sin(pos.t*wsize3) * 98.0 + rs0 + rs1));

	float waves  = (rs1 * rs0 + rs2 * rs3)/2.0f;
	float waves2 = (rs0a * rs1a + rs2a * rs3a)/2.0f;
	float waves3 = (rs0b + rs1b + rs2b + rs3b)*0.25;


	return (waves + waves2 + waves3)/3.0f;
}

//----------------MAIN------------------

void main() {

	if(aux.g > 0.01 && aux.g < 0.07) {
		iswater = 1.0;
	}

	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;
	
	float dist = length(fragposition.xyz);
	vec4 worldposition = vec4(0.0);
	worldposition = gbufferModelViewInverse * fragposition;	
	vec3 color = texture2D(gcolor, texcoord.st).rgb;
	const float rspread = 0.30f;

	float wave = 0.0;
	if (iswater > 0.9) {
		wave = callwaves(worldposition.xz*0.02)*2.0-1.0;
	
		const float wnormalclamp = 0.05f;

		float rdepth = pixeldepth;

		float wnormal_x1 = texture2D(depthtex0, texcoord.st + vec2(pw, 0.0f)).x - texture2D(depthtex0, texcoord.st).x;
		float wnormal_x2 = texture2D(depthtex0, texcoord.st).x - texture2D(depthtex0, texcoord.st + vec2(-pw, 0.0f)).x;			
		float wnormal_x = 0.0f;
		
		if(abs(wnormal_x1) > abs(wnormal_x2)){
			wnormal_x = wnormal_x2;
		} else {
			wnormal_x = wnormal_x1;
		}
		
		wnormal_x /= 1.0f - rdepth;
		wnormal_x = clamp(wnormal_x, -wnormalclamp, wnormalclamp);
		wnormal_x *= rspread;
		
		float wnormal_y1 = texture2D(depthtex0, texcoord.st + vec2(0.0f, ph)).x - texture2D(depthtex0, texcoord.st).x;
		float wnormal_y2 = texture2D(depthtex0, texcoord.st).x - texture2D(depthtex0, texcoord.st + vec2(0.0f, -ph)).x;		
		float wnormal_y;
		
		if(abs(wnormal_y1) > abs(wnormal_y2)){
			wnormal_y = wnormal_y2;
		} else {
			wnormal_y = wnormal_y1;
		}	
		wnormal_y /= 1.0f - rdepth;			

		wnormal_y = clamp(wnormal_y, -wnormalclamp, wnormalclamp);
		
		wnormal_y *= rspread;
		
		//Calculate distance of objects behind water
		float refractdist = 0.2 * 10.0f;


		vec3 refracted = vec3(0.0f);
		float refractedmask = 0.0;

		color.rgb = mix(color.rgb, refracted.rgb, vec3(refractedmask));	
		
	}

	wave = wave*0.5+0.5;
	if (iswater > 0.9){
		wave += 0.02;
	}else{
		wave = 0.0;
	}

	/* DRAWBUFFERS:3 */

	color = clamp(color,0.0,1.0);
	gl_FragData[0] = vec4(color, 1.0);
	

/* DRAWBUFFERS:NNN3N5 */

    gl_FragData[5] = vec4(0.0, wave, 0.0, 0.0);
	gl_FragData[3] = vec4(color, land);
}
