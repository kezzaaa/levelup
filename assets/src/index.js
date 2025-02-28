import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader";
import { FBXLoader } from "three/examples/jsm/loaders/FBXLoader";

console.log("✅ Starting Three.js setup");

let renderer, scene, camera, mixer, avatar;
let animations = {};
let currentAnimation = null;
let userGender = "male";

// ✅ Variables for Smooth Drag Rotation
let isDragging = false;
let previousTouchX = 0;
let rotationTarget = 0; // ✅ Target rotation (used for interpolation)
let rotationVelocity = 0;
let rotationDamping = 0.92; // ✅ Adjust for smoother slowing
let rotationSpeed = 0.007;
let rotationAcceleration = 0.005; // ✅ Adjust sensitivity

// ✅ Function to initialize Three.js
function initScene() {
  console.log("🔄 Initializing Three.js Scene...");

  if (renderer) {
    renderer.dispose();
    document.getElementById("app").innerHTML = ""; // ✅ Clears previous canvas
  }

  // ✅ Make Renderer Transparent
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
  renderer.setClearColor(0x000000, 0);
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.getElementById("app").appendChild(renderer.domElement);

  scene = new THREE.Scene();

  // ✅ Increase Ambient Light (Softens Shadows)
  const ambientLight = new THREE.AmbientLight(0xffffff, 0.75); // 🔥 Increase slightly to brighten shadows
  scene.add(ambientLight);

  // ✅ Directional Light (Keep It Soft)
  const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
  directionalLight.position.set(2, 5, 5);
  directionalLight.castShadow = false;
  scene.add(directionalLight);

  // ✅ Add a Soft Fill Light (Removes Harsh Clothing Shadows)
  const fillLight = new THREE.DirectionalLight(0xffffff, 0.7);
  fillLight.position.set(-2, 3, 3); // 🔥 Side light to reduce contrast on clothes
  fillLight.castShadow = false;
  scene.add(fillLight);

  // ✅ Reduce Shadow Intensity on Clothes
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 0.8; // 🔥 Lower exposure slightly to balance brightness
  renderer.outputEncoding = THREE.sRGBEncoding;

  // ✅ Create Static Camera
  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1000);
  camera.position.set(0, 1.2, 3);
  camera.lookAt(0, 1, 0); // ✅ Focuses on avatar

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
      avatar.position.set(0, 0, 0); // ✅ Keep avatar centered
      scene.add(avatar);
      mixer = new THREE.AnimationMixer(avatar);

      // ✅ Select animation based on gender
      const genderBasedAnimation = userGender === "female" ? "f_idle.fbx" : "m_idle.fbx";

      console.log(`🎭 Gender: ${userGender} → Playing animation: ${genderBasedAnimation}`);

      // ✅ Load only the relevant idle animation
      loadFBXAnimation(new FBXLoader(), genderBasedAnimation);

      // ✅ Enable Rotation Controls
      enableTouchRotation();

      // ✅ Allow switching animations using keys
      window.addEventListener("keydown", (event) => {
        if (event.key === "1") {
          playAnimation("f_idle.fbx");
        } else if (event.key === "2") {
          playAnimation("m_idle.fbx");
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

// ✅ Function to receive gender from Flutter
window.setUserGender = function (gender) {
  userGender = gender.toLowerCase();
  console.log(`✅ Received gender from Flutter: ${userGender}`);
};

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

          // ✅ Auto-play idle animation
          playAnimation(file);
        } else {
          console.error("❌ Avatar not found for animation!");
        }
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
  
    if (mixer) mixer.update(0.02);

    // ✅ Smoothly interpolate rotation
    if (avatar) {
      avatar.rotation.y += rotationVelocity;
      rotationVelocity *= rotationDamping; // ✅ Smooth easing (damping)

      // ✅ Prevent extreme fast spinning
      rotationVelocity = Math.max(Math.min(rotationVelocity, 0.05), -0.05);
    }

    renderer.render(scene, camera);
}

// ✅ Reload scene on WebView refresh
window.addEventListener("load", () => {
  console.log("🔄 WebView Reloaded, waiting for GLB URL from Flutter...");
  initScene();
});

// ✅ Improved Touch Rotation (Smoother Feel)
function enableTouchRotation() {
  const canvas = renderer.domElement;

  // 🖱 Mouse Down (Start Dragging)
  canvas.addEventListener("mousedown", (event) => {
    isDragging = true;
    previousTouchX = event.clientX;
  });

  // 📱 Touch Start
  canvas.addEventListener("touchstart", (event) => {
    isDragging = true;
    previousTouchX = event.touches[0].clientX;
  });

  // 🖱 Mouse Move (Rotate Avatar)
  canvas.addEventListener("mousemove", (event) => {
    if (!isDragging || !avatar) return;
    let deltaX = event.clientX - previousTouchX;
    rotationVelocity += deltaX * rotationAcceleration; // ✅ Apply acceleration
    previousTouchX = event.clientX;
  });

  // 📱 Touch Move (Rotate Avatar)
  canvas.addEventListener("touchmove", (event) => {
    if (!isDragging || !avatar) return;
    let deltaX = event.touches[0].clientX - previousTouchX;
    rotationVelocity += deltaX * rotationAcceleration; // ✅ Apply acceleration
    previousTouchX = event.touches[0].clientX;
  });

  // ✅ Stop Rotation on Release
  canvas.addEventListener("mouseup", () => { isDragging = false; });
  canvas.addEventListener("mouseleave", () => { isDragging = false; });
  canvas.addEventListener("touchend", () => { isDragging = false; });
}
