#version 120

//------------------------------------
//ONLY WATER SHADER byMrY
//http://youtube.com/hdjellybeanlp
//
//You can use my code for what ever you want,
//but don't forget to give credits! :)
//------------------------------------

//Add or remove the two "//" in front of "#define" to enable or disable the effect!

//#define DEPTH_OF_FIELD
	#define BLUR_AMOUNT 1.1 //I preffere something between 1.0 and 2.0

uniform int isEyeInWater;

uniform sampler2D depthtex0;
uniform sampler2D gnormal;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D composite;
uniform float aspectRatio;
uniform float near;
uniform float far;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

varying vec4 texcoord;

const float stp = 1.2;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 2.2;			//increasement factor at each step
const int maxf = 4;				//number of refinements

#ifdef DEPTH_OF_FIELD
	const float HYPERFOCAL = 3.132;
	const float PICONSTANT = 3.14159;
	vec4 getBlurredColor();
	vec4 getSample(vec2 coord, vec2 aspectCorrection);
	vec4 getSampleWithBoundsCheck(vec2 offset);
	float samples = 0.0;
	vec2 space;
#endif

float getDepth(vec2 coord) {
    return 2.0 * near * far / (far + near - (2.0 * texture2D(depthtex0, coord).x - 1.0) * (far - near));
}

vec3 nvec3(vec4 pos){
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos){
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}


vec4 raytrace(vec3 fragpos, vec3 normal){
    vec4 color = vec4(0.0);
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
    int sr = 0;
    for(int i = 0; i < 40; i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex0, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
		float err = abs(fragpos.z-spos.z);
		if(err < pow(length(vector)*1.85,1.15) && texture2D(gaux2,pos.st).g < 0.01){
                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 1.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					float land = texture2D(gaux1, pos.st).g;
					land = float(land < 0.03);
					spos.z = mix(fragpos.z,2000.0*(0.4+1.0*0.6),land);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
                fragpos = oldpos;
                vector *=ref;
        }
        vector *= inc;
        oldpos = fragpos;
        fragpos += vector;
    }
    return color;
}


//------------MAIN----------------

void main() {

	vec4 color = texture2D(composite, texcoord.st);

	float spec = texture2D(gaux2,texcoord.xy).r;
	float wave = texture2D(gaux2,texcoord.xy).g;
	
	float iswater = 0.0;
	if (wave > 0.0) {
		iswater = 1.0;
		wave = (wave-0.02)*2.0-1.0;
	}

    vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
    fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
    vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
	color.rgb *= mix(vec3(1.0),vec3(1.0,1.0,1.0),isEyeInWater);
    
	if (iswater > 0.9 && isEyeInWater == 0|| isEyeInWater == 1) {
		vec4 reflection = raytrace(fragpos, normalize(normal+wave*0.02));
		float normalDotEye = dot(normalize(normal+wave*0.15), -normalize(fragpos));
		float fresnel = 1.0 - normalDotEye;

		color.rgb = mix(color.rgb, reflection.rgb, fresnel*reflection.a * (vec3(1.0) - color.rgb) * (1.0-isEyeInWater));
    }
	
	#ifdef DEPTH_OF_FIELD
		float depth = getDepth(texcoord.st);
		float cursorDepth = getDepth(vec2(0.5, 0.5));
		float mixAmount = 0.0;
	
		if (depth < cursorDepth) {
			mixAmount = clamp(2.0 * ((clamp(cursorDepth, 0.0, HYPERFOCAL) - depth) / (clamp(cursorDepth, 0.0, HYPERFOCAL))), 0.0, 1.0);
		} else if (cursorDepth == HYPERFOCAL) {
			mixAmount = 0.0;
		} else {
			mixAmount =  1.0 - clamp((((cursorDepth * HYPERFOCAL) / (HYPERFOCAL - cursorDepth)) - (depth - cursorDepth)) / ((cursorDepth * HYPERFOCAL) / (HYPERFOCAL - cursorDepth)), 0.0, 1.0);
		}
    
		if (mixAmount != 0.0) {
			color.rgb = mix(color.rgb, getBlurredColor().rgb, mixAmount);
			
			
			/*
			if (iswater > 0.9) {
				vec4 reflection = raytrace(fragpos, normalize(normal+wave*0.02));
				float normalDotEye = dot(normalize(normal+wave*0.15), -normalize(fragpos));
				float fresnel = 1.0 - normalDotEye;

				color.rgb = (mix(color.rgb, reflection.rgb, fresnel*reflection.a * (vec3(1.0) - color.rgb) * (1.0-isEyeInWater)) + mix(color.rgb, getBlurredColor().rgb, mixAmount))/2;
				//color.rgb = mix(color.rgb, reflection.rgb, fresnel*reflection.a * (vec3(1.0) - color.rgb) * (1.0-isEyeInWater));
			}*/
		}
	#endif
	
	gl_FragColor = vec4(color.rgb, 0.0);
}

#ifdef DEPTH_OF_FIELD
vec4 getBlurredColor() {
	vec4 blurredColor = vec4(0.0);
	float depth = getDepth(texcoord.st);
	vec2 aspectCorrection = vec2(1.0, aspectRatio) * 0.005;

	vec2 ac0_4 = BLUR_AMOUNT * 0.4 * aspectCorrection;	// 0.4
	vec2 ac0_4x0_4 = 0.4 * ac0_4;			// 0.16
	vec2 ac0_4x0_7 = 0.7 * ac0_4;			// 0.28
	
	vec2 ac0_29 = BLUR_AMOUNT * 0.29 * aspectCorrection;	// 0.29
	vec2 ac0_29x0_7 = 0.7 * ac0_29;			// 0.203
	vec2 ac0_29x0_4 = 0.4 * ac0_29;			// 0.116
	
	vec2 ac0_15 = BLUR_AMOUNT * 0.15 * aspectCorrection;	// 0.15
	vec2 ac0_37 = BLUR_AMOUNT * 0.37 * aspectCorrection;	// 0.37
	vec2 ac0_15x0_9 = 0.9 * ac0_15;			// 0.135
	vec2 ac0_37x0_9 = 0.37 * ac0_37;		// 0.1369
	
	vec2 lowSpace = texcoord.st;
	vec2 highSpace = 1.0 - lowSpace;
	space = vec2(min(lowSpace.s, highSpace.s), min(lowSpace.t, highSpace.t));
		
	if (space.s >= ac0_4.s && space.t >= ac0_4.t) {
		
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, ac0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_4.s, 0.0));   
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, -ac0_4.t)); 
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_4.s, 0.0));
		
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_4x0_7.s, 0.0));       
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, -ac0_4x0_7.t));     
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_4x0_7.s, 0.0));     
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, ac0_4x0_7.t));
	
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_4x0_4.s, 0.0));
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, -ac0_4x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_4x0_4.s, 0.0));
		blurredColor += texture2D(composite, texcoord.st + vec2(0.0, ac0_4x0_4.t));

		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29.s, -ac0_29.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29.s, ac0_29.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29.s, ac0_29.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29.s, -ac0_29.t));
	
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_7.s, -ac0_29x0_7.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_7.s, -ac0_29x0_7.t));
		
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_29x0_4.s, -ac0_29x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_29x0_4.s, -ac0_29x0_4.t));
		
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15.s, ac0_37.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37.s, ac0_15.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37.s, -ac0_15.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15.s, -ac0_37.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15.s, ac0_37.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37.s, ac0_15.t)); 
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37.s, -ac0_15.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15.s, -ac0_37.t));

		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15x0_9.s, -ac0_37x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(-ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += texture2D(composite, texcoord.st + vec2(ac0_15x0_9.s, -ac0_37x0_9.t));
		
	    blurredColor /= 41.0;
	    
	} else {
		
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_4.s, 0.0));   
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4.t)); 
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4.s, 0.0)); 
		
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_4x0_7.s, 0.0));       
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4x0_7.t));     
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4x0_7.s, 0.0));     
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4x0_7.t));
	
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_4x0_4.s, 0.0));
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, -ac0_4x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_4x0_4.s, 0.0));
		blurredColor += getSampleWithBoundsCheck(vec2(0.0, ac0_4x0_4.t));

		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29.s, -ac0_29.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29.s, ac0_29.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29.s, ac0_29.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29.s, -ac0_29.t));
	
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_7.s, -ac0_29x0_7.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_7.s, ac0_29x0_7.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_7.s, -ac0_29x0_7.t));
		
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_29x0_4.s, -ac0_29x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_4.s, ac0_29x0_4.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_29x0_4.s, -ac0_29x0_4.t));
				
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15.s, ac0_37.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37.s, ac0_15.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37.s, -ac0_15.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15.s, -ac0_37.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15.s, ac0_37.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37.s, ac0_15.t)); 
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37.s, -ac0_15.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15.s, -ac0_37.t));
		
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15x0_9.s, -ac0_37x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_15x0_9.s, ac0_37x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_37x0_9.s, ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(-ac0_37x0_9.s, -ac0_15x0_9.t));
		blurredColor += getSampleWithBoundsCheck(vec2(ac0_15x0_9.s, -ac0_37x0_9.t));
	
	    blurredColor /= samples;
	    
	}

    return blurredColor;
}

vec4 getSampleWithBoundsCheck(vec2 offset) {
	vec2 coord = texcoord.st + offset;
	if (coord.s <= 1.0 && coord.s >= 0.0 && coord.t <= 1.0 && coord.t >= 0.0) {
		samples += 1.0;
		return texture2D(composite, coord);
	} else {
		return vec4(0.0);
	}
}
#endif