//	=============================
//	|	SDF FBM					|
//	=============================

import vs from './shader/VS.glsl?raw';
import fs from './shader/FS.glsl?raw';

const	fps				= document.getElementById('wgl2_fps');
const	canvas 			= document.getElementById('webgl-canvas');
		canvas.width 	= 800;
		canvas.height 	= 800;
const 	gl 				= canvas.getContext('webgl2');

function createShader(gl, type, source) 
{
	const shader = gl.createShader(type);
	gl.shaderSource(shader, source);
	gl.compileShader(shader);
	if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) 
	{
		console.error(`An error occurred compiling the shader: ${gl.getShaderInfoLog(shader)}`);
		gl.deleteShader(shader);
		return null;
	}
	return shader;
}

const vertexShader 		= createShader(gl, gl.VERTEX_SHADER, vs);
const fragmentShader 	= createShader(gl, gl.FRAGMENT_SHADER, fs);
const program 			= gl.createProgram();
gl.attachShader(program, vertexShader);
gl.attachShader(program, fragmentShader);
gl.linkProgram(program);

const vertices 			= new Float32Array([-1.0, -1.0, 1.0, -1.0, 1.0, 1.0,-1.0, -1.0, 1.0, 1.0, -1.0, 1.0]);
const vertexBuffer 		= gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);


const positionAttribute = gl.getAttribLocation(program, 'a_position');
gl.enableVertexAttribArray(positionAttribute);
gl.vertexAttribPointer(positionAttribute, 2, gl.FLOAT, false, 0, 0);

const timeLocation 		= gl.getUniformLocation(program, 'time');


let fc 		= 0;
let last 	= 0;
var then 	= 0;

export function renderLoop(now)
{
	now 			= now * 0.001;
	const deltaTime = now - then;
	then 			= now;

	fc++;
    if (now - last >= 1) 
	{
        const f = fc / ((now - last) / 1);
        last = now;
        fc = 0;
        fps.innerHTML = `( ${f.toFixed(2)} FPS )`;
    }

	gl.clearColor(1.0, 0.5, 0.7, 1.0);
	gl.clear(gl.COLOR_BUFFER_BIT);
	gl.useProgram(program);
	gl.uniform1f(timeLocation, now);
	gl.drawArrays(gl.TRIANGLES, 0, vertices.length / 2);
	//	requestAnimationFrame(renderLoop);
}

//	requestAnimationFrame(renderLoop);
