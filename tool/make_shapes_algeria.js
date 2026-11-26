// The Algeria book's 3D models, built from simple shapes (used by
// tool/make_shapes.html). Each model is a Group standing on a ground base,
// with one named child Group per part ("crescent", "minaret"...), so
// make_shapes can measure where each part is.
import * as THREE from 'three';

const std = (color, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.7, ...extra });
const mesh = (geo, mat, x = 0, y = 0, z = 0) => { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); return m; };
function part(name, ...children) { const g = new THREE.Group(); g.name = name; g.add(...children); return g; }
function ground(r, color = 0xe8cf9c, h = 0.08) {
  const g = mesh(new THREE.CylinderGeometry(r, r * 1.03, h, 48), std(color), 0, h / 2, 0);
  g.name = 'ground';
  return g;
}
const G = 0.08; // ground height
let seed = 7;
const rand = () => ((seed = (seed * 16807) % 2147483647) / 2147483647); // same models every run

function extrude(shape, depth, mat, bevel = 0.02) {
  const geo = new THREE.ExtrudeGeometry(shape, { depth, bevelEnabled: bevel > 0, bevelThickness: bevel, bevelSize: bevel, bevelSegments: 2, curveSegments: 24 });
  geo.translate(0, 0, -depth / 2);
  return new THREE.Mesh(geo, mat);
}
function starShape(r1, r2) {
  const s = new THREE.Shape();
  for (let i = 0; i < 10; i++) {
    const r = i % 2 ? r2 : r1, a = Math.PI / 2 + (i * Math.PI) / 5;
    i ? s.lineTo(Math.cos(a) * r, Math.sin(a) * r) : s.moveTo(Math.cos(a) * r, Math.sin(a) * r);
  }
  return s;
}
function canvasTexture(w, h, draw) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  draw(c.getContext('2d'));
  const t = new THREE.CanvasTexture(c);
  t.colorSpace = THREE.SRGBColorSpace;
  return t;
}

export const ALGERIA = {
  flag() {
    const g = new THREE.Group();
    g.add(ground(0.75, 0x7cb26a));
    const pole = part('pole', mesh(new THREE.CylinderGeometry(0.03, 0.035, 2.3, 16), std(0xd9d9d9, { metalness: 0.5, roughness: 0.3 }), -0.72, G + 1.15, 0),
      mesh(new THREE.SphereGeometry(0.06, 16, 12), std(0xf2c14e, { metalness: 0.6 }), -0.72, G + 2.32, 0));
    // the cloth, gently waving: green half at the pole, white half outside
    const w = 1.4, h = 0.94;
    const tex = canvasTexture(512, 344, (c) => {
      c.fillStyle = '#006233'; c.fillRect(0, 0, 256, 344);
      c.fillStyle = '#ffffff'; c.fillRect(256, 0, 256, 344);
    });
    const geo = new THREE.PlaneGeometry(w, h, 24, 8);
    const pos = geo.attributes.position;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i) + w / 2;
      pos.setZ(i, Math.sin(x * 4.2) * 0.06 * (x / w));
    }
    geo.computeVertexNormals();
    const cloth = mesh(geo, new THREE.MeshStandardMaterial({ map: tex, side: THREE.DoubleSide, roughness: 0.8 }), -0.72 + w / 2, G + 2.25 - h / 2, 0);
    cloth.name = 'cloth';
    const red = std(0xd21034, { roughness: 0.5 });
    // crescent: a circle minus an offset circle
    const cr = new THREE.Shape(); cr.absarc(0, 0, 0.24, 0, Math.PI * 2, false);
    const hole = new THREE.Path(); hole.absarc(0.07, 0, 0.2, 0, Math.PI * 2, true); cr.holes.push(hole);
    const cx = -0.72 + w / 2, cy = G + 2.25 - h / 2, zf = 0.07 * 0.5 + 0.03;
    const crescent = part('crescent', extrude(cr, 0.03, red, 0.005));
    crescent.position.set(cx - 0.02, cy, zf);
    const star = part('star', extrude(starShape(0.12, 0.05), 0.03, red, 0.005));
    star.position.set(cx + 0.13, cy, zf);
    star.rotation.z = -0.3;
    g.add(pole, cloth, crescent, star);
    return g;
  },

  memorial() {
    const g = new THREE.Group();
    g.add(ground(0.95, 0xd9c7a7));
    const stone = std(0xeee5d6, { roughness: 0.85 });
    const base = part('base', mesh(new THREE.CylinderGeometry(0.62, 0.7, 0.22, 3), std(0xbfae93), 0, G + 0.11, 0));
    g.add(base);
    // three leaning palm leaves meeting high up
    const leaves = new THREE.Group(); leaves.name = 'leaf';
    for (let i = 0; i < 3; i++) {
      const a = (i * Math.PI * 2) / 3 + Math.PI / 6;
      const s = new THREE.Shape();
      s.moveTo(-0.16, 0); s.quadraticCurveTo(-0.2, 1.4, -0.02, 2.5); s.lineTo(0.06, 2.5); s.quadraticCurveTo(0.12, 1.4, 0.16, 0); s.closePath();
      const leaf = extrude(s, 0.07, stone, 0.01);
      const holder = new THREE.Group();
      holder.add(leaf);
      leaf.rotation.x = -0.16; // lean in
      leaf.position.z = 0.48;
      holder.rotation.y = a;
      holder.position.y = G + 0.2;
      leaves.add(holder);
    }
    g.add(leaves);
    const ring = mesh(new THREE.TorusGeometry(0.16, 0.035, 10, 30), stone, 0, G + 2.4, 0);
    ring.rotation.x = Math.PI / 2;
    g.add(ring);
    const flame = part('flame', mesh(new THREE.ConeGeometry(0.09, 0.3, 16), std(0xff8a00, { emissive: 0xff5a00, emissiveIntensity: 0.6 }), 0, G + 0.38, 0),
      mesh(new THREE.CylinderGeometry(0.12, 0.14, 0.12, 16), std(0x6d5d4b), 0, G + 0.27, 0));
    g.add(flame);
    return g;
  },

  mosque() {
    const g = new THREE.Group();
    g.add(ground(1.25, 0xe3dccf));
    const white = std(0xf7f4ee, { roughness: 0.6 });
    const minaret = part('minaret',
      mesh(new THREE.BoxGeometry(0.34, 2.6, 0.34), white, -0.75, G + 1.3, -0.2),
      mesh(new THREE.BoxGeometry(0.4, 0.1, 0.4), std(0x00897b), -0.75, G + 2.62, -0.2),
      mesh(new THREE.BoxGeometry(0.26, 0.3, 0.26), white, -0.75, G + 2.82, -0.2),
      mesh(new THREE.ConeGeometry(0.06, 0.25, 12), std(0xd4af37, { metalness: 0.6 }), -0.75, G + 3.1, -0.2));
    const hall = mesh(new THREE.BoxGeometry(1.3, 0.55, 1.1), white, 0.3, G + 0.275, 0);
    const dome = part('dome', mesh(new THREE.SphereGeometry(0.42, 32, 16, 0, Math.PI * 2, 0, Math.PI / 2), std(0x00897b, { roughness: 0.4 }), 0.3, G + 0.55, 0),
      mesh(new THREE.CylinderGeometry(0.44, 0.44, 0.1, 32), white, 0.3, G + 0.6, 0));
    dome.children[0].position.y = G + 0.65;
    // a row of arches on the front
    const arches = new THREE.Group(); arches.name = 'arches';
    const dark = std(0x5b6b74);
    for (let i = 0; i < 5; i++) {
      const s = new THREE.Shape(); s.moveTo(-0.08, 0); s.lineTo(-0.08, 0.22); s.absarc(0, 0.22, 0.08, Math.PI, 0, true); s.lineTo(0.08, 0); s.closePath();
      const a = extrude(s, 0.02, dark, 0);
      a.position.set(-0.22 + i * 0.26, G + 0.06, 0.56);
      arches.add(a);
    }
    g.add(minaret, hall, dome, arches);
    return g;
  },

  casbah() {
    const g = new THREE.Group();
    g.add(ground(1.2, 0xd8cfc0));
    const sea = part('sea', mesh(new THREE.BoxGeometry(2.2, 0.04, 0.55), std(0x2f86d6, { roughness: 0.2 }), 0, G + 0.02, 0.8));
    const houses = new THREE.Group(); houses.name = 'house';
    const white = std(0xfbfbf8, { roughness: 0.75 }), win = std(0x3c6e9e);
    const rows = [[-0.8, -0.35, 0.1, 0.45, 0.8], [-0.6, -0.1, 0.35, 0.7], [-0.4, 0.1, 0.5], [-0.1, 0.3]];
    rows.forEach((xs, r) => {
      xs.forEach((x, k) => {
        const h = 0.3 + ((r + k) % 3) * 0.08, z = 0.35 - r * 0.32;
        const box = mesh(new THREE.BoxGeometry(0.34, h, 0.3), white, x, G + r * 0.22 + h / 2, z);
        houses.add(box, mesh(new THREE.BoxGeometry(0.08, 0.1, 0.01), win, x, G + r * 0.22 + h * 0.6, z + 0.155));
      });
    });
    // the terraces climb: a stone base under each row
    for (let r = 1; r < 4; r++) houses.add(mesh(new THREE.BoxGeometry(2.0 - r * 0.3, r * 0.22, 0.3), std(0xe2d8c8), 0, G + r * 0.11, 0.35 - r * 0.32));
    const stairs = new THREE.Group(); stairs.name = 'stairs';
    for (let i = 0; i < 6; i++) stairs.add(mesh(new THREE.BoxGeometry(0.16, 0.06, 0.1), std(0xc9b79c), 0.98, G + 0.03 + i * 0.07, 0.4 - i * 0.12));
    g.add(sea, houses, stairs);
    return g;
  },

  timgad() {
    const g = new THREE.Group();
    g.add(ground(1.15, 0xe2c48f));
    const stone = std(0xd9a865, { roughness: 0.9 });
    const s = new THREE.Shape();
    s.moveTo(-0.9, 0); s.lineTo(0.9, 0); s.lineTo(0.9, 1.3); s.lineTo(-0.9, 1.3); s.closePath();
    const hole = (cx, w, h) => { const p = new THREE.Path(); p.moveTo(cx - w / 2, 0); p.lineTo(cx - w / 2, h - w / 2); p.absarc(cx, h - w / 2, w / 2, Math.PI, 0, true); p.lineTo(cx + w / 2, 0); p.closePath(); return p; };
    s.holes.push(hole(0, 0.42, 0.95), hole(-0.58, 0.24, 0.6), hole(0.58, 0.24, 0.6));
    const arch = part('arch', extrude(s, 0.36, stone, 0.01));
    arch.position.y = G;
    const columns = new THREE.Group(); columns.name = 'column';
    for (const x of [-0.32, 0.32, -0.82, 0.82]) {
      columns.add(mesh(new THREE.CylinderGeometry(0.06, 0.07, 1.05, 16), std(0xe8c99a), x, G + 0.525, 0.26));
      columns.add(mesh(new THREE.BoxGeometry(0.17, 0.06, 0.17), std(0xe8c99a), x, G + 1.08, 0.26));
    }
    // a broken column lying in front
    const fallen = mesh(new THREE.CylinderGeometry(0.06, 0.06, 0.5, 14), std(0xe8c99a), 0.5, G + 0.06, 0.75);
    fallen.rotation.z = Math.PI / 2;
    g.add(arch, columns, fallen);
    return g;
  },

  ghardaia() {
    const g = new THREE.Group();
    g.add(ground(1.2, 0xe2b979));
    const hill = part('hill', mesh(new THREE.ConeGeometry(1.05, 0.9, 40), std(0xd7a35f, { roughness: 1 }), 0, G + 0.45, 0));
    const houses = new THREE.Group(); houses.name = 'house';
    const pastel = [0xf3d9b1, 0x9fd3e6, 0xf5f0e6, 0xe8b4a0, 0xbfe0c4];
    let n = 0;
    for (const [ring, y, count] of [[0.85, 0.12, 12], [0.6, 0.35, 9], [0.38, 0.55, 6]]) {
      for (let k = 0; k < count; k++) {
        const a = (k / count) * Math.PI * 2 + ring;
        houses.add(mesh(new THREE.BoxGeometry(0.2, 0.2, 0.2), std(pastel[n++ % pastel.length]), Math.cos(a) * ring, G + y + 0.08, Math.sin(a) * ring));
      }
    }
    // the M'zab minaret: a tapering square tower with four points on top
    const tower = new THREE.CylinderGeometry(0.07, 0.15, 0.9, 4);
    tower.rotateY(Math.PI / 4);
    const minaret = part('minaret', mesh(tower, std(0xe9c48c), 0, G + 1.15, 0));
    for (const [x, z] of [[0.05, 0.05], [-0.05, 0.05], [0.05, -0.05], [-0.05, -0.05]]) {
      minaret.add(mesh(new THREE.ConeGeometry(0.025, 0.1, 6), std(0xe9c48c), x, G + 1.65, z));
    }
    g.add(hill, houses, minaret);
    return g;
  },

  tassili() {
    const g = new THREE.Group();
    const sand = part('sand', ground(1.2, 0xe9b56f));
    for (const [x, z, s] of [[-0.7, 0.6, 0.35], [0.6, 0.7, 0.3], [0.9, -0.2, 0.4]]) {
      const d = mesh(new THREE.SphereGeometry(s, 24, 12), std(0xedbd78, { roughness: 1 }), x, G, z);
      d.scale.y = 0.35;
      sand.add(d);
    }
    const rocks = new THREE.Group(); rocks.name = 'rock';
    const red = std(0xa4522f, { roughness: 1, flatShading: true });
    for (const [x, z, h, w] of [[-0.45, -0.3, 1.5, 0.45], [0.15, -0.45, 1.1, 0.4], [0.55, -0.1, 0.8, 0.35], [-0.85, 0.1, 0.7, 0.3]]) {
      const r = mesh(new THREE.DodecahedronGeometry(1, 0), red, x, G + h / 2, z);
      r.scale.set(w, h / 2, w * 0.9);
      r.rotation.y = x * 3;
      rocks.add(r);
    }
    // an old painting of a giraffe and a man on a flat stone
    const tex = canvasTexture(256, 160, (c) => {
      c.fillStyle = '#c47a4a'; c.fillRect(0, 0, 256, 160);
      c.strokeStyle = '#f3e2c4'; c.fillStyle = '#f3e2c4'; c.lineWidth = 6; c.lineCap = 'round';
      c.beginPath(); c.ellipse(110, 95, 35, 16, 0, 0, Math.PI * 2); c.fill();
      c.beginPath(); c.moveTo(138, 88); c.lineTo(165, 30); c.lineTo(180, 32); c.stroke();
      for (const x of [85, 100, 120, 135]) { c.beginPath(); c.moveTo(x, 105); c.lineTo(x, 140); c.stroke(); }
      c.beginPath(); c.arc(45, 55, 9, 0, Math.PI * 2); c.fill();
      c.beginPath(); c.moveTo(45, 64); c.lineTo(45, 105); c.moveTo(45, 75); c.lineTo(28, 90); c.moveTo(45, 75); c.lineTo(62, 88);
      c.moveTo(45, 105); c.lineTo(33, 135); c.moveTo(45, 105); c.lineTo(57, 135); c.stroke();
    });
    const slab = mesh(new THREE.BoxGeometry(0.7, 0.45, 0.06), std(0xa4522f, { roughness: 1 }), 0, G + 0.3, 0.45);
    slab.rotation.x = -0.25;
    const pic = mesh(new THREE.PlaneGeometry(0.62, 0.38), new THREE.MeshStandardMaterial({ map: tex, roughness: 1 }), 0, 0, 0.031);
    slab.add(pic);
    const painting = part('painting', slab);
    g.add(sand, rocks, painting);
    return g;
  },

  palm() {
    const g = new THREE.Group();
    g.add(ground(0.8, 0xe6c58c));
    const trunk = new THREE.Group(); trunk.name = 'trunk';
    const bark = std(0x8b6239, { roughness: 1 });
    for (let i = 0; i < 12; i++) {
      const seg = mesh(new THREE.CylinderGeometry(0.1 - i * 0.003, 0.12 - i * 0.003, 0.2, 10), bark, Math.sin(i * 0.18) * 0.12, G + 0.1 + i * 0.19, 0);
      seg.rotation.z = -0.05;
      trunk.add(seg);
    }
    const top = new THREE.Vector3(Math.sin(11 * 0.18) * 0.12, G + 2.35, 0);
    const fronds = new THREE.Group(); fronds.name = 'fronds';
    const green = std(0x4f8f3a, { side: THREE.DoubleSide });
    for (let i = 0; i < 9; i++) {
      const a = (i / 9) * Math.PI * 2;
      const s = new THREE.Shape(); s.moveTo(0, -0.06); s.quadraticCurveTo(0.55, -0.1, 1.0, -0.02); s.quadraticCurveTo(0.55, 0.12, 0, 0.06); s.closePath();
      const leaf = new THREE.Mesh(new THREE.ShapeGeometry(s, 12), green);
      const holder = new THREE.Group();
      holder.add(leaf);
      leaf.rotation.x = Math.PI / 2;
      leaf.rotation.y = 0.45 + (i % 2) * 0.25; // droop
      holder.rotation.y = a;
      holder.position.copy(top);
      fronds.add(holder);
    }
    const dates = new THREE.Group(); dates.name = 'dates';
    const date = std(0xb5651d, { roughness: 0.4 });
    for (const a of [0.4, 2.5, 4.4]) {
      for (let k = 0; k < 14; k++) {
        dates.add(mesh(new THREE.SphereGeometry(0.035, 10, 8), date,
          top.x + Math.cos(a) * 0.17 + (rand() - 0.5) * 0.1, top.y - 0.18 - (k % 5) * 0.05, top.z + Math.sin(a) * 0.17 + (rand() - 0.5) * 0.1));
      }
    }
    g.add(trunk, fronds, dates);
    return g;
  },

  couscous() {
    const g = new THREE.Group();
    const plate = part('plate', mesh(new THREE.LatheGeometry([new THREE.Vector2(0, 0), new THREE.Vector2(0.9, 0), new THREE.Vector2(1.0, 0.1), new THREE.Vector2(1.05, 0.22), new THREE.Vector2(0.98, 0.22), new THREE.Vector2(0.88, 0.1), new THREE.Vector2(0, 0.08)], 48), std(0x1f5f99, { roughness: 0.35 })));
    const rim = mesh(new THREE.TorusGeometry(1.02, 0.025, 8, 48), std(0xf2c14e, { metalness: 0.4 }), 0, 0.22, 0);
    rim.rotation.x = Math.PI / 2;
    plate.add(rim);
    const mound = new THREE.SphereGeometry(0.8, 48, 24, 0, Math.PI * 2, 0, Math.PI / 2);
    const pos = mound.attributes.position;
    for (let i = 0; i < pos.count; i++) pos.setY(i, pos.getY(i) * 0.55 + (rand() - 0.5) * 0.015);
    mound.computeVertexNormals();
    const grains = part('grains', mesh(mound, std(0xf0cf7a, { roughness: 1 }), 0, 0.08, 0));
    const carrot = new THREE.Group(); carrot.name = 'carrot';
    for (let i = 0; i < 5; i++) {
      const a = (i / 5) * Math.PI * 2;
      const c = mesh(new THREE.ConeGeometry(0.07, 0.55, 12), std(0xf07c1b), Math.cos(a) * 0.12, 0.56, Math.sin(a) * 0.12);
      c.rotation.set(Math.sin(a) * 0.5, 0, -Math.cos(a) * 0.5);
      carrot.add(c);
    }
    const chickpeas = new THREE.Group(); chickpeas.name = 'chickpeas';
    for (let i = 0; i < 18; i++) {
      const a = rand() * Math.PI * 2, r = 0.25 + rand() * 0.4;
      const y = 0.08 + 0.44 * Math.sqrt(Math.max(0, 1 - (r / 0.8) ** 2));
      chickpeas.add(mesh(new THREE.SphereGeometry(0.045, 10, 8), std(0xe8d3a0), Math.cos(a) * r, y + 0.02, Math.sin(a) * r));
    }
    g.add(plate, grains, carrot, chickpeas);
    return g;
  },

  tea() {
    const g = new THREE.Group();
    const silver = std(0xd7d7d7, { metalness: 0.85, roughness: 0.25 });
    const tray = part('tray', mesh(new THREE.CylinderGeometry(1.0, 1.0, 0.04, 48), silver, 0, 0.02, 0));
    const rimT = mesh(new THREE.TorusGeometry(1.0, 0.03, 8, 48), silver, 0, 0.05, 0);
    rimT.rotation.x = Math.PI / 2;
    tray.add(rimT);
    const pot = new THREE.Group(); pot.name = 'teapot';
    const body = mesh(new THREE.LatheGeometry([new THREE.Vector2(0, 0), new THREE.Vector2(0.2, 0), new THREE.Vector2(0.3, 0.12), new THREE.Vector2(0.32, 0.25), new THREE.Vector2(0.24, 0.42), new THREE.Vector2(0.14, 0.5), new THREE.Vector2(0, 0.5)], 32), silver, -0.3, 0.04, -0.15);
    const lid = mesh(new THREE.ConeGeometry(0.15, 0.22, 24), silver, -0.3, 0.65, -0.15);
    const knob = mesh(new THREE.SphereGeometry(0.04, 12, 8), silver, -0.3, 0.78, -0.15);
    const spout = mesh(new THREE.CylinderGeometry(0.025, 0.05, 0.45, 12), silver, 0.02, 0.38, -0.15);
    spout.rotation.z = -0.9;
    const handle = mesh(new THREE.TorusGeometry(0.15, 0.025, 8, 20, Math.PI), silver, -0.6, 0.32, -0.15);
    handle.rotation.z = Math.PI / 2;
    pot.add(body, lid, knob, spout, handle);
    const glasses = new THREE.Group(); glasses.name = 'glass';
    const glassMat = new THREE.MeshStandardMaterial({ color: 0xb8e0d8, transparent: true, opacity: 0.55, roughness: 0.1 });
    const teaMat = std(0xa0521d, { roughness: 0.3 });
    for (const [x, z] of [[0.35, 0.3], [0.62, 0.0], [0.15, 0.6]]) {
      glasses.add(mesh(new THREE.CylinderGeometry(0.09, 0.07, 0.24, 20, 1, true), glassMat, x, 0.16, z));
      glasses.add(mesh(new THREE.CylinderGeometry(0.083, 0.068, 0.18, 20), teaMat, x, 0.13, z));
    }
    const mint = new THREE.Group(); mint.name = 'mint';
    const leafMat = std(0x3c9a3c);
    for (let i = 0; i < 7; i++) {
      const l = mesh(new THREE.SphereGeometry(0.07, 12, 8), leafMat, -0.45 + (i % 3) * 0.09, 0.08, 0.45 + Math.floor(i / 3) * 0.08);
      l.scale.set(1, 0.25, 0.6);
      l.rotation.y = i;
      mint.add(l);
    }
    g.add(tray, pot, glasses, mint);
    return g;
  },
};
