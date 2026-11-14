defmodule InterfazWeb.Gestiones.Albergues do
  @moduledoc """
  Componentes de la gestión de albergues: ficha de cada albergue, ranking de
  ocupación y los formularios de registro e ingreso/salida.
  """
  use InterfazWeb, :html

  attr :albergue, :map, required: true
  attr :zonas_por_codigo, :map, required: true
  attr :gestiona, :boolean, default: false

  @doc "Ficha de un albergue, construida sobre la tarjeta base."
  def tarjeta_albergue(assigns) do
    assigns = assign(assigns, :lleno, assigns.albergue.cupos <= 0)

    ~H"""
    <.tarjeta id={"albergue-#{@albergue.codigo}"} alerta={@lleno}>
      <:etiqueta>{zona(@albergue.zona, @zonas_por_codigo)}</:etiqueta>
      <:titulo>{@albergue.nombre}</:titulo>
      <:insignias :if={@lleno}>
        <span class="badge badge-error badge-soft badge-sm">Lleno</span>
      </:insignias>

      <div class="flex items-end justify-between">
        <.cifra valor={@albergue.cupos} unidad="cupos" />
        <p class="text-sm text-base-content/60">
          {@albergue.ocupacion} / {@albergue.capacidad} ocupados
        </p>
      </div>
      <.barra valor={@albergue.ocupacion} maximo={@albergue.capacidad} class="mt-3" />

      <:acciones :if={@gestiona}>
        <button
          id={"ingreso-#{@albergue.codigo}"}
          class="btn btn-sm btn-primary btn-soft flex-1"
          phx-click="movimiento"
          phx-value-codigo={@albergue.codigo}
          phx-value-tipo="ingreso"
          disabled={@lleno}
        >
          <.icon name="hero-arrow-down-on-square" class="size-4" /> Ingreso
        </button>
        <button
          id={"salida-#{@albergue.codigo}"}
          class="btn btn-sm btn-ghost flex-1"
          phx-click="movimiento"
          phx-value-codigo={@albergue.codigo}
          phx-value-tipo="salida"
          disabled={@albergue.ocupacion == 0}
        >
          <.icon name="hero-arrow-up-on-square" class="size-4" /> Salida
        </button>
      </:acciones>
    </.tarjeta>
    """
  end

  attr :ranking, :list, required: true

  @doc "Albergues de mayor a menor ocupación."
  def ranking_ocupacion(assigns) do
    ~H"""
    <.panel titulo="Mayor nivel de ocupación">
      <ol id="ranking-albergues" class="space-y-4">
        <li :for={{albergue, puesto} <- Enum.with_index(@ranking, 1)} class="flex gap-3">
          <span class="grid size-7 shrink-0 place-items-center rounded-full bg-base-200 text-sm font-semibold">
            {puesto}
          </span>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm font-medium">{albergue.nombre}</p>
            <.barra valor={albergue.ocupacion} maximo={albergue.capacidad} />
            <p class="mt-1 text-xs text-base-content/60">
              {albergue.ocupacion} / {albergue.capacidad} ocupados
            </p>
          </div>
        </li>
      </ol>
    </.panel>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :opciones_zonas, :list, required: true

  def form_albergue(assigns) do
    ~H"""
    <.modal id="modal-albergue" titulo="Registrar albergue" abierto={@abierto}>
      <.form for={@form} id="form-albergue" phx-submit="guardar">
        <.input field={@form[:nombre]} label="Nombre" placeholder="Albergue Norte" required />
        <div class="grid grid-cols-2 gap-3">
          <.input field={@form[:capacidad]} type="number" min="1" label="Capacidad máxima" required />
          <.input field={@form[:zona]} type="select" label="Zona" options={@opciones_zonas} />
        </div>
        <p class="text-xs text-base-content/60">El código del albergue lo genera el sistema.</p>
        <.botones_form texto="Registrar" />
      </.form>
    </.modal>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :albergue, :map, default: nil
  attr :tipo, :string, required: true
  attr :opciones_personas, :list, required: true

  @doc "Ingreso o salida de una persona. Las opciones se calculan al abrir el modal."
  def form_movimiento_albergue(assigns) do
    ~H"""
    <.modal
      :if={@albergue}
      id="modal-movimiento-albergue"
      titulo={"#{@albergue.nombre} · registrar #{@tipo}"}
      abierto={@abierto}
    >
      <p class="mb-3 text-sm text-base-content/70">
        {@albergue.cupos} cupos disponibles de {@albergue.capacidad}.
      </p>
      <.form for={@form} id="form-movimiento-albergue" phx-submit="guardar">
        <.vacio
          :if={@opciones_personas == []}
          mensaje={
            if @tipo == "salida",
              do: "No hay personas en este albergue.",
              else: "No hay personas reportadas para ingresar. Repórtalas en «Personas y mensajes»."
          }
          icono="hero-user-group"
        />
        <.input
          :if={@opciones_personas != []}
          field={@form[:documento]}
          type="select"
          label="Persona"
          options={@opciones_personas}
        />
        <.botones_form texto="Registrar" />
      </.form>
    </.modal>
    """
  end
end
