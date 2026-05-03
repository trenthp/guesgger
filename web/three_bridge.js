import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { clone as skeletonClone } from 'three/addons/utils/SkeletonUtils.js';

/**
 * ThreeBridge — JS-side scene manager for the Flutter game.
 * Dart communicates via window.ThreeBridge.* methods.
 */
class ThreeBridgeClass {
  constructor() {
    this.renderer = null;
    this.scene = null;
    this.camera = null;
    this.clock = new THREE.Clock();
    this.loader = new GLTFLoader();

    // Model cache: modelId -> { scene, animations, hasSkeleton }
    this.modelCache = {};

    // Active scene objects: objectId -> { mesh, mixer, actions, currentAction }
    this.objects = {};

    // Ground, road, sky references
    this.ground = null;
    this.road = null;
    this.laneLines = [];
    this.roadEdges = [];
    this.skyDome = null;

    // Walkway escalator visuals — split into right (with you) and left
    // (against you) strips, with the middle lane left as plain road.
    this.walkwayGroup = null; // container for all walkway geometry
    this.walkwayGroovesRight = []; // cross-grooves on the right strip
    this.walkwayGroovesLeft = [];  // cross-grooves on the left strip
    this.walkwayChevronsRight = []; // arrows on the right strip
    this.walkwayChevronsLeft = [];  // arrows on the left strip

    // Walkway clipping planes (Z-range visibility)
    this.walkwayClipStart = null;
    this.walkwayClipEnd = null;
    this.walkwayEntryRamp = null;
    this.walkwayExitRamp = null;
    this.walkwayRoadOverlayRight = null;
    this.walkwayRoadOverlayLeft = null;
    this.walkwayGroundOverlay = null;

    // Effects
    this.hitOverlayTimer = 0;

    // Lights
    this.ambientLight = null;
    this.directionalLight = null;
  }

  /**
   * Initialize the three.js scene.
   */
  init(canvas, width, height) {
    if (!canvas || typeof canvas === 'number') {
      canvas = document.getElementById('three-canvas');
      if (!canvas) {
        console.error('[ThreeBridge] No canvas found');
        return;
      }
      width = width || window.innerWidth;
      height = height || window.innerHeight;
    }

    // Renderer
    this.renderer = new THREE.WebGLRenderer({
      canvas: canvas,
      antialias: true,
      alpha: false,
    });
    this.renderer.setSize(width, height);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.2;
    this.renderer.localClippingEnabled = true;

    // Scene
    this.scene = new THREE.Scene();
    this.scene.fog = new THREE.Fog(0x1a1a2e, 130, 230);

    // Camera
    this.camera = new THREE.PerspectiveCamera(60, width / height, 1, 250);
    this.camera.position.set(0, 10, 5);
    this.camera.lookAt(0, 0, 60);

    // Lighting — late-afternoon golden hour. Intensities/colors are tinted
    // toward dusk as the park-closing timer drops via setDaylight().
    this.daylight = 1.0;

    this.ambientLight = new THREE.AmbientLight(0xffd8a8, 0.9);
    this.scene.add(this.ambientLight);

    // Low-angle "sun" from the side — warm gold, casts long shadows
    this.directionalLight = new THREE.DirectionalLight(0xffb070, 1.4);
    this.directionalLight.position.set(20, 8, -6);
    this.directionalLight.castShadow = true;
    this.directionalLight.shadow.mapSize.width = 2048;
    this.directionalLight.shadow.mapSize.height = 2048;
    this.directionalLight.shadow.camera.near = 1;
    this.directionalLight.shadow.camera.far = 150;
    this.directionalLight.shadow.camera.left = -30;
    this.directionalLight.shadow.camera.right = 30;
    this.directionalLight.shadow.camera.top = 30;
    this.directionalLight.shadow.camera.bottom = -30;
    this.scene.add(this.directionalLight);

    // Hemisphere — warm sky / cool earth fill
    this.hemiLight = new THREE.HemisphereLight(0xffb877, 0x3a3247, 0.6);
    this.scene.add(this.hemiLight);

    // Subtle cool fill light from front
    this.fillLight = new THREE.DirectionalLight(0xa3a8c8, 0.35);
    this.fillLight.position.set(0, 5, -15);
    this.scene.add(this.fillLight);

    // Build static environment
    this._buildGround();
    this._buildWalkway();
    this._buildSky();

    console.log('[ThreeBridge] Initialized');
  }

  resize(width, height) {
    if (!this.renderer) return;
    this.renderer.setSize(width, height);
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
  }

  setCameraParams(fov, near, far, posX, posY, posZ, lookX, lookY, lookZ) {
    if (!this.camera) return;
    this.camera.fov = fov;
    this.camera.near = near;
    this.camera.far = far;
    this.camera.position.set(posX, posY, posZ);
    this.camera.lookAt(lookX, lookY, lookZ);
    this.camera.updateProjectionMatrix();
  }

  loadModel(id, url) {
    return new Promise((resolve, reject) => {
      if (this.modelCache[id]) {
        resolve();
        return;
      }
      this.loader.load(
        url,
        (gltf) => {
          // Check if model has skinned meshes (needs SkeletonUtils.clone)
          let hasSkeleton = false;
          gltf.scene.traverse((child) => {
            if (child.isSkinnedMesh) {
              hasSkeleton = true;
            }
            if (child.isMesh) {
              child.castShadow = true;
              child.receiveShadow = true;
            }
          });

          this.modelCache[id] = {
            scene: gltf.scene,
            animations: gltf.animations || [],
            hasSkeleton,
          };
          const animNames = (gltf.animations || []).map(a => a.name).join(', ');
          console.log(`[ThreeBridge] Model loaded: ${id} (${gltf.animations.length} anims, skeleton: ${hasSkeleton}, names: [${animNames}])`);
          resolve();
        },
        undefined,
        (error) => {
          console.warn(`[ThreeBridge] Failed to load model ${id}: ${error}`);
          reject(error);
        }
      );
    });
  }

  syncScene(payload) {
    const data = typeof payload === 'string' ? JSON.parse(payload) : payload;
    const delta = this.clock.getDelta();

    if (data.camera) {
      const c = data.camera;
      this.setCameraParams(c.fov, c.near, c.far, c.posX, c.posY, c.posZ, c.lookX, c.lookY, c.lookZ);
    }

    if (data.remove) {
      for (const id of data.remove) {
        this._removeObject(id);
      }
    }

    if (data.add) {
      for (const obj of data.add) {
        this._addObject(obj);
      }
    }

    if (data.update) {
      for (const obj of data.update) {
        this._updateObject(obj, delta);
      }
    }

    if (data.walkwayRanges !== undefined) {
      this._updateWalkwayClipping(data.walkwayRanges);
    }

    if (data.zone) {
      this._updateZoneVisuals(data.zone);
    }

    if (data.daylight !== undefined) {
      this._setDaylight(data.daylight);
    }

    if (data.scrollOffset !== undefined) {
      this._scrollGround(data.scrollOffset);
    }

    if (data.walkwayLaneScroll) {
      this._scrollWalkwayLanes(
        data.walkwayLaneScroll.right || 0,
        data.walkwayLaneScroll.left || 0,
      );
    }

    if (data.effects) {
      if (data.effects.hitFlash) {
        this.hitOverlayTimer = 0.5;
      }
    }

    // Update all animation mixers
    for (const id of Object.keys(this.objects)) {
      const obj = this.objects[id];
      if (obj.mixer) {
        obj.mixer.update(delta);
      }
    }

    if (this.hitOverlayTimer > 0) {
      this.hitOverlayTimer -= delta;
    }
  }

  renderFrame() {
    if (!this.renderer || !this.scene || !this.camera) return;
    try {
      this.renderer.render(this.scene, this.camera);
    } catch (e) {
      console.error('[ThreeBridge] Render error:', e);
    }
  }

  dispose() {
    if (this.renderer) {
      this.renderer.dispose();
    }
    for (const id of Object.keys(this.objects)) {
      this._removeObject(id);
    }
    this.modelCache = {};
    this.objects = {};
  }

  // --- Internal methods ---

  /**
   * Check if a model is loaded in cache.
   */
  isModelLoaded(modelId) {
    return !!this.modelCache[modelId];
  }

  _addObject(obj) {
    const cached = this.modelCache[obj.modelId];
    if (!cached) {
      console.warn(`[ThreeBridge] No cached model for "${obj.modelId}" (object: ${obj.id}), using fallback box`);
      // Fallback: colored box with emissive for visibility
      const sx = obj.scaleX || 2;
      const sy = obj.scaleY || 2;
      const sz = obj.scaleZ || 2;
      const geometry = new THREE.BoxGeometry(sx, sy, sz);
      const baseColor = obj.fallbackColor || 0xff00ff;
      const material = new THREE.MeshStandardMaterial({
        color: baseColor,
        emissive: baseColor,
        emissiveIntensity: 0.15,
        roughness: 0.6,
      });
      const mesh = new THREE.Mesh(geometry, material);
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      mesh.position.set(obj.x, obj.y + sy / 2, obj.z);
      if (obj.rotY) mesh.rotation.y = obj.rotY;
      this.scene.add(mesh);
      this.objects[obj.id] = { mesh, mixer: null, actions: {}, currentAction: null, isFallback: true };
      return;
    }

    // Clone the model — use SkeletonUtils for skinned meshes
    let mesh;
    if (cached.hasSkeleton) {
      mesh = skeletonClone(cached.scene);
    } else {
      mesh = cached.scene.clone();
    }

    const sx = obj.scaleX || 1;
    const sy = obj.scaleY || 1;
    const sz = obj.scaleZ || 1;
    mesh.scale.set(sx, sy, sz);

    // Compute bounding box to center model on its lane and place ON ground
    const box = new THREE.Box3().setFromObject(mesh);
    const xCenter = (box.min.x + box.max.x) / 2;
    const yOffset = -box.min.y + 0.03;
    const zCenter = (box.min.z + box.max.z) / 2;

    // Use a pivot group so the model is centered at the lane position
    const pivot = new THREE.Group();

    if (obj.spanLanes && obj.laneWidth) {
      // Span all 3 lanes: place a copy in left, center, and right lanes
      const lw = obj.laneWidth;
      for (const laneX of [-lw, 0, lw]) {
        let copy;
        if (cached.hasSkeleton) {
          copy = skeletonClone(cached.scene);
        } else {
          copy = mesh.clone();
        }
        copy.scale.set(sx, sy, sz);
        copy.position.set(laneX - xCenter, yOffset, -zCenter);
        copy.traverse((child) => {
          if (child.isMesh) { child.castShadow = true; child.receiveShadow = true; }
        });
        pivot.add(copy);
      }
    } else {
      mesh.position.set(-xCenter, yOffset, -zCenter);
      pivot.add(mesh);
    }

    pivot.position.set(obj.x, obj.y, obj.z);
    if (obj.rotY !== undefined) pivot.rotation.y = obj.rotY;

    // Ensure shadow settings on cloned meshes
    mesh.traverse((child) => {
      if (child.isMesh) {
        child.castShadow = true;
        child.receiveShadow = true;
      }
    });

    // Animation mixer
    let mixer = null;
    const actions = {};
    if (cached.animations.length > 0) {
      mixer = new THREE.AnimationMixer(mesh);
      for (const clip of cached.animations) {
        actions[clip.name] = mixer.clipAction(clip);
      }
    }

    this.scene.add(pivot);
    this.objects[obj.id] = { mesh: pivot, mixer, actions, currentAction: null, isFallback: false };

    // Play initial animation
    if (obj.anim && actions[obj.anim]) {
      const action = actions[obj.anim];
      action.loop = obj.animLoop !== false ? THREE.LoopRepeat : THREE.LoopOnce;
      action.play();
      this.objects[obj.id].currentAction = obj.anim;
    } else if (obj.anim && Object.keys(actions).length > 0) {
      console.warn(`[ThreeBridge] Animation "${obj.anim}" not found for ${obj.id}. Available: [${Object.keys(actions).join(', ')}]`);
    }
  }

  _updateObject(obj, delta) {
    const entry = this.objects[obj.id];
    if (!entry) return;

    const mesh = entry.mesh;
    // For pivot groups, position is set directly (yOffset baked into child mesh)
    // For fallback boxes, yOffset is in userData
    const yOffset = mesh.userData.yOffset || 0;
    mesh.position.set(obj.x, obj.y + yOffset, obj.z);
    if (obj.rotY !== undefined) mesh.rotation.y = obj.rotY;
    if (obj.scaleX !== undefined) {
      mesh.scale.set(obj.scaleX, obj.scaleY || mesh.scale.y, obj.scaleZ || mesh.scale.z);
    }

    if (obj.visible !== undefined) {
      mesh.visible = obj.visible;
    }

    // Animation transition
    if (obj.anim !== undefined && obj.anim !== entry.currentAction) {
      if (entry.currentAction && entry.actions[entry.currentAction]) {
        entry.actions[entry.currentAction].fadeOut(0.2);
      }
      if (obj.anim && entry.actions[obj.anim]) {
        const action = entry.actions[obj.anim];
        action.reset();
        action.loop = obj.animLoop !== false ? THREE.LoopRepeat : THREE.LoopOnce;
        action.fadeIn(0.2);
        action.play();
      }
      entry.currentAction = obj.anim;
    }
  }

  _removeObject(id) {
    const entry = this.objects[id];
    if (!entry) return;

    if (entry.mixer) {
      entry.mixer.stopAllAction();
    }
    this.scene.remove(entry.mesh);

    // Only dispose geometry/materials that we OWN (fallback boxes).
    // Cloned GLTF models share geometry/materials with the cache —
    // disposing them corrupts all other instances of that model.
    // Pivot groups used for GLTF models should NOT dispose children.
    if (entry.isFallback) {
      entry.mesh.traverse((child) => {
        if (child.isMesh) {
          child.geometry?.dispose();
          if (child.material) {
            if (Array.isArray(child.material)) {
              child.material.forEach(m => m.dispose());
            } else {
              child.material.dispose();
            }
          }
        }
      });
    }

    delete this.objects[id];
  }

  _buildGround() {
    const groundGeo = new THREE.PlaneGeometry(60, 400);
    const groundMat = new THREE.MeshStandardMaterial({
      color: 0x2d2d3d,
      roughness: 0.9,
      metalness: 0.0,
      polygonOffset: true,
      polygonOffsetFactor: 2,
      polygonOffsetUnits: 2,
    });
    this.ground = new THREE.Mesh(groundGeo, groundMat);
    this.ground.rotation.x = -Math.PI / 2;
    this.ground.position.set(0, -0.05, 100);
    this.ground.receiveShadow = true;
    this.scene.add(this.ground);

    const laneWidth = 3.0;
    const roadWidth = laneWidth * 3;
    const roadGeo = new THREE.PlaneGeometry(roadWidth, 400);
    const roadMat = new THREE.MeshStandardMaterial({
      color: 0x1e1e2a,
      roughness: 0.8,
      metalness: 0.1,
      polygonOffset: true,
      polygonOffsetFactor: 1,
      polygonOffsetUnits: 1,
    });
    this.road = new THREE.Mesh(roadGeo, roadMat);
    this.road.rotation.x = -Math.PI / 2;
    this.road.position.set(0, -0.03, 100);
    this.road.receiveShadow = true;
    this.scene.add(this.road);

    // Lane divider lines
    const lineMat = new THREE.MeshBasicMaterial({ color: 0xcccccc });
    for (let i = -1; i <= 1; i += 2) {
      const x = i * laneWidth / 2;
      for (let z = 0; z < 400; z += 4) {
        const lineGeo = new THREE.PlaneGeometry(0.1, 1.5);
        const line = new THREE.Mesh(lineGeo, lineMat);
        line.rotation.x = -Math.PI / 2;
        line.position.set(x, 0.01, z);
        this.scene.add(line);
        this.laneLines.push(line);
      }
    }

    // Road edges
    const edgeMat = new THREE.MeshBasicMaterial({ color: 0xdddddd });
    for (const side of [-1, 1]) {
      const x = side * roadWidth / 2;
      const edgeGeo = new THREE.PlaneGeometry(0.1, 400);
      const edge = new THREE.Mesh(edgeGeo, edgeMat);
      edge.rotation.x = -Math.PI / 2;
      edge.position.set(x, 0.01, 100);
      this.scene.add(edge);
      this.roadEdges.push(edge);
    }
  }

  _buildWalkway() {
    const laneWidth = 3.0;
    const roadWidth = laneWidth * 3; // 9 units (-4.5 to +4.5)
    const roadHalf = roadWidth / 2;
    // Right walkway strip occupies lane +1 (center at +laneWidth = +3),
    // left walkway strip occupies lane -1 (center at -laneWidth = -3),
    // middle lane (lane 0) is left as plain road — the gap between walkways.
    const stripWidth = laneWidth - 0.2; // small inset
    // The Dart->scene X mapping negates worldX, so game-lane +1 (the player's
    // right) renders at scene_x = -laneWidth on screen. The walkway side
    // strips follow that same screen-relative orientation.
    const rightCenterX = -laneWidth; // visually right side of screen
    const leftCenterX = laneWidth;   // visually left side of screen

    // --- Clipping planes: restrict walkway geometry to a Z range ---
    this.walkwayClipStart = new THREE.Plane(new THREE.Vector3(0, 0, 1), 1000);
    this.walkwayClipEnd = new THREE.Plane(new THREE.Vector3(0, 0, -1), -1000);
    const clipPlanes = [this.walkwayClipStart, this.walkwayClipEnd];

    this.walkwayGroup = new THREE.Group();
    this.walkwayGroup.visible = true;

    // --- Outer side rails (along the outer edges of the road) ---
    const railMat = new THREE.MeshStandardMaterial({
      color: 0xaabbcc,
      roughness: 0.2,
      metalness: 0.8,
      clippingPlanes: clipPlanes,
    });
    const barMat = new THREE.MeshStandardMaterial({
      color: 0x445566,
      roughness: 0.1,
      metalness: 0.9,
      clippingPlanes: clipPlanes,
    });
    const postMat = new THREE.MeshStandardMaterial({
      color: 0x889aaa,
      roughness: 0.3,
      metalness: 0.7,
      clippingPlanes: clipPlanes,
    });
    // Outer rails (one per side of the whole road)
    for (const side of [-1, 1]) {
      const outerRail = new THREE.Mesh(
        new THREE.BoxGeometry(0.15, 1.2, 400),
        railMat,
      );
      outerRail.position.set(side * (roadHalf + 0.1), 0.6, 100);
      outerRail.castShadow = true;
      this.walkwayGroup.add(outerRail);

      const bar = new THREE.Mesh(
        new THREE.BoxGeometry(0.4, 0.08, 400),
        barMat,
      );
      bar.position.set(side * (roadHalf + 0.1), 1.2, 100);
      this.walkwayGroup.add(bar);

      for (let z = 0; z < 400; z += 8) {
        const post = new THREE.Mesh(
          new THREE.BoxGeometry(0.1, 1.2, 0.1),
          postMat,
        );
        post.position.set(side * (roadHalf + 0.1), 0.6, z);
        post.castShadow = true;
        this.walkwayGroup.add(post);
      }
    }
    // Inner divider rails — flank the central no-walkway gap
    for (const side of [-1, 1]) {
      const innerX = side * (laneWidth / 2);
      const innerRail = new THREE.Mesh(
        new THREE.BoxGeometry(0.12, 1.0, 400),
        railMat,
      );
      innerRail.position.set(innerX, 0.5, 100);
      innerRail.castShadow = true;
      this.walkwayGroup.add(innerRail);

      const innerBar = new THREE.Mesh(
        new THREE.BoxGeometry(0.3, 0.06, 400),
        barMat,
      );
      innerBar.position.set(innerX, 1.0, 100);
      this.walkwayGroup.add(innerBar);

      for (let z = 0; z < 400; z += 8) {
        const post = new THREE.Mesh(
          new THREE.BoxGeometry(0.08, 1.0, 0.08),
          postMat,
        );
        post.position.set(innerX, 0.5, z);
        post.castShadow = true;
        this.walkwayGroup.add(post);
      }
    }

    // --- Metal surface grooves on each strip (scroll independently) ---
    const grooveMat = new THREE.MeshBasicMaterial({
      color: 0x556677,
      clippingPlanes: clipPlanes,
    });
    for (let z = 0; z < 400; z += 1.5) {
      const grooveGeoR = new THREE.PlaneGeometry(stripWidth, 0.08);
      const grooveR = new THREE.Mesh(grooveGeoR, grooveMat);
      grooveR.rotation.x = -Math.PI / 2;
      grooveR.position.set(rightCenterX, 0.02, z);
      this.walkwayGroup.add(grooveR);
      this.walkwayGroovesRight.push(grooveR);

      const grooveL = new THREE.Mesh(grooveGeoR.clone(), grooveMat);
      grooveL.rotation.x = -Math.PI / 2;
      grooveL.position.set(leftCenterX, 0.02, z);
      this.walkwayGroup.add(grooveL);
      this.walkwayGroovesLeft.push(grooveL);
    }

    // --- Directional chevrons ---
    // Build a single forward-pointing chevron template; left strip uses
    // rotation.y = π on the wrapping group to flip it 180° around vertical
    // so it unambiguously points the opposite direction.
    const chevronRightMat = new THREE.MeshBasicMaterial({
      color: 0x88ffaa,
      transparent: true,
      opacity: 0.6,
      clippingPlanes: clipPlanes,
    });
    const chevronLeftMat = new THREE.MeshBasicMaterial({
      color: 0xff8888,
      transparent: true,
      opacity: 0.6,
      clippingPlanes: clipPlanes,
    });
    const armGeo = new THREE.PlaneGeometry(0.14, 1.6);
    const buildChevron = (mat, faceBackward) => {
      const group = new THREE.Group();
      const armL = new THREE.Mesh(armGeo.clone(), mat);
      armL.rotation.x = -Math.PI / 2;
      armL.rotation.z = 0.45;
      armL.position.set(-0.55, 0.025, 0);
      group.add(armL);
      const armR = new THREE.Mesh(armGeo.clone(), mat);
      armR.rotation.x = -Math.PI / 2;
      armR.rotation.z = -0.45;
      armR.position.set(0.55, 0.025, 0);
      group.add(armR);
      if (faceBackward) group.rotation.y = Math.PI;
      return group;
    };
    for (let z = 0; z < 400; z += 10) {
      const rChev = buildChevron(chevronRightMat, false);
      rChev.position.set(rightCenterX, 0, z);
      this.walkwayGroup.add(rChev);
      this.walkwayChevronsRight.push(rChev);

      const lChev = buildChevron(chevronLeftMat, true);
      lChev.position.set(leftCenterX, 0, z);
      this.walkwayGroup.add(lChev);
      this.walkwayChevronsLeft.push(lChev);
    }

    // --- Raised edge strips along the walkway perimeters ---
    const stripMat = new THREE.MeshStandardMaterial({
      color: 0x333333,
      roughness: 0.9,
      metalness: 0.0,
      clippingPlanes: clipPlanes,
    });
    for (const centerX of [leftCenterX, rightCenterX]) {
      for (const side of [-1, 1]) {
        const strip = new THREE.Mesh(
          new THREE.BoxGeometry(0.2, 0.06, 400),
          stripMat,
        );
        strip.position.set(centerX + side * (stripWidth / 2), 0.03, 100);
        this.walkwayGroup.add(strip);
      }
    }

    // --- Road overlays for each strip (only the strip changes color) ---
    const roadOverlayGeoR = new THREE.PlaneGeometry(stripWidth, 400);
    const roadOverlayMat = new THREE.MeshStandardMaterial({
      color: 0x6B7B8D,
      roughness: 0.3,
      metalness: 0.4,
      clippingPlanes: clipPlanes,
      polygonOffset: true,
      polygonOffsetFactor: -1,
      polygonOffsetUnits: -1,
    });
    this.walkwayRoadOverlayRight = new THREE.Mesh(roadOverlayGeoR, roadOverlayMat);
    this.walkwayRoadOverlayRight.rotation.x = -Math.PI / 2;
    this.walkwayRoadOverlayRight.position.set(rightCenterX, -0.01, 100);
    this.walkwayRoadOverlayRight.receiveShadow = true;
    this.walkwayGroup.add(this.walkwayRoadOverlayRight);

    this.walkwayRoadOverlayLeft = new THREE.Mesh(roadOverlayGeoR.clone(), roadOverlayMat);
    this.walkwayRoadOverlayLeft.rotation.x = -Math.PI / 2;
    this.walkwayRoadOverlayLeft.position.set(leftCenterX, -0.01, 100);
    this.walkwayRoadOverlayLeft.receiveShadow = true;
    this.walkwayGroup.add(this.walkwayRoadOverlayLeft);

    const groundOverlayGeo = new THREE.PlaneGeometry(60, 400);
    const groundOverlayMat = new THREE.MeshStandardMaterial({
      color: 0x3A3A4A,
      roughness: 0.9,
      metalness: 0.0,
      clippingPlanes: clipPlanes,
      polygonOffset: true,
      polygonOffsetFactor: -1,
      polygonOffsetUnits: -1,
    });
    this.walkwayGroundOverlay = new THREE.Mesh(groundOverlayGeo, groundOverlayMat);
    this.walkwayGroundOverlay.rotation.x = -Math.PI / 2;
    this.walkwayGroundOverlay.position.set(0, -0.02, 100);
    this.walkwayGroundOverlay.receiveShadow = true;
    this.walkwayGroup.add(this.walkwayGroundOverlay);

    this.scene.add(this.walkwayGroup);

    // --- Entry/exit ramp plates (only span the side strips, not the gap) ---
    const rampGeo = new THREE.BoxGeometry(roadWidth + 1.0, 0.12, 1.5);
    const rampMat = new THREE.MeshStandardMaterial({
      color: 0x667788,
      metalness: 0.6,
      roughness: 0.3,
    });
    this.walkwayEntryRamp = new THREE.Mesh(rampGeo, rampMat);
    this.walkwayEntryRamp.receiveShadow = true;
    this.walkwayEntryRamp.visible = false;
    this.scene.add(this.walkwayEntryRamp);

    this.walkwayExitRamp = new THREE.Mesh(rampGeo.clone(), rampMat.clone());
    this.walkwayExitRamp.receiveShadow = true;
    this.walkwayExitRamp.visible = false;
    this.scene.add(this.walkwayExitRamp);
  }

  _buildSky() {
    const skyGeo = new THREE.PlaneGeometry(400, 200);
    // Late-afternoon palette interpolated toward dusk by the daylight uniform.
    this.skyAfternoon = {
      top: new THREE.Color(0x3b3568),
      mid: new THREE.Color(0x7a4a6e),
      bottom: new THREE.Color(0xd17a45),
      horizon: new THREE.Color(0xffb066),
    };
    this.skyDusk = {
      top: new THREE.Color(0x0e0f26),
      mid: new THREE.Color(0x26143a),
      bottom: new THREE.Color(0x4a1830),
      horizon: new THREE.Color(0x7a2030),
    };
    const skyMat = new THREE.ShaderMaterial({
      uniforms: {
        topColor: { value: this.skyAfternoon.top.clone() },
        midColor: { value: this.skyAfternoon.mid.clone() },
        bottomColor: { value: this.skyAfternoon.bottom.clone() },
        horizonColor: { value: this.skyAfternoon.horizon.clone() },
      },
      vertexShader: `
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform vec3 topColor;
        uniform vec3 midColor;
        uniform vec3 bottomColor;
        uniform vec3 horizonColor;
        varying vec2 vUv;
        void main() {
          float t = vUv.y;
          vec3 color;
          if (t < 0.15) {
            color = mix(horizonColor, bottomColor, t / 0.15);
          } else if (t < 0.5) {
            color = mix(bottomColor, midColor, (t - 0.15) / 0.35);
          } else {
            color = mix(midColor, topColor, (t - 0.5) / 0.5);
          }
          gl_FragColor = vec4(color, 1.0);
        }
      `,
      side: THREE.DoubleSide,
      depthWrite: false,
    });
    this.skyDome = new THREE.Mesh(skyGeo, skyMat);
    this.skyDome.position.set(0, 60, 200);
    this.skyDome.renderOrder = -1;
    this.scene.add(this.skyDome);
  }

  /// Lerp sky colors and light intensities from late-afternoon (1.0) toward
  /// dusk (0.0). Driven by the park-closing timer so the world physically
  /// gets darker as the player runs out of time.
  _setDaylight(value) {
    const v = Math.max(0, Math.min(1, value));
    if (this.daylight === v) return;
    this.daylight = v;

    if (this.skyDome && this.skyAfternoon && this.skyDusk) {
      const u = this.skyDome.material.uniforms;
      u.topColor.value.copy(this.skyDusk.top).lerp(this.skyAfternoon.top, v);
      u.midColor.value.copy(this.skyDusk.mid).lerp(this.skyAfternoon.mid, v);
      u.bottomColor.value
        .copy(this.skyDusk.bottom)
        .lerp(this.skyAfternoon.bottom, v);
      u.horizonColor.value
        .copy(this.skyDusk.horizon)
        .lerp(this.skyAfternoon.horizon, v);
    }

    // Scale light intensities — keep a minimum so models stay legible at dusk.
    const lightFloor = 0.35;
    const k = lightFloor + v * (1.0 - lightFloor);
    if (this.ambientLight) this.ambientLight.intensity = 0.9 * k;
    if (this.directionalLight) this.directionalLight.intensity = 1.4 * k;
    if (this.hemiLight) this.hemiLight.intensity = 0.6 * k;
    if (this.fillLight) this.fillLight.intensity = 0.35 * k;

    // Renderer exposure dips slightly at dusk for an overall darker tone.
    if (this.renderer) {
      this.renderer.toneMappingExposure = 0.85 + v * 0.45;
    }
  }

  _updateZoneVisuals(zone) {
    // Only change base road/ground colors for non-walkway zones.
    // Walkway sections use clipped overlay planes for their colors.
    if (!zone.isWalkway) {
      if (this.ground && zone.groundColor) {
        this.ground.material.color.set(zone.groundColor);
      }
      if (this.road && zone.roadColor) {
        this.road.material.color.set(zone.roadColor);
        this.road.material.metalness = 0.1;
        this.road.material.roughness = 0.8;
      }
    }
    // Fog and ambient lighting are global atmosphere — always update
    if (this.scene.fog && zone.fogColor) {
      this.scene.fog.color.set(zone.fogColor);
    }
    if (this.ambientLight && zone.ambientColor) {
      this.ambientLight.color.set(zone.ambientColor);
    }
  }

  _updateWalkwayClipping(ranges) {
    if (!this.walkwayClipStart || !this.walkwayClipEnd) return;

    if (!ranges || ranges.length === 0) {
      // No walkway visible — clip everything out
      this.walkwayClipStart.constant = 1000;
      this.walkwayClipEnd.constant = -1000;
      if (this.walkwayEntryRamp) this.walkwayEntryRamp.visible = false;
      if (this.walkwayExitRamp) this.walkwayExitRamp.visible = false;
      return;
    }

    // Use the first visible walkway range
    const r = ranges[0];
    // Clamp to visible range to avoid rendering behind camera
    const startZ = Math.max(r.startZ, -5);
    const endZ = Math.min(r.endZ, 240);

    // Start clip: Z >= startZ  →  constant = -startZ
    this.walkwayClipStart.constant = -startZ;
    // End clip:   Z <= endZ    →  constant = endZ
    this.walkwayClipEnd.constant = endZ;

    // Position entry/exit ramp plates at the boundaries
    if (this.walkwayEntryRamp) {
      const entryVisible = r.startZ > -5 && r.startZ < 240;
      this.walkwayEntryRamp.visible = entryVisible;
      if (entryVisible) {
        this.walkwayEntryRamp.position.set(0, 0.06, r.startZ);
      }
    }
    if (this.walkwayExitRamp) {
      const exitVisible = r.endZ > -5 && r.endZ < 240;
      this.walkwayExitRamp.visible = exitVisible;
      if (exitVisible) {
        this.walkwayExitRamp.position.set(0, 0.06, r.endZ);
      }
    }
  }

  _scrollGround(offset) {
    for (const line of this.laneLines) {
      line.position.z = ((line.position.z - offset) % 400 + 400) % 400;
    }
  }

  _scrollWalkwayLanes(rightOffset, leftOffset) {
    if (!this.walkwayGroup || !this.walkwayGroup.visible) return;
    // Right strip: scroll grooves + chevrons toward camera (with player).
    for (const g of this.walkwayGroovesRight) {
      g.position.z = ((g.position.z - rightOffset) % 400 + 400) % 400;
    }
    for (const c of this.walkwayChevronsRight) {
      c.position.z = ((c.position.z - rightOffset) % 400 + 400) % 400;
    }
    // Left strip: scroll opposite. leftOffset is already negative from Dart.
    for (const g of this.walkwayGroovesLeft) {
      g.position.z = ((g.position.z - leftOffset) % 400 + 400) % 400;
    }
    for (const c of this.walkwayChevronsLeft) {
      c.position.z = ((c.position.z - leftOffset) % 400 + 400) % 400;
    }
  }
}

window.ThreeBridge = new ThreeBridgeClass();
