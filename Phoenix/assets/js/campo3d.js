// Escena 3D de fondo (Three.js): un suelo de partículas que respira y por el
// que viajan ondas sísmicas. Solo presentación; no usa datos del sistema.

import {
  BufferGeometry,
  Float32BufferAttribute,
  PerspectiveCamera,
  Plane,
  Points,
  Raycaster,
  Scene,
  ShaderMaterial,
  Vector2,
  Vector3,
  Vector4,
  WebGLRenderer,
} from "../vendor/three/three.module.js"

export const MAX_ONDAS = 8
export const EPICENTRO = {x: 5, z: -9}

const COLUMNAS = 230
const FILAS = 150
const ANCHO = 46
const Z_CERCA = 5
const Z_LEJOS = -34

const VERTICES = /* glsl */ `
  uniform float uT;
  uniform float uPunto;
  uniform float uAgitacion;
  uniform vec4 uOndas[${MAX_ONDAS}];
  varying float vOnda;
  varying float vProf;

  void main() {
    vec3 p = position;

    float base = uAgitacion *
      (0.22 * sin(p.x * 0.42 + uT * 0.45) * cos(p.z * 0.36 - uT * 0.3) +
      0.09 * sin(p.x * 1.05 - uT * 0.7 + p.z * 0.8));

    float onda = 0.0;
    for (int i = 0; i < ${MAX_ONDAS}; i++) {
      vec4 w = uOndas[i];
      if (w.w <= 0.0) continue;
      float edad = max(0.0, uT - w.z);
      float d = distance(p.xz, w.xy);
      float dd = d - edad * 3.6;
      onda += w.w * exp(-edad * 0.42) / (1.0 + d * 0.1) * exp(-dd * dd * 1.4) * cos(dd * 3.0);
    }

    p.y = base + onda;
    vOnda = abs(onda);

    vec4 mv = modelViewMatrix * vec4(p, 1.0);
    vProf = -mv.z;
    gl_Position = projectionMatrix * mv;
    gl_PointSize = uPunto * (1.0 + vOnda * 5.0) * (10.0 / vProf);
  }
`

const FRAGMENTOS = /* glsl */ `
  uniform vec3 uBase;
  uniform vec3 uAcento;
  uniform float uIntensidad;
  uniform float uTinte;
  varying float vOnda;
  varying float vProf;

  void main() {
    float r = length(gl_PointCoord - 0.5);
    if (r > 0.5) discard;

    float borde = smoothstep(0.5, 0.15, r);
    float niebla = smoothstep(36.0, 7.0, vProf) * smoothstep(1.5, 4.0, vProf);
    float m = clamp(vOnda * 6.0 + uTinte, 0.0, 1.0);

    gl_FragColor = vec4(mix(uBase, uAcento, m), borde * niebla * uIntensidad * (0.42 + 0.58 * m));
  }
`

// Convierte cualquier color CSS (los temas usan oklch) a RGB 0..1.
function aRGB(css) {
  const lienzo = document.createElement("canvas")
  lienzo.width = lienzo.height = 1
  const g = lienzo.getContext("2d", {willReadFrequently: true})
  g.fillStyle = css
  g.fillRect(0, 0, 1, 1)
  const d = g.getImageData(0, 0, 1, 1).data
  return new Vector3(d[0] / 255, d[1] / 255, d[2] / 255)
}

/**
 * Crea la escena sobre `lienzo`. Devuelve `null` si el navegador no tiene
 * WebGL: la app funciona igual, solo sin el fondo 3D.
 */
export function crearCampo(lienzo) {
  let render

  try {
    render = new WebGLRenderer({canvas: lienzo, alpha: true, antialias: true})
  } catch (_error) {
    return null
  }

  render.setClearColor(0x000000, 0)

  const escena = new Scene()
  const camara = new PerspectiveCamera(48, 1, 0.1, 80)
  const mirada = new Vector3(0, 0, -9)

  const posiciones = new Float32Array(COLUMNAS * FILAS * 3)
  let k = 0
  for (let f = 0; f < FILAS; f++) {
    for (let c = 0; c < COLUMNAS; c++) {
      posiciones[k++] = (c / (COLUMNAS - 1) - 0.5) * ANCHO
      posiciones[k++] = 0
      posiciones[k++] = Z_CERCA + (f / (FILAS - 1)) * (Z_LEJOS - Z_CERCA)
    }
  }

  const geometria = new BufferGeometry()
  geometria.setAttribute("position", new Float32BufferAttribute(posiciones, 3))

  const ondas = Array.from({length: MAX_ONDAS}, () => new Vector4(0, 0, 0, 0))

  const material = new ShaderMaterial({
    vertexShader: VERTICES,
    fragmentShader: FRAGMENTOS,
    transparent: true,
    depthWrite: false,
    depthTest: false,
    uniforms: {
      uT: {value: 0},
      uPunto: {value: 2},
      uIntensidad: {value: 0.5},
      uAgitacion: {value: 1},
      uTinte: {value: 0},
      uBase: {value: new Vector3(1, 1, 1)},
      uAcento: {value: new Vector3(1, 0.4, 0.1)},
      uOndas: {value: ondas},
    },
  })

  const puntos = new Points(geometria, material)
  puntos.frustumCulled = false
  escena.add(puntos)

  const rayo = new Raycaster()
  const suelo = new Plane(new Vector3(0, 1, 0), 0)
  const puntero = new Vector2()
  const impacto = new Vector3()

  return {
    medir() {
      const dpr = Math.min(devicePixelRatio || 1, 1.75)
      render.setPixelRatio(dpr)
      render.setSize(innerWidth, innerHeight, false)
      camara.aspect = innerWidth / innerHeight
      camara.updateProjectionMatrix()
      material.uniforms.uPunto.value = 2.5 * dpr * Math.max(0.7, innerHeight / 900)
    },

    colores(base, acento) {
      material.uniforms.uBase.value = aRGB(base)
      material.uniforms.uAcento.value = aRGB(acento)
    },

    /** Punto del suelo bajo una posición de pantalla, o `null` si mira al cielo. */
    alSuelo(clienteX, clienteY) {
      puntero.set((clienteX / innerWidth) * 2 - 1, -(clienteY / innerHeight) * 2 + 1)
      rayo.setFromCamera(puntero, camara)
      const p = rayo.ray.intersectPlane(suelo, impacto)
      if (!p || p.z < Z_LEJOS || Math.abs(p.x) > ANCHO) return null
      return {x: p.x, z: p.z}
    },

    dibujar(t, estado) {
      for (let i = 0; i < MAX_ONDAS; i++) {
        const q = estado.ondas[i]
        if (q) ondas[i].set(q.x, q.z, q.t, q.a)
        else ondas[i].set(0, 0, 0, 0)
      }

      material.uniforms.uT.value = t
      material.uniforms.uIntensidad.value = estado.intensidad
      material.uniforms.uAgitacion.value = estado.agitacion
      material.uniforms.uTinte.value = estado.tinte

      // La cámara flota muy despacio y acompaña al puntero. `vuelo` la aleja y
      // eleva (> 0, llegada al panel) o la lanza hacia delante (< 0, al conectar).
      const v = estado.vuelo
      camara.position.set(
        (estado.sx - 0.5) * 2.4 + Math.sin(t * 0.11) * 0.6,
        2.7 + (0.5 - estado.sy) * 0.7 + Math.sin(t * 0.17) * 0.12 + v * (v > 0 ? 3 : 1.3),
        8 + v * (v > 0 ? 9 : 5.5),
      )
      camara.lookAt(mirada)
      render.render(escena, camara)
    },
  }
}
