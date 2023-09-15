#version 300 es
precision highp float;

uniform float time;

/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Constants
//	==================
const int MAX_MARCHING_STEPS		= 150;
const float SURFACE_THRESHOLD		= 0.001;
const float MAX_MARCHING_DISTANCE	= 15.0;
const float PI 						= 3.14159265359;
const float AMBIENT					= 0.75;
const vec3	lPos1					= vec3(-0.12, 0.4, 0.28);

const mat3 m3 = mat3(		0.00	,  0.80	,  0.60	,
							-0.80	,  0.36	, -0.48	,
							-0.60	, -0.48	,  0.64 );

const mat3 m3i	= mat3(		0.00	, -0.80	, -0.60	,
							0.80	,  0.36	, -0.48	,
							0.60	, -0.48	,  0.64 );

const mat2 m2	= mat2(		0.80	,  0.60	,
                    		-0.60	,  0.80 );

const mat2 m2i	= mat2(		0.80	, -0.60	,
							0.60	,  0.80 );

/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Structs
//	==================
struct Ray 
{
    vec3 dir;
    vec3 org;
};

/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Functions
//	==================
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) 
{
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);

	return mat4(	vec4(s, 0.0),
					vec4(u, 0.0),
					vec4(-f, 0.0),
					vec4(0.0, 0.0, 0.0, 1.0));
}

vec4 blend(float a, float b, vec3 colA, vec3 colB, float k) 
{
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	float blendDst = mix(b, a, h) - k * h * (1.0 - h);
	vec3 blendCol = mix(colB, colA, h);

	return vec4(blendCol, blendDst);
}

/////////////////////////////////////////////////////////////////////////////////////

float sdMeta(vec3 v, float r, float f) 
{
	vec3 	p 	= v;
	float 	rad = r + 0.1 * sin(p.x * f + time * -2.0) 	* 
							cos(p.y * f + time * 1.0) 	* 	
							cos(p.z * f + time * 2.0);
	return length(p) - rad;
}

float sdSphere(vec3 p, float r) 
{
    return length(p) - r;
}

float sdCylinder(vec3 p, float r, float h) 
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0)));
}

float sdSphereRandom(vec3 i, vec3 f, vec3 c) 
{
    vec3 	p	= 17.0 * fract((i + c) * 0.3183099 + vec3(0.11, 0.17, 0.13));
    float 	w 	= fract(p.x * p.y * p.z * (p.x + p.y + p.z));
    float 	r 	= 0.7 * w * w;
    return length(f - c) - r;
}

float sdBox(vec3 p, vec3 b) 
{
    vec3 q = abs(p) - b;
    return length(vec3(max(q.x, 0.0), max(q.y, 0.0), max(q.z, 0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdPlane(vec3 p, vec3 n, float h) 
{
    return dot(p, n) + h;
}

float sdOctahedron(vec3 v, float s) 
{
    vec3 p = abs(v);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

float sdDunes(vec3 p, vec3 n, float h) 
{
    float disp = 0.3 * sin(2.0 * p.z) * sin(p.x) * 0.5;
    float plane = dot(p, n) + h;
    return (plane + disp);
}

float sdBase(vec3 p) 
{
	vec3 i = floor(p);
	vec3 f = fract(p);
	
	return min(min(	min(	sdSphereRandom(i, f, vec3(0.0, 0.0, 0.0)),
							sdSphereRandom(i, f, vec3(0.0, 0.0, 1.0))),
					min(	sdSphereRandom(i, f, vec3(0.0, 1.0, 0.0)),
							sdSphereRandom(i, f, vec3(0.0, 1.0, 1.0)))),
				min(min(	sdSphereRandom(i, f, vec3(1.0, 0.0, 0.0)),
							sdSphereRandom(i, f, vec3(1.0, 0.0, 1.0))),
					min(	sdSphereRandom(i, f, vec3(1.0, 1.0, 0.0)),
							sdSphereRandom(i, f, vec3(1.0, 1.0, 1.0)))));
}

/////////////////////////////////////////////////////////////////////////////////////

float unite(		float a, float b) { return min( a, b); }
float subtract(		float a, float b) { return max(-a, b); }
float intersect(	float a, float b) { return max( a, b); }

float smin(float a, float b, float k) 
{
    float h = max(k - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / k;
}

float smax(float a, float b, float k) 
{
    float h = max(k - abs(a - b), 0.0);
    return max(a, b) + h * h * 0.25 / k;
}

float hash1d(float n) { return fract(n * 17.0 * fract(n * 0.3183099)); }

float hash2d(vec2 p) 
{
    vec2 x = 50.0 * fract(p * 0.3183099);
    return fract(x.x * x.y * (x.x + x.y));
}

vec2 hash2dB(vec2 p) 
{
    vec2 n = vec2(dot(p, vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(n) * 43758.5453123);
}

float hash3d(vec3 p) 
{
    vec3 	x = 50.0 * fract(p * vec3(0.3183099, 0.3183099, 0.3183099));
    float 	y = x.x * x.y * x.z * (x.x + x.y + x.z);
    return fract(y);
}

float noise3d(vec3 x) 
{
	vec3	p	= floor(x);
	vec3	w 	= fract(x);
	vec3	u 	= w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
	float	n	= p.x + 317.0 * p.y + 157.0 * p.z;

	float 	a	= hash1d(n + 0.0);
	float 	b	= hash1d(n + 1.0);
	float 	c	= hash1d(n + 317.0);
	float 	d	= hash1d(n + 318.0);
	float 	e	= hash1d(n + 157.0);
	float 	f	= hash1d(n + 158.0);
	float 	g	= hash1d(n + 474.0);
	float 	h	= hash1d(n + 475.0);

	float 	k0	=   a;
	float 	k1	=   b - a;
	float 	k2	=   c - a;
	float 	k3	=   e - a;
	float 	k4	=   a - b - c + d;
	float 	k5	=   a - c - e + g;
	float 	k6	=   a - b - e + f;
	float 	k7	= - a + b + c - d + e - f - g + h;

	return -1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z);
}

float noise2d(vec2 x) 
{
	vec2 p	= floor(x);
	vec2 w	= fract(x);
	vec2 u	= w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

	float a	= hash2d(p + vec2(0,0));
	float b	= hash2d(p + vec2(1,0));
	float c	= hash2d(p + vec2(0,1));
	float d	= hash2d(p + vec2(1,1));

	return -1.0 + 2.0 * (a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y);
}

float fbm2d(vec2 p, int oct) 
{
	float 	f 	= 1.9;
	float 	s 	= 0.5;
	float 	a 	= 0.0;
	float 	b 	= 0.5;
	vec2	x 	= p;

    for(int i = 0; i < oct; ++i) 
	{
		float n = noise2d(x);
		a += b * n;
		b *= s;
		x = f * m2 * x;
    }

    return a;
}

float fbm3d(vec3 p, int oct) 
{
	float f = 2.0;
	float s = 0.5;
	float a = 0.0;
	float b = 0.5;
	vec3 x = p;

    for(int i = 0; i < oct; ++i) 
	{
		float n = noise3d(x);
		a += b * n;
		b *= s;
		x = f * m3 * x;
    }

	return a;
}

float sdFbm(vec3 v, float dist, int oct) 
{
	vec3	p = v;
	float 	s = 1.0;
	float 	d = dist;

    for(int i = 0; i < oct; i++) 
	{
		float n = s * sdBase(p);
		d 		= smax(d, -n, 0.2 * s);
		p 		= (m3 * 2.0) * p;
		s 		= 0.5 * s;
    }

    return d;
}

float sdFbmDunes(vec2 xy, int oct) 
{
	vec2	uv 		 = xy;
	float	value 	 = 0.0;
	float	factor 	 = -3.8;
	uv 				*= factor;

    for(int i = 0; i < oct; i++) 
	{
		uv 		+= max(sin(uv * factor) / factor, cos(uv / factor) * factor).yx;
		value 	 = -min(value + sin(uv.x) / factor, value + cos(uv.y / factor) / factor);
		uv 		 = uv / 1.5 / factor;
    }

	return value / 2.0 + 1.5;
}


//	===================
//		Cos Palette
//	===================
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

vec3 paletteSand(float t)
{
	return vec3(0.93855, 0.63795, 0.5573);
}

vec3 paletteRock(float t)
{
	return vec3(0.29, 0.25, 0.2);
}

vec3 paletteSky(float t)
{
	return vec3(0.53, 0.81, 0.98);
}

vec3 paletteHaze(float t)
{
	return vec3(0.77, 0.7, 0.62);
}

//	===================
//		Scenegraph
//	===================
vec4 scene(vec3 v, float distCurrent) 
{
	vec3 	p 			= v;
	float	globalDst 	= MAX_MARCHING_DISTANCE;
	vec3	globalColor = vec3(0.5);
	float	d 			= 0.0;

	float	bb 			= clamp(sdBox(p, vec3(4.0)), 0.0001, 8.0);
	if(bb > 8.0) { return vec4(globalColor, bb); }

	d = sdPlane(p, vec3(0.0, 1.0, 0.0), 0.4);
	d = smin(d, sdPlane(p, vec3(0.0, 1.0, 0.0), sdFbmDunes(p.xz, 1) - 1.5), 0.3);									// dunes
	d = smin(d, sdSphere(p * vec3(1.0, 2.5, 1.0) + vec3(0.0, 1.0, 0.0), 0.8), 0.3);									// island
	d = smin(d, sdFbm(p + vec3(0.0, -0.2, 0.0), sdBox(p + vec3(0.0, -0.2, 0.0), vec3(0.4) - 0.2) - 0.2, 6), 0.3); 	// rock
	d = smax(d, -sdSphere(p - lPos1, 0.001), 0.10);  																// cave

	globalColor = paletteSand(0.08);
	globalColor = mix(globalColor, vec3(0.29, 0.25, 0.2) + noise3d(p * 200.0) / 35.0, clamp(p.y * 4.0, 0.0 , 1.0));
	globalColor = mix(globalColor, paletteRock(0.08) + noise3d(p * 200.0) / 35.0, clamp(p.y * 4.0, 0.0 , 1.0));

	return vec4(globalColor, d);
}

//	===================
//		Raymarching
//	===================

vec3 opRepLim(vec3 p, float s, vec3 lim) 
{
	return p - s * clamp(round(p / s), -lim, lim);
}

vec3 opRep(vec3 p, float s) 
{
	return p - s * round(p / s);
}

vec4 rayMarch(Ray r) 
{
	float distCurrent = 0.0;
	vec4 result;

	for(int i = 0; i < MAX_MARCHING_STEPS; i++) 
	{
		vec3 current 	= r.org + r.dir * distCurrent;
		result			= scene(current, distCurrent);
		if(result.w < SURFACE_THRESHOLD) 		{ return vec4(result.xyz, distCurrent); }
		distCurrent 	+= result.w;
		if(distCurrent > MAX_MARCHING_DISTANCE) { return vec4(-1.0); }
    }

	return vec4(-1.0);
}


float softShadow(vec3 ro, vec3 rd, float mint, float k) 
{
	float res 		= 1.0;
	float t			= mint;
	for(int i = 0; i < 5; i++) 
	{
		vec3 p 		= ro + rd * t;
		float h 	= scene(p, 0.0).w;
		res 		= min(res, 0.5 * k * h / t);
		t 			+= clamp(h, 0.1, 1.0);
		if (h < 0.001) { break; }
	}
	return clamp(res, 0.0, 1.0);
}

float pointLight(vec3 pos, vec3 hit, vec3 normal, float att) 
{
	vec3	lightDir	= normalize(pos - hit);
	float	lightDist 	= length(pos - hit);
	float	attenuation = 1.0 / (1.0 + att * lightDist * lightDist);
	float	intensity	= max(dot(normal, lightDir), 0.0) * attenuation;
	return	intensity;
}

float pointLightSoftShadow(vec3 ro, vec3 lightPos, float k) 
{
	float	res		= 1.0;
	float	t		= 0.01;
	vec3	rd		= normalize(lightPos - ro);
	float	maxDist	= length(lightPos - ro);
    
    for(int i = 0; i < 5; i++) 
	{
		vec3 	p	= ro + rd * t;
		float	h	= scene(p, 0.0).w;
				res	= min(res, k * h / t);
		t += clamp(h, 0.1, 1.0);
        
		if (h < 0.001 || t > maxDist) { break; }
    }
    
	return clamp(res, 0.0, 1.0);
}

vec3 getNormal(vec3 p) 
{
	float 	dist	= scene(p, 0.0).w;
	vec2 	e		= vec2(SURFACE_THRESHOLD, 0.0);
	return normalize(dist - vec3(	scene(p - e.xyy, 0.0).w,
									scene(p - e.yxy, 0.0).w,
									scene(p - e.yyx, 0.0).w));
}


in vec2 v_uv;
out vec4 FragColor;
void main() 
{

	
	
	
	vec2 uv				= v_uv;
	vec3 origin			= vec3(0.0);
	vec3 up 			= vec3(0.0, 1.0, 0.0);
	vec3 camPos 		= vec3(0.5 * sin(time / 2.0), 0.4, 1.0 + sin(time / 1.0) / 8.0);
	mat4 viewMatrix		= viewMatrix(camPos, origin, up);
	vec3 camDir			= normalize((viewMatrix * vec4(uv, -1.0, 0.0)).xyz);
	Ray ray 			= Ray(camDir, camPos); 
	vec4 result 		= rayMarch(ray);
	float dist 			= result.w;
	vec3 HAZE 			= paletteHaze(0.0);
	vec3 SKY 			= paletteSky(0.0);
	vec3 SUN 			= vec3(4.0, 8.0, 8.0);


	if(dist == -1.0) 
	{
		FragColor = vec4(mix(HAZE, SKY, uv.y * 1.2 - 0.2), 1.0);

	} 
	else 
	{
		vec3 color = result.xyz;
		vec3 hit = ray.org + ray.dir * dist;
		vec3 normal = getNormal(hit); // Make sure you have a function called 'getNormal' defined in your GLSL
		float fog = clamp(0.0, 1.0, pow(dist / 10.0, 2.0));
		float shadow = clamp(0.0, 1.0, softShadow(hit, normalize(SUN - hit), 0.1, 4.0) + 0.25); // Make sure 'softShadow' is defined in your GLSL
		float pShadow = pointLightSoftShadow(hit, lPos1, 16.0); // Make sure 'pointLightSoftShadow' is defined in your GLSL

		color = mix(color, paletteSand(0.08), pow(dot(normal, vec3(0.0, 1.0, 0.0)), 5.0)); // Replace 'paletteSand' if not defined in GLSL
		color += pointLight(lPos1, hit, normal, 150.0 + 50.0 * abs(sin(time * 5.0))) * pShadow * vec3(1.0, 0.5, 0.0); // Make sure 'pointLight' is defined in your GLSL
		color = mix(color * 0.4 * paletteSand(0.09), color, shadow); // Replace 'paletteSand' if not defined in GLSL

		FragColor = vec4(mix(color * (clamp(dot(vec3(4.0, 8.0, 6.0), normal) / 15.0, 0.0, 1.0) + AMBIENT), HAZE, fog), 1.0);


	//	FragColor = vec4(AMBIENT, AMBIENT ,AMBIENT,1.0);
	}

}
