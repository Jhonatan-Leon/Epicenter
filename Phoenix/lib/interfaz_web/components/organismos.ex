defmodule InterfazWeb.Organismos do
  @moduledoc """
  Organismos: secciones completas de una página (encabezado, panel, modal).
  """
  use Phoenix.Component
  import InterfazWeb.CoreComponents, only: [icon: 1]

  attr :titulo, :string, required: true
  attr :class, :string, default: nil
  slot :acciones
  slot :inner_block, required: true

  def panel(assigns) do
    ~H"""
    <section class={["sx-card sx-foco", @class]}>
      <header class="flex flex-wrap items-center justify-between gap-2 border-b border-base-content/10 px-4 py-3">
        <h2 class="sx-panel-titulo">{@titulo}</h2>

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
    <div class="sx-encabezado mb-8 flex flex-wrap items-end justify-between gap-4">
      <div class="min-w-0">
        <p class="sx-etiqueta mb-2 flex items-center gap-2">
          <span class="sx-punto"></span> Epicenter · Respuesta ante sismo
        </p>

        <h1 class="sx-titulo">{@titulo}</h1>

        <p :if={@subtitulo} class="mt-3 max-w-2xl text-sm text-base-content/70">{@subtitulo}</p>
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
end
