defmodule InterfazWeb.UI do
  @moduledoc """
  Componentes visuales propios de Epicenter: insignias de estado, tarjetas de
  indicadores, barras de ocupación, paneles y modales.
  """
  use Phoenix.Component
  import InterfazWeb.CoreComponents, only: [icon: 1]

  # ---------------------------------------------------------------------------
  # Textos
  # ---------------------------------------------------------------------------

  @etiquetas %{
    critico: "Crítico",
    critica: "Crítica",
    alto: "Alto",
    alta: "Alta",
    medio: "Medio",
    media: "Media",
    bajo: "Bajo",
    baja: "Baja",
    pendiente: "Pendiente",
    asignada: "Asignada",
    en_atencion: "En atención",
    atendida: "Atendida",
    cancelada: "Cancelada",
    sin_informacion: "Sin información",
    reportada: "Reportada",
    localizada: "Localizada",
    trasladada: "Trasladada",
    en_albergue: "En albergue",
    reunificada: "Reunificada",
    activa: "Activa",
    posible_coincidencia: "Posible coincidencia",
    resuelta: "Resuelta",
    perdida: "Perdida",
    encontrada: "Encontrada",
    entregado: "Entregado",
    agua: "Agua",
    alimentos: "Alimentos",
    medicamentos: "Medicamentos",
    primeros_auxilios: "Primeros auxilios",
    refugio: "Refugio",
    transporte: "Transporte",
    rescate: "Rescate",
    otra: "Otra",
    ciudadano: "Ciudadano",
    voluntario: "Voluntario",
    coordinador: "Coordinador",
    administrador: "Administrador",
    entrada: "Entrada",
    salida: "Salida",
    asignacion: "Asignación",
    transferencia: "Transferencia",
    rechazo: "Rechazada",
    perro: "Perro",
    gato: "Gato",
    ave: "Ave",
    pequeno: "Pequeño",
    mediano: "Mediano",
    grande: "Grande",
    ok: "Correcto",
    error: "Rechazado",
    especie: "Especie",
    color: "Color",
    tamano: "Tamaño",
    zona: "Zona",
    caracteristicas: "Características"
  }

  @doc "Texto legible para un átomo del dominio."
  def t(nil), do: "—"
  def t(valor) when is_atom(valor), do: Map.get(@etiquetas, valor, Phoenix.Naming.humanize(valor))
  def t(valor), do: to_string(valor)

  @doc "Opciones `{etiqueta, valor}` para un `<select>`."
  def opciones(valores), do: Enum.map(valores, &{t(&1), &1})

  @doc "Nombre legible de una zona a partir de su código."
  def zona(codigo) do
    case Enum.find(Interfaz.Fuente.zonas(), &(&1.codigo == codigo)) do
      nil -> codigo
      z -> z.nombre
    end
  end

  # ---------------------------------------------------------------------------
  # Insignias
  # ---------------------------------------------------------------------------

  @tonos %{
    critico: "badge-error",
    critica: "badge-error",
    alto: "badge-warning",
    alta: "badge-warning",
    medio: "badge-info",
    media: "badge-info",
    bajo: "badge-success",
    baja: "badge-success",
    pendiente: "badge-warning",
    asignada: "badge-info",
    en_atencion: "badge-primary",
    atendida: "badge-success",
    cancelada: "badge-ghost",
    sin_informacion: "badge-error",
    reportada: "badge-warning",
    localizada: "badge-info",
    trasladada: "badge-primary",
    en_albergue: "badge-info",
    reunificada: "badge-success",
    activa: "badge-warning",
    posible_coincidencia: "badge-primary",
    resuelta: "badge-success",
    entregado: "badge-success",
    ok: "badge-success",
    error: "badge-error",
    entrada: "badge-success",
    salida: "badge-info",
    asignacion: "badge-primary",
    transferencia: "badge-neutral",
    rechazo: "badge-error",
    perdida: "badge-error",
    encontrada: "badge-success"
  }

  attr :valor, :atom, required: true
  attr :class, :string, default: nil

  def insignia(assigns) do
    assigns = assign(assigns, :tono, Map.get(@tonos, assigns.valor, "badge-ghost"))

    ~H"""
    <span class={["badge badge-sm badge-soft whitespace-nowrap", @tono, @class]}>{t(@valor)}</span>
    """
  end

  # ---------------------------------------------------------------------------
  # Indicadores
  # ---------------------------------------------------------------------------

  attr :titulo, :string, required: true
  attr :valor, :any, required: true
  attr :detalle, :string, default: nil
  attr :icono, :string, required: true
  attr :tono, :string, default: "text-primary"

  def indicador(assigns) do
    ~H"""
    <div class="rounded-box border border-base-300 bg-base-100 p-4">
      <div class="flex items-center justify-between gap-2">
        <p class="text-sm text-base-content/70">{@titulo}</p>
         <.icon name={@icono} class={["size-5", @tono]} />
      </div>
      
      <p class="mt-2 text-3xl font-semibold tabular-nums">{@valor}</p>
      
      <p :if={@detalle} class="mt-1 text-xs text-base-content/60">{@detalle}</p>
    </div>
    """
  end

  attr :valor, :integer, required: true
  attr :maximo, :integer, required: true
  attr :class, :string, default: nil

  @doc "Barra de ocupación/disponibilidad. Cambia de color cerca del límite."
  def barra(assigns) do
    pct = if assigns.maximo > 0, do: round(assigns.valor * 100 / assigns.maximo), else: 0

    tono =
      cond do
        pct >= 95 -> "progress-error"
        pct >= 80 -> "progress-warning"
        true -> "progress-success"
      end

    assigns = assign(assigns, pct: pct, tono: tono)

    ~H"""
    <div class={["flex items-center gap-2", @class]}>
      <progress class={["progress h-2 flex-1", @tono]} value={@valor} max={@maximo}></progress>
      <span class="w-10 text-right text-xs tabular-nums text-base-content/70">{@pct}%</span>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Estructura
  # ---------------------------------------------------------------------------

  attr :titulo, :string, required: true
  attr :class, :string, default: nil
  slot :acciones
  slot :inner_block, required: true

  def panel(assigns) do
    ~H"""
    <section class={["rounded-box border border-base-300 bg-base-100", @class]}>
      <header class="flex flex-wrap items-center justify-between gap-2 border-b border-base-300 px-4 py-3">
        <h2 class="font-semibold">{@titulo}</h2>
        
        <div :if={@acciones != []} class="flex flex-wrap gap-2">{render_slot(@acciones)}</div>
      </header>
      
      <div class="p-4">{render_slot(@inner_block)}</div>
    </section>
    """
  end

  attr :titulo, :string, required: true
  attr :subtitulo, :string, default: nil
  slot :acciones

  def encabezado(assigns) do
    ~H"""
    <div class="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold tracking-tight">{@titulo}</h1>
        
        <p :if={@subtitulo} class="mt-1 text-sm text-base-content/70">{@subtitulo}</p>
      </div>
      
      <div :if={@acciones != []} class="flex flex-wrap gap-2">{render_slot(@acciones)}</div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :titulo, :string, required: true
  attr :abierto, :boolean, default: false
  attr :al_cerrar, :string, default: "cerrar_modal"
  slot :inner_block, required: true

  @doc "Modal controlado desde el LiveView mediante un assign."
  def modal(assigns) do
    ~H"""
    <div
      :if={@abierto}
      id={@id}
      class="modal modal-open"
      phx-window-keydown={@al_cerrar}
      phx-key="escape"
    >
      <div class="modal-box max-w-lg">
        <div class="mb-4 flex items-center justify-between">
          <h3 class="text-lg font-semibold">{@titulo}</h3>
          
          <button
            type="button"
            class="btn btn-ghost btn-sm btn-square"
            phx-click={@al_cerrar}
            aria-label="Cerrar"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
         {render_slot(@inner_block)}
      </div>
      
      <div class="modal-backdrop" phx-click={@al_cerrar}></div>
    </div>
    """
  end

  attr :texto, :string, default: "Guardar"

  @doc "Botones de cierre de un formulario dentro de un modal."
  def botones_form(assigns) do
    ~H"""
    <div class="mt-4 flex justify-end gap-2">
      <button type="button" class="btn btn-ghost" phx-click="cerrar_modal">Cancelar</button>
      <button type="submit" class="btn btn-primary" phx-disable-with="Enviando...">{@texto}</button>
    </div>
    """
  end

  attr :mensaje, :string, required: true
  attr :icono, :string, default: "hero-inbox"

  def vacio(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-2 py-8 text-center text-base-content/60">
      <.icon name={@icono} class="size-8" />
      <p class="text-sm">{@mensaje}</p>
    </div>
    """
  end
end
