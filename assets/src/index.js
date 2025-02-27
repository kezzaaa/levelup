import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";
import { FBXLoader } from "three/examples/jsm/loaders/FBXLoader";

console.log("✅ Starting Three.js setup");

let renderer, scene, camera, mixer, avatar;
let animations = {};
let currentAnimation = null;

// ✅ Function to initialize Three.js
function initScene() {
  console.log("🔄 Initializing Three.js Scene...");

  if (renderer) {
    renderer.dispose();
    document.getElementById("app").innerHTML = ""; // ✅ Clears previous canvas
  }

  // ✅ Make Renderer Transparent
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true }); // ✅ `alpha: true` enables transparency
  renderer.setClearColor(0x000000, 0); // ✅ Fully transparent background (RGBA: 0)
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.getElementById("app").appendChild(renderer.domElement);

  scene = new THREE.Scene();
  
  let ambientLight = new THREE.AmbientLight("#fff", 1);
  scene.add(ambientLight);

  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1000);
  camera.position.set(0, 1, 4);

  animate();
}

// ✅ Function to load the GLB model dynamically
function loadGLBModel(glbUrl) {
  console.log(`⏳ Loading user GLB model: ${glbUrl}`);

  const gltfLoader = new GLTFLoader();
  gltfLoader.load(
    glbUrl,
    function (gltf) {
      console.log("✅ GLB Model Loaded Successfully!");
      avatar = gltf.scene;
      scene.add(avatar);
      mixer = new THREE.AnimationMixer(avatar);

      // ✅ Load animations
      const animationFiles = {
        "1": "idle.fbx",
        "2": "dance.fbx"
      };

      Object.values(animationFiles).forEach((file) => loadFBXAnimation(new FBXLoader(), file));

      // ✅ Allow switching animations using keys
      window.addEventListener("keydown", (event) => {
        if (animationFiles[event.key]) {
          playAnimation(animationFiles[event.key]);
        }
      });
    },
    undefined,
    function (error) {
      console.error("❌ GLB Load Error:", error);
    }
  );
}

// ✅ Attach `loadGLBModel()` to `window` so Flutter can access it
window.loadGLBModel = loadGLBModel;

// ✅ Function to load FBX animations
function loadFBXAnimation(loader, file) {
    const filePath = `https://localhost/assets/animations/${file}`;
    console.log(`⏳ Fetching animation: ${filePath}`);
  
    loader.load(
      filePath,
      function (fbx) {
        console.log(`✅ ${file} Animation Loaded!`);
        
        let fbxAnimation = fbx.animations[0];
  
        // ✅ Fix scale issue for position keyframes
        fbxAnimation.tracks.forEach((track) => {
          if (track.name.includes("position")) {
            track.values.forEach((v, i) => {
              track.values[i] = v / 100; // ✅ Scale down 100x if animation is too big
            });
          }
        });
  
        if (avatar) {
          let modelBones = avatar.children[0].skeleton ? avatar.children[0] : avatar;
          
          animations[file] = mixer.clipAction(fbxAnimation, modelBones);
          animations[file].setLoop(THREE.LoopRepeat);
  
          console.log(`📌 Animation "${file}" assigned to avatar correctly.`);
        } else {
          console.error("❌ Avatar not found for animation!");
        }
  
        if (!currentAnimation) playAnimation(file);
      },
      undefined,
      function (error) {
        console.error(`❌ FBX Load Error (${file}):`, error);
      }
    );
  }
  

// ✅ Function to switch animations
function playAnimation(name) {
    if (!animations[name]) {
      console.warn(`⚠️ Animation "${name}" not found!`);
      return;
    }
  
    // ✅ Stop all animations before playing new one
    mixer.stopAllAction();
  
    currentAnimation = animations[name];
    currentAnimation.setLoop(THREE.LoopRepeat);
    currentAnimation.play();
    console.log(`🎬 Playing animation: ${name}`);
  }

// ✅ Animation loop
function animate() {
    requestAnimationFrame(animate);
  
    if (mixer) {
      mixer.update(0.02);
  
      if (currentAnimation) {
        console.log(`🎥 Animation Running: ${currentAnimation.getEffectiveWeight()}`);
      } else {
        console.warn("⚠️ No active animation.");
      }
    }
  
    renderer.render(scene, camera);
  }

// ✅ Reload scene on WebView refresh
window.addEventListener("load", () => {
  console.log("🔄 WebView Reloaded, waiting for GLB URL from Flutter...");
  initScene();
});
