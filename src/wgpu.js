import vs from './shader/VS.wgsl?raw';
import fs from './shader/FS.wgsl?raw';

const	fps				= document.getElementById('wgpu_fps');
const 	canvas			= document.getElementById('webgpu-canvas');
		canvas.width	= 800;
		canvas.height	= 800;
const 	adapter 		= await navigator.gpu.requestAdapter();
const 	device 			= await adapter.requestDevice();
const 	context 		= canvas.getContext('webgpu');
const 	canvasFormat 	= navigator.gpu.getPreferredCanvasFormat();
const 	canvasConfig	= {	device		: device,
    						format		: 'bgra8unorm',
    						usage		: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
    						alphaMode	: 'opaque'};
// 	const 	swapChain 		= context.configure({	device: device, format: canvasFormat  });
	const 	swapChain 		= context.configure( canvasConfig );
const 	encoder 		= device.createCommandEncoder();
const 	passDescriptor 	= {	colorAttachments: [{	view		: context.getCurrentTexture().createView(),
													loadOp		: "clear",
													clearValue	: [1.0, 0.5, 0.7, 1],
													storeOp		: "store"	}]};
const 	pass 			= encoder.beginRenderPass( passDescriptor );



const	vertices 		= new Float32Array([	-1.0, -1.0, 1.0, -1.0,  1.0,  1.0,
			  									-1.0, -1.0, 1.0,  1.0, -1.0,  1.0	]);

//	=============================================
//	initialize vertex buffer with zeros
//	=============================================
const	vertexBuffer 	= device.createBuffer({	label	: "screen",
												size	: vertices.byteLength,
												usage	: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST	});
//	=============================================
//	write the vertices into the buffer (offset 0)
//	=============================================
		device.queue.writeBuffer(vertexBuffer, 0, vertices);

const vertexBufferLayout = 	{	arrayStride: 8,
								attributes: [{	format			: "float32x2"	,
			  									offset			: 0				,
			  									shaderLocation	: 0				}]};

//	=============================================
//	setup the shader Module with its sources
//	=============================================
const shader			= device.createShaderModule({	label	: "VertexShader",
														code	: vs + fs  		});

//	=============================================
//	general configuration on how to render
//	=============================================
const pipeline 			= device.createRenderPipeline({	label	: "Pipeline",
  														layout	: "auto",
  														vertex	: 	{
    																	module		: shader,
    																	entryPoint	: "vertexMain",
    																	buffers		: [ vertexBufferLayout ]
  																	},
														fragment: 	{
    																	module		: shader,
    																	entryPoint	: "fragmentMain",
    																	targets		: [{ format: canvasFormat }]
  																	}
														});

//	==============================================
//	set uniform buffers (time)
//	==============================================

const uniformArray 		= new Float32Array([0.5]);
const uniformBuffer 	= device.createBuffer({	label	: "Uniform Buffer",
  												size	: uniformArray.byteLength,
  												usage	: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST	});
device.queue.writeBuffer(uniformBuffer, 0, uniformArray);

//	==============================================
//	create bind group 0 binding 0
//	==============================================

const bindGroup 		= device.createBindGroup({	label	: "Bind Group 0",
													layout	: pipeline.getBindGroupLayout(0),
													entries	: [{	binding		: 0,
	  																resource	: { buffer: uniformBuffer }	}],
												});

pass.setPipeline		(pipeline);
pass.setVertexBuffer	(0, vertexBuffer);
pass.setBindGroup		(0, bindGroup);
pass.draw				(vertices.length / 2);
pass.end				();		
device.queue.submit([encoder.finish()]);

var fc 		= 0;
var last 	= 0;
var then 	= 0;

export async function renderLoop(now)
{
	now 			= now * 0.001;
    var deltaTime 	= now - then;
    then 			= now;

	fc++;
    if (now - last >= 1) 
	{
        const f = fc / ((now - last) / 1);
        last = now;
        fc = 0;
        fps.innerHTML = `( ${f.toFixed(2)} FPS )`;
    }

	passDescriptor.colorAttachments[0].view 	= context.getCurrentTexture().createView();
	const commandEncoder 						= device.createCommandEncoder();
	const passEncoder 							= commandEncoder.beginRenderPass(passDescriptor);

	uniformArray[0] = now;
	device.queue.writeBuffer(uniformBuffer, 0, uniformArray);
	passEncoder.setPipeline			(pipeline);
	passEncoder.setVertexBuffer		(0, vertexBuffer);
	passEncoder.setBindGroup		(0, bindGroup);
	passEncoder.draw				(vertices.length / 2);
	passEncoder.end					();
	device.queue.submit([commandEncoder.finish()]);
	//	requestAnimationFrame(renderLoop);
}

//	requestAnimationFrame(renderLoop);