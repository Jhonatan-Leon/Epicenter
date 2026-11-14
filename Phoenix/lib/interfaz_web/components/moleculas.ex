defmodule InterfazWeb.Moleculas do
  @moduledoc """
  Moléculas: combinan átomos en un bloque con sentido propio. La tarjeta es
  la base de todas las fichas (recursos, albergues, necesidades…): cada
  gestión solo le pasa su contenido.
  """
  use Phoenix.Component
  import InterfazWeb.CoreComponents, only: [icon: 1]

  attr :titulo, :string, required: true
  attr :valor, :any, required: true
  attr :detalle, :string, default: nil
  attr :icono, :string, required: true
  attr :tono, :string, default: "text-primary"

  def indicador(assigns) do
    ~H"""
    <div class="sx-card sx-foco sx-inclinar sx-indicador px-4 pb-10 pt-4 sm:px-5 sm:pt-5">
      <div class="flex items-start justify-between gap-2">
        <p class="sx-etiqueta pt-1">{@titulo}</p>
        <span class={["sx-anillo", @tono]}><.icon name={@icono} class="size-4" /></span>
      </div>

      <p class="sx-cifra mt-3" data-conteo={@valor}>{@valor}</p>

      <p :if={@detalle} class="mt-2 text-xs text-base-content/65">{@detalle}</p>

      <svg
        class={["sx-traza", @tono]}
        viewBox="0 0 120 26"
        preserveAspectRatio="none"
        aria-hidden="true"
      >
        <path pathLength="1" d="M0 14h30l4-6 5 13 6-19 6 22 5-13 4 6 3-3h57" />
      </svg>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :alerta, :boolean, default: false, doc: "borde de alerta (por ejemplo, bajo mínimo o lleno)"
  attr :class, :string, default: nil
  slot :etiqueta, doc: "línea pequeña arriba del título (código, categoría, zona)"
  slot :titulo, required: true
  slot :insignias, doc: "insignias a la derecha del título"
  slot :inner_block, doc: "cuerpo: cifra principal, barra, descripción"
  slot :pie, doc: "datos secundarios abajo"
  slot :acciones, doc: "botones; solo se muestra si hay alguno"

  @doc "Tarjeta base reutilizable para cualquier ficha."
  def tarjeta(assigns) do
    ~H"""
    <article
      id={@id}
      class={[
        "sx-card sx-foco flex flex-col p-4",
        @alerta && "border-error/50",
        @class
      ]}
    >
      <div class="flex items-start justify-between gap-2">
        <div class="min-w-0">
          <p :if={@etiqueta != []} class="text-xs text-base-content/60">{render_slot(@etiqueta)}</p>
          <h3 class="truncate font-semibold">{render_slot(@titulo)}</h3>
        </div>
        <div :if={@insignias != []} class="flex shrink-0 gap-1">{render_slot(@insignias)}</div>
      </div>

      <div :if={@inner_block != []} class="mt-3 flex-1">{render_slot(@inner_block)}</div>

      <div
        :if={@pie != []}
        class="mt-3 flex items-center justify-between gap-2 text-xs text-base-content/60"
      >
        {render_slot(@pie)}
      </div>

      <div :if={@acciones != []} class="mt-3 flex gap-2 border-t border-base-300 pt-3">
        {render_slot(@acciones)}
      </div>
    </article>
    """
  end

  attr :valor, :any, required: true
  attr :unidad, :string, default: nil

  @doc "Cifra grande con su unidad (\"15 litros\")."
  def cifra(assigns) do
    ~H"""
    <p class="text-3xl font-semibold tabular-nums">
      {@valor} <span :if={@unidad} class="text-sm font-normal text-base-content/60">{@unidad}</span>
    </p>
    """
  end
end
