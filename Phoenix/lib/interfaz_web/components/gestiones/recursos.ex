defmodule InterfazWeb.Gestiones.Recursos do
  @moduledoc """
  Componentes de la gestión de recursos: la ficha de cada recurso, la tabla
  de movimientos y los tres formularios (registrar, entrada/salida, transferir).
  La LiveView solo decide qué mostrar; aquí está cómo se ve.
  """
  use InterfazWeb, :html

  alias Interfaz.Fuente.Catalogos

  attr :recurso, :map, required: true
  attr :zonas_por_codigo, :map, required: true
  attr :gestiona, :boolean, default: false

  @doc "Ficha de un recurso, construida sobre la tarjeta base."
  def tarjeta_recurso(assigns) do
    ~H"""
    <.tarjeta id={"recurso-#{@recurso.codigo}"} alerta={@recurso.critico}>
      <:etiqueta>{@recurso.codigo} · {t(@recurso.categoria)}</:etiqueta>
      <:titulo>{@recurso.nombre}</:titulo>
      <:insignias :if={@recurso.critico}>
        <span class="badge badge-sm badge-error badge-soft">Bajo mínimo</span>
      </:insignias>

      <.cifra valor={@recurso.cantidad} unidad={@recurso.unidad} />
      <.barra class="mt-2" valor={@recurso.cantidad} maximo={max(@recurso.minimo * 3, 1)} />

      <:pie>
        <span>
          <.icon name="hero-map-pin" class="size-3.5" />
          {@recurso.ubicacion} · {zona(@recurso.zona, @zonas_por_codigo)}
        </span>
        <span>mínimo {@recurso.minimo}</span>
      </:pie>

      <:acciones :if={@gestiona}>
        <button
          class="btn btn-xs btn-ghost"
          phx-click="abrir"
          phx-value-modal="movimiento"
          phx-value-codigo={@recurso.codigo}
        >
          Movimiento
        </button>
        <button
          class="btn btn-xs btn-ghost"
          phx-click="abrir"
          phx-value-modal="transferencia"
          phx-value-codigo={@recurso.codigo}
        >
          Transferir
        </button>
      </:acciones>
    </.tarjeta>
    """
  end

  attr :movimientos, :list, required: true

  @doc "Historial de movimientos: entradas, salidas, asignaciones, transferencias y rechazos."
  def tabla_movimientos(assigns) do
    ~H"""
    <.panel titulo="Historial de movimientos" class="mt-6">
      <.vacio :if={@movimientos == []} mensaje="Todavía no hay movimientos." />
      <div :if={@movimientos != []} class="overflow-x-auto">
        <table id="tabla-movimientos" class="table table-sm">
          <thead>
            <tr>
              <th>Fecha</th>
              <th>Tipo</th>
              <th>Recurso</th>
              <th class="text-right">Cantidad</th>
              <th>Detalle</th>
              <th>Usuario</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={m <- @movimientos} id={"movimiento-#{m.id}"}>
              <td class="whitespace-nowrap tabular-nums text-base-content/70">{m.fecha}</td>
              <td><.insignia valor={m.tipo} /></td>
              <td>{m.recurso}</td>
              <td class={[
                "text-right tabular-nums",
                m.tipo == :rechazo && "line-through text-base-content/50"
              ]}>
                {m.cantidad}
              </td>
              <td class="min-w-56">{m.detalle}</td>
              <td>{m.usuario}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </.panel>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :opciones_zonas, :list, required: true

  def form_recurso(assigns) do
    ~H"""
    <.modal id="modal-recurso" titulo="Registrar recurso" abierto={@abierto}>
      <.form for={@form} id="form-recurso" phx-submit="guardar">
        <div class="grid grid-cols-2 gap-3">
          <.input field={@form[:nombre]} label="Nombre" placeholder="Agua potable" required />
          <.input
            field={@form[:categoria]}
            type="select"
            label="Categoría"
            options={opciones(Catalogos.categorias_recurso())}
          />
          <.input field={@form[:cantidad]} type="number" min="0" label="Cantidad" required />
          <.input field={@form[:unidad]} label="Unidad de medida" placeholder="litros" required />
          <.input field={@form[:minimo]} type="number" min="0" label="Mínimo (alerta)" required />
          <.input field={@form[:ubicacion]} label="Ubicación" placeholder="centro_acopio_1" required />
          <.input field={@form[:zona]} type="select" label="Zona" options={@opciones_zonas} />
        </div>
        <.botones_form texto="Registrar" />
      </.form>
    </.modal>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :opciones_recursos, :list, required: true

  def form_movimiento(assigns) do
    ~H"""
    <.modal id="modal-movimiento" titulo="Registrar entrada o salida" abierto={@abierto}>
      <.form for={@form} id="form-movimiento" phx-submit="guardar">
        <div class="grid grid-cols-2 gap-3">
          <.input
            field={@form[:tipo]}
            type="select"
            label="Tipo"
            options={[{"Entrada", "entrada"}, {"Salida", "salida"}]}
          />
          <.input field={@form[:recurso]} type="select" label="Recurso" options={@opciones_recursos} />
        </div>
        <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad" required />
        <.input
          field={@form[:detalle]}
          label="Detalle (motivo de la salida)"
          placeholder="Donación, entrega, ajuste…"
        />
        <.botones_form />
      </.form>
    </.modal>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :opciones_recursos, :list, required: true
  attr :opciones_zonas, :list, required: true
  attr :ubicaciones, :list, required: true

  def form_transferencia(assigns) do
    ~H"""
    <.modal id="modal-transferencia" titulo="Transferir entre centros" abierto={@abierto}>
      <.form for={@form} id="form-transferencia" phx-submit="guardar">
        <.input
          field={@form[:recurso]}
          type="select"
          label="Recurso (sale de su ubicación actual)"
          options={@opciones_recursos}
        />
        <div class="grid grid-cols-2 gap-3">
          <.input
            field={@form[:destino]}
            label="Destino"
            placeholder="albergue_2"
            list="ubicaciones-conocidas"
            required
          />
          <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad" required />
        </div>
        <.input field={@form[:zona]} type="select" label="Zona del destino" options={@opciones_zonas} />
        <datalist id="ubicaciones-conocidas">
          <option :for={ubicacion <- @ubicaciones} value={ubicacion} />
        </datalist>
        <.botones_form texto="Transferir" />
      </.form>
    </.modal>
    """
  end
end
