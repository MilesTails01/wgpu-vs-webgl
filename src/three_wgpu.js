import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import WebGPURenderer from 'three/examples/jsm/renderers/webgpu/WebGPURenderer.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls';
import { ImprovedNoise } from 'three/examples/jsm/math/ImprovedNoise.js';
import { SimplexNoise } from 'three/examples/jsm/math/SimplexNoise';
import Stats from 'stats.js';

let camera, scene, renderer, mesh, loader; 
export const stats = new Stats();

const	fps				= document.getElementById('wgpu_fps');
const 	canvas			= document.getElementById('webgpu-canvasT');
		canvas.width	= 800;
		canvas.height	= 800;

		stats.dom.className = "statsA";
		canvas.parentElement.appendChild(stats.dom);

const 	adapter 		= await navigator.gpu.requestAdapter();
const 	device 			= await adapter.requestDevice();
const 	context 		= canvas.getContext('webgpu');
const 	canvasFormat 	= navigator.gpu.getPreferredCanvasFormat();
const 	canvasConfig	= {	device		: device,
    						format		: 'bgra8unorm',
    						usage		: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC,
    						alphaMode	: 'opaque'};
const 	swapChain 		= context.configure( canvasConfig );

export async function init()
{
	camera 				= new THREE.PerspectiveCamera(70, canvas.width / canvas.height, 0.01, 100);

	camera.position.z = 5;
	camera.position.y = 2;
	camera.lookAt(0, 0, 0);
	scene 				= new THREE.Scene();

	const geometry 		= new THREE.PlaneGeometry( 10, 10, 100, 100 );
	const vertices 		= geometry.attributes.position.array;
	const noise 		= new SimplexNoise();
	const inoise		= new ImprovedNoise();
	const freq			= 2;

	
	// geometry.rotateX( - Math.PI / 2 );
	for (let i = 0, j = 0; i < vertices.length; i += 3, j++) 
	{
		const x = vertices[i];
		const y = vertices[i + 1];
		const z = inoise.noise(x / freq, y / freq, 0);
		vertices[i + 2] = z;
	}

	geometry.computeVertexNormals();

	const terrain 		= new THREE.Mesh( geometry, new THREE.MeshPhongMaterial( { color: 0xffc107, side: THREE.DoubleSide } ) );
	const ambient 		= new THREE.AmbientLight( 0x404040 );
	const direct 		= new THREE.DirectionalLight( 0xffffff, 1.75 );
	const wireframe 	= new THREE.Mesh(geometry, new THREE.MeshBasicMaterial({ color: 0x555555, wireframe: true, transparent: true }));

	direct.castShadow 				= true;
	direct.shadow.mapSize.width 	= 2048;
	direct.shadow.mapSize.height	= 2048;
	direct.shadow.camera.near 		= 0.5; 
	direct.shadow.camera.far 		= 500;

	for (let i = 0; i < 15; i++) 
	{
		const sphereGeometry 	= new THREE.SphereGeometry(0.25, 128, 128);
		const sphereMaterial 	= new THREE.MeshPhongMaterial({ color: getRandomColor(), });
		const sphere 			= new THREE.Mesh(sphereGeometry, sphereMaterial);
		sphere.castShadow 		= true; 
		sphere.receiveShadow 	= false;
		sphere.position.set(Math.random()*10-5, Math.random()*5-2.5, Math.random()*10-5);
		scene.add(sphere);
	}

	// for (let i = 0; i < 10; i++) 
	// {
	// 	const pointLight = new THREE.PointLight(0x00ff00, 5, 80, 3);
	// 	pointLight.position.set(Math.random()*10-5, Math.random()*10-5, Math.random()*10-5);
	// 	pointLight.castShadow = true;
	// 	scene.add(pointLight);
	// }

	terrain.receiveShadow = true;
	terrain.rotateX(-Math.PI / 2);
	wireframe.rotateX(-Math.PI / 2);
	wireframe.position.y += .001;
	direct.position.set( 1, .5, 1 );


	scene.add( ambient );
	scene.add( direct );
	scene.add( terrain );
	// scene.add( wireframe );
		

	renderer 					= new WebGPURenderer({ context });
	renderer.shadowMap.enabled 	= true;
	renderer.shadowMap.type 	= THREE.PCFSoftShadowMap;
	renderer.setSize(800,800);
	renderer.setClearColor(new THREE.Color( 0, 0, 0 ), 0);
}

function getRandomColor() 
{
	const letters 	= '0123456789ABCDEF';
	let color 		= '#';
	for (let i = 0; i < 6; i++) 
	{
		color += letters[Math.floor(Math.random() * 16)];
	}
	return color;
}

export function animate(now)
{
	stats.begin();


	camera.position.z = 5 * Math.sin(now * 0.001);
	camera.position.x = 5 * Math.cos(now * 0.001);
	camera.lookAt(0, 0, 0);

	if(mesh && mesh.rotation)
	mesh.rotation.y += 0.01;

	renderer.render(scene, camera);
	stats.end();
	// requestAnimationFrame(animate);
}

// await init();
// animate();
