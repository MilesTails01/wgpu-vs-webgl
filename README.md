# WebGL vs WebGPU

![image](https://github.com/MilesTails01/wgpu-vs-webgl/assets/83541965/428fd08b-73fe-4629-ba0e-d48d42a8edfa)

This repository is dedicated to exploring the capabilities of WebGPU, the next-gen graphics API that promises to revolutionize web-based 3D and 2D graphics. WebGPU is heavily inspired by modern graphics APIs like Vulkan, Metal, and Direct3D12, offering reduced overhead and impressive performance. benchmarks have been designed to probe the boundaries of what WebGPU can currently achieve, focusing on two key aspects: Scene rendering via Fragment Shaders (SDF Fragment Shader) and Vertex Shaders. While WebGPU has shown immense promise, it's worth noting that it's still under development. the tests revealed some issues with shadow mapping and overall performance when compared to the established WebGL standard, especially when using high polygon scenes with Three.js. it's an exciting area to watch for anyone interested in web graphics technology.

## Installation


**Download the Project**
```
git clone https://github.com/MilesTails01/webgpu-vs-webgl.git
git pull
```

**Install Node.js**

If Node.js is not already installed download and install it from the official Node.js website: https://nodejs.org/en/download/


**Install project dependencies**

navigate to the project folder in your terminal.
this project includes: `gl-matrix` `three.js` `vite` `stats.js`

```
npm install
```

**Build project**


## Build

```
npm run build
```


## Usage

```
npm run dev
```


# Commits

🐛 `:bug:` to indicate fixing a bug  
🔥 `:fire:` to indicate removing code or files  
🔧 `:fix:` mostly small little mistakes  
🧹 `:broom:` cleanup, or layouting the code  
✨ `:sparkles:` to indicate adding new features  
💄 `:lipstick:` to indicate improving the UI/UX  
🐎 `:racehorse:` to indicate improving performance  
🔒 `:lock:` to indicate dealing with security  
📝 `:memo:` to indicate writing documentation  
🚧 `:construction:` to indicate work in progress  
