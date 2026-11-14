defmodule InterfazWeb.Atomos do
  @moduledoc """
  Átomos: las piezas visuales más pequeñas (insignia, barra, estado vacío,
  botones de formulario). No conocen ninguna gestión en particular.
  """
  use Phoenix.Component
  import InterfazWeb.CoreComponents, only: [icon: 1]
  import InterfazWeb.Formato, only: [t: 1]

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

  # Valores cuyo punto de estado parpadea para llamar la atención (solo visual).
  @urgentes [:critico, :critica, :sin_informacion, :perdida]

  attr :valor, :atom, required: true
  attr :class, :string, default: nil

  def insignia(assigns) do
    assigns =
      assigns
      |> assign(:tono, Map.get(@tonos, assigns.valor, "badge-ghost"))
      |> assign(:alerta, assigns.valor in @urgentes)

    ~H"""
    <span class={[
      "sx-insignia badge badge-sm badge-soft whitespace-nowrap",
      @alerta && "sx-insignia-alerta",
      @tono,
      @class
    ]}>
      {t(@valor)}
    </span>
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
        pct >= 95 -> "text-error"
        pct >= 80 -> "text-warning"
        true -> "text-success"
      end

    assigns = assign(assigns, pct: pct, ancho: min(pct, 100), tono: tono)

    ~H"""
    <div class={["flex items-center gap-2", @class]}>
      <div
        class={["sx-barra-pista flex-1", @tono]}
        role="progressbar"
        aria-valuenow={@valor}
        aria-valuemin="0"
        aria-valuemax={@maximo}
      >
        <div class="sx-barra-relleno" style={"width: #{@ancho}%"}></div>
      </div>

      <span class="w-10 text-right font-mono text-xs tabular-nums text-base-content/70">{@pct}%</span>
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
    <div class="flex flex-col items-center gap-3 py-8 text-center text-base-content/60">
      <span class="sx-vacio-icono"><.icon name={@icono} class="size-6" /></span>
      <p class="text-sm">{@mensaje}</p>
    </div>
    """
  end
end
