import './css/style.css'
import * as wgpu_three from './three_wgpu.js';
import * as wgl2_three from './three_wgl2.js';
import * as wgpu   from './wgpu';
import * as wgl2   from './wgl2';

window.step = 0;
wgpu_three.init()
wgl2_three.init()

let accumulatedTimeWGL2 = 0;
let accumulatedTimeWGPU = 0;
let lastNow 			= 0;

function masterLoop(now) 
{
    let deltaTime 		= now - lastNow; 
    let s 				= Math.sin(now / 1000);

	if(window.step == 0)
	{
		if (s >= 0) { accumulatedTimeWGPU += deltaTime; wgpu.renderLoop(accumulatedTimeWGPU); }
		if (s  < 0) { accumulatedTimeWGL2 += deltaTime; wgl2.renderLoop(accumulatedTimeWGL2); }
	}

	if(window.step == 1)
	{
	 	if (s >= 0) { accumulatedTimeWGPU += deltaTime; wgpu_three.animate(accumulatedTimeWGPU); }
	    if (s  < 0) { accumulatedTimeWGL2 += deltaTime; wgl2_three.animate(accumulatedTimeWGL2); }
	}

    lastNow = now;
    requestAnimationFrame(masterLoop);
}

requestAnimationFrame(masterLoop);