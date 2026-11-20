import * as THREE from 'three';
import { advanceProbe } from './core/smoke.js';

const scene = new THREE.Scene();
scene.background = new THREE.Color('#112333');
const camera = new THREE.PerspectiveCamera(60, innerWidth / innerHeight, 0.1, 100);
camera.position.set(0, 1.5, 4);
camera.lookAt(0, 0, 0);
const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
document.body.appendChild(renderer.domElement);
const cube = new THREE.Mesh(new THREE.BoxGeometry(), new THREE.MeshNormalMaterial());
scene.add(cube);
let state = { angle: 0 };
let previous;
renderer.setAnimationLoop((now) => {
  state = advanceProbe(state, previous === undefined ? 0 : Math.min((now - previous) / 1000, 0.1));
  previous = now;
  cube.rotation.y = state.angle;
  cube.rotation.x = state.angle * 0.4;
  renderer.render(scene, camera);
});
addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});
