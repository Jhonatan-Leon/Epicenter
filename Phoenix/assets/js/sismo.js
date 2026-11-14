// Efectos visuales de Epicenter.
//
// Solo presentación: este archivo no lee ni modifica datos del sistema ni
// eventos de LiveView. Coordina la escena 3D de fondo (campo3d.js), la traza
// del sismógrafo de la barra superior y las microinteracciones (foco,
// inclinación, conteo).
//
// Nada de lo que se dibuja aquí es una medición real: el fondo y la traza
// reaccionan a la actividad de la interfaz (clics, envíos, avisos).

import {crearCampo, EPICENTRO, MAX_ONDAS} from "./campo3d"

const CLAVE_MOVIMIENTO = "epicenter:movimiento"
const CLAVE_ENTRADA = "epicenter:entrada"
const VIDA_ONDA = 9

// Cómo se comporta el fondo según el nivel de afectación que la pantalla ya
// muestra (atributo `data-sx-nivel`): cada cuánto late el epicentro, con qué
// fuerza, cuánto se agita el suelo y cuánto se tiñe del color de acento.
const NIVELES = {
  critico: {cada: 2.2, fuerza: 0.8, agitacion: 1.7, tinte: 0.2},
  alto: {cada: 3.6, fuerza: 0.62, agitacion: 1.3, tinte: 0.1},
  medio: {cada: 5.2, fuerza: 0.5, agitacion: 1, tinte: 0.03},
  bajo: {cada: 8.5, fuerza: 0.32, agitacion: 0.65, tinte: 0},
}
const NIVEL_NEUTRO = {cada: 6, fuerza: 0.5, agitacion: 1, tinte: 0}

function nivelEnPantalla() {
  const el = document.querySelector("[data-sx-nivel]")
  return (el && NIVELES[el.dataset.sxNivel]) || NIVEL_NEUTRO
}

// El movimiento lo decide la persona con el botón de la barra (se guarda en el
// navegador). Por defecto está activo.
const quieto = () => document.documentElement.dataset.movimiento === "reducido"

const E = {
  energia: 0,
  ondas: [],
  px: 0.5,
  py: 0.5,
  sx: 0.5,
  sy: 0.5,
  intensidad: 0.5,
  t: 0,
  agitacion: 1,
  tinte: 0,
  vuelo: 0,
  vueloObjetivo: 0,
  linea: "#d8dce4",
  acento: "#ef6a2c",
}

let campo = null

// ---------------------------------------------------------------------------
// Colores del tema (se leen de las variables de daisyUI, no se definen aquí)
// ---------------------------------------------------------------------------

function leerColores() {
  const estilo = getComputedStyle(document.documentElement)
  E.linea = estilo.getPropertyValue("--color-base-content").trim() || E.linea
  E.acento = estilo.getPropertyValue("--color-primary").trim() || E.acento
  if (campo) campo.colores(E.linea, E.acento)
}

// ---------------------------------------------------------------------------
// Traza del sismógrafo (barra superior)
// ---------------------------------------------------------------------------

const TRAZA = new Float32Array(140)
let cursorTraza = 0
let acumulado = 0

function avanzarTraza(dt, t) {
  acumulado += dt
  while (acumulado > 0.02) {
    acumulado -= 0.02
    const ruido = (Math.sin(t * 9.1) + Math.sin(t * 23.7)) * 0.03
    TRAZA[cursorTraza] = ruido + E.energia * (Math.random() * 2 - 1) * 0.9
    cursorTraza = (cursorTraza + 1) % TRAZA.length
    E.energia *= 0.93
  }
}

function dibujarTraza() {
  const lienzo = document.getElementById("sx-sismografo")
  if (!lienzo || !lienzo.clientWidth) return

  const dpr = Math.min(devicePixelRatio || 1, 2)
  const w = lienzo.clientWidth
  const h = lienzo.clientHeight
  if (lienzo.width !== Math.round(w * dpr)) {
    lienzo.width = Math.round(w * dpr)
    lienzo.height = Math.round(h * dpr)
  }

  const ctx = lienzo.getContext("2d")
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  ctx.clearRect(0, 0, w, h)

  ctx.globalAlpha = 0.18
  ctx.strokeStyle = E.linea
  ctx.lineWidth = 1
  ctx.beginPath()
  ctx.moveTo(0, h / 2)
  ctx.lineTo(w, h / 2)
  ctx.stroke()

  ctx.globalAlpha = 1
  ctx.strokeStyle = E.acento
  ctx.lineWidth = 1.4
  ctx.lineJoin = "round"
  ctx.beginPath()
  const n = TRAZA.length
  let ultimoY = h / 2
  for (let i = 0; i < n; i++) {
    const v = TRAZA[(cursorTraza + i) % n]
    const x = (i / (n - 1)) * (w - 4)
    ultimoY = h / 2 - Math.max(-1, Math.min(1, v)) * (h / 2 - 2)
    if (i === 0) ctx.moveTo(x, ultimoY)
    else ctx.lineTo(x, ultimoY)
  }
  ctx.stroke()

  ctx.fillStyle = E.acento
  ctx.beginPath()
  ctx.arc(w - 3, ultimoY, 2.2, 0, Math.PI * 2)
  ctx.fill()
}

// ---------------------------------------------------------------------------
// Pulsos
// ---------------------------------------------------------------------------

function emitirOnda(x, z, amplitud) {
  if (quieto()) return
  E.ondas.push({x, z, a: amplitud, t: E.t})
  if (E.ondas.length > MAX_ONDAS) E.ondas.shift()
}

function pulso(fuerza) {
  E.energia = Math.min(1.6, E.energia + fuerza)
  emitirOnda(EPICENTRO.x, EPICENTRO.z, 0.35 + 0.45 * fuerza)
}

function anilloEnPantalla(x, y) {
  if (quieto()) return
  const anillo = document.createElement("span")
  anillo.className = "sx-onda"
  anillo.style.left = `${x}px`
  anillo.style.top = `${y}px`
  anillo.addEventListener("animationend", () => anillo.remove())
  document.body.appendChild(anillo)
}

// ---------------------------------------------------------------------------
// Conteo animado de cifras (`data-conteo`)
// ---------------------------------------------------------------------------

function contar(el) {
  const final = el.dataset.conteo ?? ""
  el._sxConteo = final
  if (quieto() || !/\d/.test(final)) return

  const partes = final.split(/(\d+)/)
  const inicio = performance.now()
  const duracion = 900

  const paso = ahora => {
    if (el._sxConteo !== final || !el.isConnected) return
    const p = Math.min(1, (ahora - inicio) / duracion)
    const suave = 1 - Math.pow(1 - p, 3)
    if (p < 1) {
      el.textContent = partes
        .map((parte, i) => (i % 2 ? String(Math.round(Number(parte) * suave)) : parte))
        .join("")
      requestAnimationFrame(paso)
    } else {
      el.textContent = final
    }
  }

  requestAnimationFrame(paso)
}

function revisarNodo(nodo) {
  if (nodo.nodeType !== 1) return
  if (nodo.matches("[data-conteo]")) contar(nodo)
  nodo.querySelectorAll("[data-conteo]").forEach(contar)

  const aviso = nodo.matches("#flash-error, #flash-info")
    ? nodo
    : nodo.querySelector("#flash-error, #flash-info")
  if (aviso) pulso(aviso.id === "flash-error" ? 1.4 : 0.6)
}

// ---------------------------------------------------------------------------
// Arranque
// ---------------------------------------------------------------------------

export function iniciarEfectos() {
  let guardado = null
  try {
    guardado = localStorage.getItem(CLAVE_MOVIMIENTO)
  } catch (_error) {
    guardado = null
  }
  document.documentElement.dataset.movimiento = guardado === "reducido" ? "reducido" : "completo"

  const lienzo = document.getElementById("sx-campo")
  campo = lienzo ? crearCampo(lienzo) : null
  leerColores()

  let fijoDibujado = false

  const medir = () => {
    if (campo) campo.medir()
    fijoDibujado = false
  }

  medir()
  addEventListener("resize", medir)

  new MutationObserver(() => {
    leerColores()
    fijoDibujado = false
  }).observe(document.documentElement, {attributes: true, attributeFilter: ["data-theme"]})

  const intensidadObjetivo = () =>
    document.querySelector("[data-escena='portada']") ? 1 : 0.7

  // Bucle de dibujo.
  let anterior = performance.now()
  let ultimaAmbiental = -10

  const cuadro = ahora => {
    requestAnimationFrame(cuadro)
    if (document.hidden) {
      anterior = ahora
      return
    }

    const t = ahora / 1000
    const dt = Math.min(0.1, (ahora - anterior) / 1000)
    anterior = ahora
    E.t = t

    if (quieto()) {
      // Sin animación: una sola imagen fija del fondo y la traza en reposo.
      const objetivo = intensidadObjetivo()
      if (!fijoDibujado || E.intensidad !== objetivo) {
        fijoDibujado = true
        E.intensidad = objetivo
        E.ondas.length = 0
        E.energia = 0
        E.sx = E.sy = 0.5
        E.agitacion = 1
        E.tinte = 0
        E.vuelo = E.vueloObjetivo = 0
        TRAZA.fill(0)
        if (campo) campo.dibujar(0, E)
      }
      dibujarTraza()
      return
    }
    fijoDibujado = false

    E.intensidad += (intensidadObjetivo() - E.intensidad) * 0.05
    E.sx += (E.px - E.sx) * 0.04
    E.sy += (E.py - E.sy) * 0.04

    const nivel = nivelEnPantalla()
    E.agitacion += (nivel.agitacion - E.agitacion) * 0.03
    E.tinte += (nivel.tinte - E.tinte) * 0.03
    E.vuelo += (E.vueloObjetivo - E.vuelo) * (E.vueloObjetivo < 0 ? 0.07 : 0.035)

    if (t - ultimaAmbiental > nivel.cada) {
      ultimaAmbiental = t
      emitirOnda(EPICENTRO.x, EPICENTRO.z, nivel.fuerza)
    }

    while (E.ondas.length && t - E.ondas[0].t > VIDA_ONDA) E.ondas.shift()

    if (campo) campo.dibujar(t, E)
    avanzarTraza(dt, t)
    dibujarTraza()
  }

  requestAnimationFrame(cuadro)

  // Botón "movimiento": alterna entre completo y reducido y lo recuerda.
  addEventListener("click", e => {
    if (!(e.target instanceof Element) || !e.target.closest("[data-sx-movimiento]")) return
    const nuevo = quieto() ? "completo" : "reducido"
    document.documentElement.dataset.movimiento = nuevo
    try {
      localStorage.setItem(CLAVE_MOVIMIENTO, nuevo)
    } catch (_error) {
      // Sin almacenamiento disponible: la preferencia dura lo que dure la página.
    }
  })

  // Reloj de la barra superior.
  const reloj = () => {
    const el = document.getElementById("sx-reloj")
    if (el) el.textContent = new Date().toLocaleTimeString("es-CO", {hour12: false})
  }
  reloj()
  setInterval(reloj, 1000)

  // Puntero: la cámara acompaña, foco de las tarjetas e inclinación.
  let inclinada = null

  addEventListener(
    "pointermove",
    e => {
      E.px = e.clientX / innerWidth
      E.py = e.clientY / innerHeight
      if (!(e.target instanceof Element)) return

      const foco = e.target.closest(".sx-foco")
      if (foco) {
        const r = foco.getBoundingClientRect()
        foco.style.setProperty("--mx", `${e.clientX - r.left}px`)
        foco.style.setProperty("--my", `${e.clientY - r.top}px`)
      }

      const tarjeta = quieto() ? null : e.target.closest(".sx-inclinar")
      if (inclinada && inclinada !== tarjeta) {
        inclinada.style.removeProperty("--rx")
        inclinada.style.removeProperty("--ry")
      }
      inclinada = tarjeta
      if (tarjeta) {
        const r = tarjeta.getBoundingClientRect()
        const nx = (e.clientX - r.left) / r.width - 0.5
        const ny = (e.clientY - r.top) / r.height - 0.5
        tarjeta.style.setProperty("--rx", `${(-ny * 7).toFixed(2)}deg`)
        tarjeta.style.setProperty("--ry", `${(nx * 7).toFixed(2)}deg`)
      }
    },
    {passive: true},
  )

  addEventListener(
    "pointerdown",
    e => {
      E.energia = Math.min(1.6, E.energia + 0.55)
      const suelo = campo ? campo.alSuelo(e.clientX, e.clientY) : null
      if (suelo) emitirOnda(suelo.x, suelo.z, 0.3 + 0.5 * E.intensidad)

      if (e.target instanceof Element && e.target.closest("a, button, .btn, [phx-click]")) {
        anilloEnPantalla(e.clientX, e.clientY)
      }
    },
    {passive: true},
  )

  addEventListener("keydown", () => (E.energia = Math.min(1.6, E.energia + 0.1)), {passive: true})
  // Envíos. En la portada, "Conectar" lanza una onda desde el formulario y la
  // cámara avanza sobre el terreno antes de enviar de verdad (0,65 s).
  addEventListener(
    "submit",
    e => {
      const form = e.target
      const portada = form instanceof HTMLFormElement && form.closest("[data-escena='portada']")

      if (!portada || quieto() || !campo || form.dataset.sxEnviando) {
        pulso(0.8)
        return
      }

      e.preventDefault()
      form.dataset.sxEnviando = "1"

      const r = form.getBoundingClientRect()
      const origen = campo.alSuelo(r.left + r.width / 2, r.bottom) || EPICENTRO
      E.energia = 1.6
      emitirOnda(origen.x, origen.z, 1.3)
      E.vueloObjetivo = -1
      portada.classList.add("sx-despegue")

      try {
        sessionStorage.setItem(CLAVE_ENTRADA, "1")
      } catch (_error) {
        // Sin almacenamiento: el panel simplemente entra sin la llegada animada.
      }

      setTimeout(() => form.submit(), 650)
    },
    true,
  )

  // Llegada tras conectar: la cámara baja desde lejos hasta su sitio.
  try {
    if (sessionStorage.getItem(CLAVE_ENTRADA)) {
      sessionStorage.removeItem(CLAVE_ENTRADA)
      if (!quieto()) {
        E.vuelo = 1
        E.intensidad = 1
      }
    }
  } catch (_error) {
    // Sin almacenamiento disponible.
  }

  // Cambio de sección: el contenido actual se retira y la marca del menú se
  // desliza desde el ítem anterior hasta el nuevo.
  let marcaAnterior = null

  addEventListener("phx:page-loading-start", e => {
    pulso(0.6)
    if (!e.detail || e.detail.kind !== "redirect") return

    const activo = document.querySelector(".sx-nav-activo")
    marcaAnterior = activo ? activo.getBoundingClientRect().top : null

    const contenido = document.querySelector(".sx-contenido")
    if (contenido && !quieto()) contenido.classList.add("sx-saliendo")
  })

  addEventListener("phx:page-loading-stop", () => {
    document.querySelectorAll(".sx-saliendo").forEach(el => el.classList.remove("sx-saliendo"))

    // LiveView avisa dos veces al navegar; el menú nuevo solo existe en la segunda.
    const activo = document.querySelector(".sx-nav-activo")
    if (!activo) return

    if (marcaAnterior !== null && !quieto()) {
      const salto = marcaAnterior - activo.getBoundingClientRect().top
      if (Math.abs(salto) > 1) {
        activo.style.setProperty("--sx-desde", `${salto}px`)
        activo.style.setProperty("--sx-escala", "1")
      }
    }
    marcaAnterior = null
  })

  // Cifras y avisos que aparecen o cambian.
  revisarNodo(document.body)
  new MutationObserver(cambios => {
    for (const cambio of cambios) {
      if (cambio.type === "attributes") {
        if (cambio.target._sxConteo !== cambio.target.dataset.conteo) contar(cambio.target)
      } else {
        cambio.addedNodes.forEach(revisarNodo)
      }
    }
  }).observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["data-conteo"],
  })
}
