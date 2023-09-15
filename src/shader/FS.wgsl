//	==================
//		Uniforms
//	==================
@group(0) @binding(0) var<uniform> time: f32;
@group(0) @binding(1) var<uniform> resolution: vec2f;

/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Constants
//	==================
const m3					: mat3x3f  	= mat3x3f( 	 0.00,  0.80,  0.60	,
                      								-0.80,  0.36, -0.48	,
                      								-0.60, -0.48,  0.64 );
const m3i					: mat3x3f	= mat3x3f(	 0.00, -0.80, -0.60 ,
                       								 0.80,  0.36, -0.48	,
                       								 0.60, -0.48,  0.64 );
const m2					: mat2x2f	= mat2x2f(   0.80,  0.60 ,
                      								-0.60,  0.80 );
const m2i 					: mat2x2f	= mat2x2f(	 0.80, -0.60 ,
                       								 0.60,  0.80 );

/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Structs
//	==================
struct Ray 
{
	dir: vec3f,
	org: vec3f
};


/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Functions
//	==================
fn viewMatrix(eye: vec3f, center: vec3f, up: vec3f) -> mat4x4f
{
	let f: vec3f = normalize(center - eye);
	let s: vec3f = normalize(cross(f, up));
	let u: vec3f = cross(s, f);
	return mat4x4f(		vec4f( s, 0)
					,	vec4f( u, 0)
					,	vec4f(-f, 0)
					,	vec4f( 0, 0, 0, 1));
}

fn blend(a: f32, b: f32, colA: vec3f, colB: vec3f, k: f32) -> vec4f
{
	let h			: f32	= clamp( 0.5 + 0.5 * (b - a) / k, 0.0, 1.0 );
	let blendDst	: f32	= mix(b, a, h) - k * h * (1.0 - h);
	let blendCol	: vec3f	= mix(colB, colA, h);
	return vec4f(blendCol, blendDst);
}

/////////////////////////////////////////////////////////////////////////////////////

fn sdMeta( v: vec3f, r: f32, f: f32 ) -> f32
{
	var p: vec3f = v;
	let rad: f32 = r + 0.1 * sin(p.x * f + time * -2) * cos(p.y * f + time * 1) * cos(p.z * f + time * 2);
	return length(p) - rad;
}

fn sdSphere( p: vec3f, r: f32 ) -> f32
{
	return length(p) - r;
}

fn sdCylinder( p: vec3f, r: f32, h: f32) -> f32
{
	let d: vec2f = abs(vec2f(length(p.xz),p.y)) - vec2f(r,h);
  	return min(max(d.x,d.y),0.0) + length(max(d,vec2f(0.0)));
}

fn sdSphereRandom( i: vec3f, f: vec3f, c: vec3f ) -> f32
{
	let p: vec3f 	= 17.0*fract( (i + c) * 0.3183099 + vec3f(0.11,0.17,0.13) );
    let w: f32 		= fract( p.x * p.y * p.z * (p.x + p.y + p.z) );
    let r: f32 		= 0.7 * w * w;
    return length(f-c) - r; 
}

fn sdBox( p: vec3f, b: vec3f )-> f32
{
	let q: vec3f = abs(p) - b;
	return length(vec3f(max(q.x,0),max(q.y,0),max(q.z,0))) + min(max(q.x,max(q.y,q.z)),0);
}

fn sdPlane(p: vec3f, n: vec3f, h: f32) -> f32
{
	return dot(p,n) + h;
}

fn sdOctahedron(v: vec3f, s: f32) -> f32
{
	let p: vec3f = abs(v);
	return (p.x + p.y + p.z - s)*0.57735027;
}

fn sdDunes(p: vec3f, n: vec3f, h: f32) -> f32
{
	// var disp	: f32	= 0.3 * sin(0.4 * p.z) * sin(p.x + noise2dB(p.zx)) * 2.5;
	var disp	: f32	= 0.3 * sin(2 * p.z) * sin(p.x) * 0.5;
	var plane	: f32	= dot(p, n) + h;
	return (plane + disp);
}

fn sdBase(p: vec3f) -> f32
{
	let i: vec3f = floor(p);
	let f: vec3f = fract(p);

	return 	min(min(min(sdSphereRandom(i,f,vec3f(0,0,0)), 
						sdSphereRandom(i,f,vec3f(0,0,1))),
                  	min(sdSphereRandom(i,f,vec3f(0,1,0)),
                      	sdSphereRandom(i,f,vec3f(0,1,1)))),
            min(min(	sdSphereRandom(i,f,vec3f(1,0,0)),
                      	sdSphereRandom(i,f,vec3f(1,0,1))),
                  	min(sdSphereRandom(i,f,vec3f(1,1,0)),
                      	sdSphereRandom(i,f,vec3f(1,1,1)))));
}

/////////////////////////////////////////////////////////////////////////////////////

fn unite		(a: f32, b: f32) -> f32 { return min( a, b); }
fn subtract		(a: f32, b: f32) -> f32 { return max(-a, b); }
fn intersect	(a: f32, b: f32) -> f32 { return max( a, b); }

fn smin(a: f32, b: f32, k: f32) -> f32 
{
    let h = max(k - abs(a - b), 0.0);
    return min(a, b) - h * h * 0.25 / k;
}

fn smax(a: f32, b: f32, k: f32) -> f32 
{
    let h = max(k - abs(a - b), 0.0);
    return max(a, b) + h * h * 0.25 / k;
}

fn hash1d(n: f32) -> f32
{
    return fract( n*17.0*fract( n*0.3183099 ) );
}

fn hash2d(p: vec2f ) -> f32
{
	let x: vec2f  = 50.0 * fract( p * 0.3183099 );
	return fract( x.x*x.y*(x.x+x.y) );
}

fn hash2dB(p: vec2f) -> vec2f
{
	var n: vec2f = vec2f(	dot(p, vec2f(127.1,311.7)),
							dot(p, vec2f(269.5,183.3)));
	return -1.0 + 2.0 * fract(sin(p + 20) * 53758.5453123);
}

fn hash3d(p: vec3f) -> f32
{
    let x: vec3f 	= 50.0 * fract(p * vec3f(0.3183099, 0.3183099, 0.3183099));
    let y: f32 		= x.x * x.y * x.z * (x.x + x.y + x.z);
    return fract(y);
}

fn noise3d(x: vec3f) -> f32
{
	var p	: vec3f		= vec3f(floor(x));
	var w	: vec3f		= vec3f(fract(x));
	var u	: vec3f 	= w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
	var n	: f32		= p.x + 317.0*p.y + 157.0*p.z;

	let a	: f32 		= hash1d(n + 0.0);
    let b	: f32 		= hash1d(n + 1.0);
    let c	: f32 		= hash1d(n + 317.0);
    let d	: f32 		= hash1d(n + 318.0);
    let e	: f32 		= hash1d(n + 157.0);
	let f	: f32 		= hash1d(n + 158.0);
    let g	: f32 		= hash1d(n + 474.0);
    let h	: f32 		= hash1d(n + 475.0);

	let k0	: f32 		=   a;
    let k1	: f32 		=   b - a;
    let k2	: f32 		=   c - a;
    let k3	: f32 		=   e - a;
    let k4	: f32 		=   a - b - c + d;
    let k5	: f32 		=   a - c - e + g;
    let k6	: f32 		=   a - b - e + f;
    let k7	: f32 		= - a + b + c - d + e - f - g + h;

	return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}

fn noise2d(x: vec2f) -> f32
{
	var p	: vec2f		= vec2f(floor(x));
	var w	: vec2f		= vec2f(fract(x));
	var u	: vec2f 	= w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

	let a	: f32 		= hash2d(p + vec2f(0,0));
    let b	: f32 		= hash2d(p + vec2f(1,0));
    let c	: f32 		= hash2d(p + vec2f(0,1));
    let d	: f32 		= hash2d(p + vec2f(1,1));

	return -1.0+2.0*(a + (b-a)*u.x + (c-a)*u.y + (a - b - c + d)*u.x*u.y);
}


fn noise2dB(p: vec2f) -> f32
{
	var i	: vec2f 	= vec2f(floor(p));
	var f	: vec2f 	= vec2f(fract(p));
	var u	: vec2f 	= f * f * (3 - 2 * f);

	return mix( mix( dot( hash2dB( i + vec2f(0,0) ), f - vec2f(0,0) ), 
                     dot( hash2dB( i + vec2f(1,0) ), f - vec2f(1,0) ), u.x),
                mix( dot( hash2dB( i + vec2f(0,1) ), f - vec2f(0,1) ), 
                     dot( hash2dB( i + vec2f(1,1) ), f - vec2f(1,1) ), u.x), u.y);
}

fn fbm2d(p: vec2f, oct: u32) -> f32
{
	var f: f32 		= 1.9;
	var s: f32 		= 0.5;
	var a: f32 		= 0.0;
	var b: f32 		= 0.5;
	var x: vec2f	= p;

	for(var i: u32 = 0; i < oct; i++)
	{
		let n: f32 = noise2d(x);
		a += b * n;
		b *= s;
		x = f * m2 * x;
	}

	return a;
}

fn fbm3d(p: vec3f, oct: u32) -> f32
{
	var f: f32 		= 2.0;
	var s: f32 		= 0.5;
	var a: f32 		= 0.0;
	var b: f32 		= 0.5;
	var x: vec3f	= p;

	for(var i: u32 = 0; i < oct; i++)
	{
		let n: f32 = noise3d(x);
		a += b * n;
		b *= s;
		x = f * m3 * x;
	}

	return a;
}

fn opRepLim(p: vec3f, s: f32, lim: vec3f) -> vec3f
{
	return p - s * clamp(round(p / s), -lim, lim);
}

fn opRep(p: vec3f, s: f32) -> vec3f
{
	return p - s * round(p / s);
}

fn getNormal(p: vec3f) -> vec3f
{
	let dist	: f32	= scene(p, 0).w;
	let e		: vec2f	= vec2f(SURFACE_THRESHOLD, 0.0);
	return normalize(dist - vec3f(	scene(p - e.xyy, 0).w,
									scene(p - e.yxy, 0).w,
									scene(p - e.yyx, 0).w));
}	

//	===================
//		Raymarching
//	===================
fn rayMarch(r: Ray) -> vec4f
{
	var distCurrent	: f32 		= 0.0;
	var result		: vec4f		= vec4f();

	for(var i: u32 = 0; i < MAX_MARCHING_STEPS; i++)
	{
		let current: vec3f 	= r.org + r.dir * distCurrent;
			result			= scene(current, distCurrent);
			if(result.w < SURFACE_THRESHOLD)		{	return vec4f(result.xyz, distCurrent);	}
			distCurrent			+= result.w;
			if(distCurrent > MAX_MARCHING_DISTANCE) {	return vec4f(-1.0);	}
	}

	return vec4f(-1.0);
}

fn sdFbm(v: vec3f, dist: f32, oct: u32) -> f32
{
	var p: vec3f 	= v;
	var s: f32 		= 1.0;
	var d: f32 		= dist;

	for(var i: u32 = 0; i < oct; i++)
	{
		var n: f32 = s * sdBase(p);
		d = smax(d, -n, 0.2 * s);
		p = (m3 * 2) * p;
		s = 0.5 * s;
	}

	return d;
}

fn sdFbmB(v: vec3f, oct: u32) -> f32
{
	var p: vec3f 	= v;
	var s: f32 		= 1.0;
	var d: f32 		= 0;

	for(var i: u32 = 0; i < oct; i++)
	{
		var n: f32 = s * sdBase(p );

		d = smax(d, -n, 0.2 * s);
		n = smax(n, d - 0.1 * s	, 0.3 * s);
		d = smin(n, d 			, 0.3 * s);
		// p = (m3 * 1) * p;
		s = 0.5 * s;
	}

	return d;
}

fn sdFbmDunes(xy: vec2f, oct: u32) -> f32 
{
	var uv		: vec2f 	= xy;
    var value	: f32 		= 0.0;
    var factor	: f32 		= -3.8;
    uv *= factor;

    for (var i: u32 = 0; i < oct; i++) 
	{
        uv 		+= max(sin(uv * factor) / factor, cos(uv / factor) * factor).yx;
        value 	= -min(value + sin(uv.x) / factor, value + cos(uv.y / factor) / factor);
        uv 		= uv / 1.5 / factor;
    }

    return value / 2.0 + 1.5;
}


fn palette(t: f32, a: vec3<f32>, b: vec3<f32>, c: vec3<f32>, d: vec3<f32>) -> vec3<f32> 
{
    return a + b * cos(6.28318 * (c * t + d));
}

fn paletteSand(t: f32) -> vec3<f32> 
{
	return vec3f(0.93855, 0.63795, 0.5573);

//	let a: vec3f = vec3f(.5);
//	let b: vec3f = vec3f(.5);
//	let c: vec3f = vec3f(1,.7,.4);
//	let d: vec3f = vec3f(0,.15,.2);
//	return a + b * cos(6.28318 * (c * (t + (sin(time) / 2 + 0.5 )) + d));
}

fn paletteRock(t: f32) -> vec3<f32> 
{
	return vec3f(0.29, 0.25, 0.2);

//	let a: vec3f = vec3f(.5);
//	let b: vec3f = vec3f(.5);
//	let c: vec3f = vec3f(1,.7,.4);
//	let d: vec3f = vec3f(0,.15,.2);
//	return a + b * cos(6.28318 * (c * (t + (sin(time) / 2 + 0.5 )) + d));
}

fn paletteSky(t: f32) -> vec3<f32> 
{
	return vec3f(0.53, 0.81, 0.98);
//	let a: vec3f = vec3f(0.410, 0.800, 0.880);
//	let b: vec3f = vec3f(.150, -.510, -.302);
//	let c: vec3f = vec3f(1,.5,1);
//	let d: vec3f = vec3f(-1.255,-.250,.500);

//	let a: vec3f = vec3f(0.148, 0.800, 0.880);
//	let b: vec3f = vec3f(.248, -.510, -.58);
//	let c: vec3f = vec3f(1,.5,1);
//	let d: vec3f = vec3f(-1,-.250,.500);

//	return a + b * cos(6.28318 * (c * (t + (sin(time) / 2 + 0.5 )) + d));
}

fn paletteHaze(t: f32) -> vec3<f32> 
{
	return vec3f(0.77, 0.7, 0.62);
//	let a: vec3f = vec3f(0.56,0.61,0.6);
//	let b: vec3f = vec3f(0.178,0.078,0.028);
//	let c: vec3f = vec3f(1);
//	let d: vec3f = vec3f(0);

//	let a: vec3f = vec3f(0.410, 0.800, 0.880);
//	let b: vec3f = vec3f(.150, -.510, -.302);
//	let c: vec3f = vec3f(1,.5,1);
//	let d: vec3f = vec3f(-1.255,-.250,.500);

//	return a + b * cos(6.28318 * (c * (t + (sin(time) / 2 + 0.5 )) + d));
}



fn scene(v: vec3f, distCurrent: f32) -> vec4f
{
	var p			: vec3f			= v;
	var globalDst	: f32			= MAX_MARCHING_DISTANCE;
	var globalColor	: vec3f			= vec3f(0.5);
	var d			: f32			= 0.0;
	let bb			: f32			= clamp(sdBox(p, vec3f(4)),0.0001, 8);
	if(bb > 8.0) { return vec4f(globalColor,bb); }


	d = sdPlane(p, vec3f(0,1,0), 0.4);
	d = smin(d, sdPlane(p, vec3f(0,1,0), sdFbmDunes(p.xz, 1) - 1.5), 0.3);										//	dunes

	d = smin(d, sdSphere(p * vec3f(1,2.5,1) + vec3f(0,1.0,0), 0.8) , 0.3);										//	island
	d = smin(d, sdFbm(p + vec3f(0,-0.2,0),sdBox(p + vec3f(0,-0.2,0), vec3f(0.4) - 0.2) - 0.2, 6), 0.3);			//	rock
	d = smax(d, -sdSphere(p - lPos1, 0.001), 0.10);																//	cave
	
	globalColor = paletteSand(0.08);
	globalColor = mix(globalColor,vec3f(0.29, 0.25, 0.2) + noise3d(p * 200) / 35, clamp(p.y * 4, 0 , 1));
	globalColor = mix(globalColor,paletteRock(0.08) + noise3d(p * 200) / 35, clamp(p.y * 4, 0 , 1));


//	let isOctahedron: f32 = 1.0 - step(0.001, abs(d - octahedronDistance));
// 	let glowFactor: f32 = exp(-15.0 * abs(octahedronDistance)); // adjust 15.0 for different glow extents
//	let glowColor: vec3f = vec3f(0.28, 0.23, 0.19); // Blue-ish glow
//	let octahedronColor: vec3f = vec3f(0.28, 0.23, 0.19);  // Add glow
//	globalColor = mix(globalColor, octahedronColor, isOctahedron);

	return vec4f(globalColor, d);
}



/////////////////////////////////////////////////////////////////////////////////////
//	==================
//		Startup
//	==================
const MAX_MARCHING_STEPS	: u32 	= 150;
const SURFACE_THRESHOLD		: f32	= 0.001;
const MAX_MARCHING_DISTANCE	: f32	= 15.0;
const PI 					: f32	= 3.14159265359;
const AMBIENT				: f32	= 0.75;
const lPos1					: vec3f	= vec3f(-0.12, 0.4, 0.28);


fn softShadow(ro: vec3f, rd: vec3f, mint: f32, k: f32) -> f32 
{
    var res	: f32 = 1.0;
    var t	: f32 = mint;
    for (var i: u32 = 0; i < 5; i++) 
	{
        let p: vec3f 	= ro + rd * t;
        let h: f32 		= scene(p, 0.0).w;
        res 			= min(res, 0.5 * k * h / t);
        t 				+= clamp(h, 0.1, 1);

        if (h < 0.001) { break; }
    }
    return clamp(res, 0.0, 1.0);
}

fn pointLight(pos: vec3f, hit: vec3f, normal: vec3f, att: f32) -> f32 
{
    let lightDir 	: vec3f	= normalize(pos - hit);
    let lightDist 	: f32 	= length(pos - hit);
    let attenuation : f32 	= 1.0 / (1.0 + att * lightDist * lightDist);
    let intensity 	: f32 	= max(dot(normal, lightDir), 0.0) * attenuation;

    return intensity;
}

fn pointLightSoftShadow(ro: vec3f, lightPos: vec3f, k: f32) -> f32 
{
    var res			: f32 		= 1.0;
    var t			: f32 		= 0.01;
    let rd			: vec3f 	= normalize(lightPos - ro);
    let maxDist		: f32 		= length(lightPos - ro);

    for (var i: u32 = 0; i < 5; i++) 
	{
        let p: vec3f	= ro + rd * t;
        let h: f32		= scene(p, 0.0).w;
        res 			= min(res, k * h / t);
        t 				+= clamp(h, 0.1, 1.0);
        
        if (h < 0.001 || t > maxDist) { break; }
    }
    
    return clamp(res, 0.0, 1.0);
}

@fragment
fn fragmentMain(gl: vsOut) -> @location(0) vec4f 
{
	let origin		: vec3f 	= vec3f(0);
	let uv			: vec2f 	= (gl.uv);
	let up			: vec3f 	= vec3f(0, 1, 0);
	let camPos		: vec3f 	= vec3f(0.5 * sin(time / 2), 0.4, 1 + sin(time / 1) / 8);
	let viewMatrix	: mat4x4f 	= viewMatrix(camPos, origin, up);
	let camDir		: vec3f		= normalize((viewMatrix * vec4f(uv,-1,0)).xyz);
	let ray			: Ray		= Ray(camDir, camPos);
	let result		: vec4f		= rayMarch(ray);
	let dist		: f32		= result.w;
	let HAZE		: vec3f		= paletteHaze(0); 	// vec3f(0.77, 0.7, 0.62);
	let SKY			: vec3f		= paletteSky(0);	// vec3f(0.53, 0.81, 0.98);
//	let SUN			: vec3f 	= vec3f(4,8,8) * vec3f(sin(time),cos(time) / 2 + .5,cos(time));
	let SUN			: vec3f 	= vec3f(4,8,8);


	if(dist == -1.0)
	{
		// discard;
		return vec4f(mix(HAZE,SKY, uv.y * 1.2 - 0.2),1);
	}
	else
	{
		var color	: vec3f		= result.xyz;
		let hit		: vec3f		= ray.org + ray.dir * dist;
		let normal	: vec3f		= getNormal(hit);
		let fog		: f32		= clamp(0,1,pow(dist / 10, 2));

		var shadow 	: f32		= clamp(0,1,softShadow(hit, normalize(SUN - hit), 0.1, 4.0) + 0.25);
		var pShadow	: f32 		= pointLightSoftShadow(hit, lPos1, 16.0);
			
			color				= mix(color, paletteSand(0.08), pow(dot(normal, vec3f(0,1,0)), 5));			// 	sand
			color				= color + pointLight(lPos1, hit, normal, 150 + 50 * abs(sin(time * 5)) ) * pShadow * vec3f(1,0.5,0);	//	point light
			color				= mix(color * 0.4 * paletteSand(0.09), color, shadow);						//	direct shadow
			

		// return vec4f(vec3f(shadow),1);
		return vec4f(mix(color * (clamp(dot(vec3f(4,8,6), normal) / 15,0.0,1.0) + AMBIENT), HAZE, fog), 1);
		
	}

//	return vec4f(uv, time * 0, 1);
}