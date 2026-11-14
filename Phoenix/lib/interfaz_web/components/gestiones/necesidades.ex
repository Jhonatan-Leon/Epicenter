defmodule InterfazWeb.Gestiones.Necesidades do
  @moduledoc """
  Componentes de la gestión de necesidades: tabla ordenada por prioridad,
  formulario para registrar y formulario para asignar un recurso.
  """
  use InterfazWeb, :html

  alias Interfaz.Fuente.Catalogos

  attr :necesidades, :list, required: true
  attr :zonas_por_codigo, :map, required: true
  attr :coordina, :boolean, default: false

  def tabla_necesidades(assigns) do
    ~H"""
    <div class="sx-card overflow-x-auto">
      <table id="tabla-necesidades" class="table">
        <thead>
          <tr>
            <th>Prioridad</th>
            <th>Necesidad</th>
            <th>Zona</th>
            <th class="text-right">Asignado / requerido</th>
            <th>Estado</th>
            <th><span class="sr-only">Acciones</span></th>
          </tr>
        </thead>
        <tbody>
          <tr :if={@necesidades == []}>
            <td colspan="6"><.vacio mensaje="No hay necesidades con esos filtros." /></td>
          </tr>
          <.fila_necesidad
            :for={necesidad <- @necesidades}
            necesidad={necesidad}
            zonas_por_codigo={@zonas_por_codigo}
            coordina={@coordina}
          />
        </tbody>
      </table>
    </div>
    """
  end

  attr :necesidad, :map, required: true
  attr :zonas_por_codigo, :map, required: true
  attr :coordina, :boolean, default: false

  def fila_necesidad(assigns) do
    ~H"""
    <tr id={"necesidad-#{@necesidad.id}"} class="hover:bg-base-200/60">
      <td><.insignia valor={@necesidad.prioridad} /></td>
      <td class="min-w-56">
        <p class="font-medium">
          {t(@necesidad.tipo)}
          <span class="text-xs font-normal text-base-content/50">{@necesidad.id}</span>
        </p>
        <p class="text-xs text-base-content/60">
          {@necesidad.descripcion} · reportó {@necesidad.responsable}
        </p>
      </td>
      <td class="whitespace-nowrap">{zona(@necesidad.zona, @zonas_por_codigo)}</td>
      <td class="min-w-36">
        <p class="text-right tabular-nums">{@necesidad.asignada} / {@necesidad.cantidad}</p>
        <.barra valor={@necesidad.asignada} maximo={@necesidad.cantidad} />
      </td>
      <td><.insignia valor={@necesidad.estado} /></td>
      <td class="text-right">
        <div :if={@coordina and not @necesidad.cerrada} class="flex justify-end gap-1">
          <button
            :if={@necesidad.faltante > 0}
            id={"asignar-#{@necesidad.id}"}
            class="btn btn-xs btn-primary btn-soft"
            phx-click="asignar"
            phx-value-id={@necesidad.id}
          >
            Asignar
          </button>
          <.menu_estados necesidad={@necesidad} />
        </div>
      </td>
    </tr>
    """
  end

  # Estados a los que se puede pasar desde el actual (la lógica valida igual).
  @siguientes %{
    pendiente: [:asignada, :cancelada],
    asignada: [:en_atencion, :cancelada],
    en_atencion: [:atendida, :cancelada]
  }

  attr :necesidad, :map, required: true

  defp menu_estados(assigns) do
    assigns = assign(assigns, :siguientes, Map.get(@siguientes, assigns.necesidad.estado, []))

    ~H"""
    <div class="dropdown dropdown-end">
      <button
        id={"estados-#{@necesidad.id}"}
        tabindex="0"
        class="btn btn-xs btn-ghost btn-square"
        aria-label="Cambiar estado"
      >
        <.icon name="hero-ellipsis-vertical" class="size-4" />
      </button>
      <ul tabindex="0" class="dropdown-content menu z-10 w-44 sx-card sx-foco p-1 shadow">
        <li :for={estado <- @siguientes}>
          <button
            id={"estado-#{@necesidad.id}-#{estado}"}
            phx-click="cambiar_estado"
            phx-value-id={@necesidad.id}
            phx-value-estado={estado}
          >
            Marcar {String.downcase(t(estado))}
          </button>
        </li>
      </ul>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :opciones_zonas, :list, required: true
  attr :coordina, :boolean, default: false

  def form_necesidad(assigns) do
    prioridades =
      if assigns.coordina,
        do: Catalogos.prioridades(),
        else: Catalogos.prioridades() -- [:critica]

    assigns = assign(assigns, :prioridades, prioridades)

    ~H"""
    <.modal id="modal-necesidad" titulo="Registrar necesidad" abierto={@abierto}>
      <.form for={@form} id="form-necesidad" phx-submit="guardar">
        <div class="grid grid-cols-2 gap-3">
          <.input
            field={@form[:tipo]}
            type="select"
            label="Tipo"
            options={opciones(Catalogos.tipos_necesidad())}
          />
          <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad requerida" required />
          <.input field={@form[:prioridad]} type="select" label="Prioridad" options={opciones(@prioridades)} />
          <.input field={@form[:zona]} type="select" label="Zona" options={@opciones_zonas} />
        </div>
        <.input
          field={@form[:descripcion]}
          type="textarea"
          label="Descripción"
          rows="2"
          placeholder="Punto de atención sector 3"
          required
        />
        <.botones_form texto="Registrar" />
      </.form>
    </.modal>
    """
  end

  attr :form, :any, required: true
  attr :abierto, :boolean, required: true
  attr :necesidad, :map, default: nil
  attr :opciones_recursos, :list, required: true
  attr :zonas_por_codigo, :map, required: true

  def form_asignar(assigns) do
    ~H"""
    <.modal
      :if={@necesidad}
      id="modal-asignar"
      titulo={"Asignar recurso a #{@necesidad.id}"}
      abierto={@abierto}
    >
      <div class="mb-4 rounded-box bg-base-200 p-3 text-sm">
        <p class="font-medium">
          {t(@necesidad.tipo)} · faltan {@necesidad.faltante} de {@necesidad.cantidad}
        </p>
        <p class="text-base-content/70">
          {@necesidad.descripcion} — {zona(@necesidad.zona, @zonas_por_codigo)}
        </p>
      </div>

      <.vacio
        :if={@opciones_recursos == []}
        mensaje={"No hay recursos de #{String.downcase(t(@necesidad.tipo))} con existencias para asignar."}
        icono="hero-cube"
      />
      <.form :if={@opciones_recursos != []} for={@form} id="form-asignar" phx-submit="guardar">
        <.input field={@form[:recurso]} type="select" label="Recurso" options={@opciones_recursos} />
        <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad a asignar" required />
        <p class="text-xs text-base-content/60">
          Si otra solicitud toma el mismo recurso al mismo tiempo, el sistema solo confirma lo que haya en inventario.
        </p>
        <.botones_form texto="Asignar" />
      </.form>
    </.modal>
    """
  end
end
