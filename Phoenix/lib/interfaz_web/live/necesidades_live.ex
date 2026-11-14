defmodule InterfazWeb.NecesidadesLive do
  @moduledoc """
  Página de necesidades. Los datos vienen de `Interfaz.Fuente.Necesidades`
  (ya ordenados por prioridad) y el dibujo de `InterfazWeb.Gestiones.Necesidades`.
  """
  use InterfazWeb, :live_view

  import InterfazWeb.Gestiones.Necesidades

  alias Interfaz.Fuente.{Catalogos, Necesidades, Recursos}
  alias InterfazWeb.{Respuesta, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :necesidades}}

  @filtros_vacios %{"zona" => "", "tipo" => "", "prioridad" => "", "estado" => ""}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Necesidades")
     |> assign(:modal, nil)
     |> assign(:necesidad, nil)
     |> assign(:opciones_recursos, [])
     |> assign(:form, to_form(%{}, as: :necesidad))
     |> assign(:filtros_actuales, @filtros_vacios)
     |> cargar()}
  end

  defp cargar(socket) do
    filtros = socket.assigns.filtros_actuales

    socket
    |> assign(:necesidades, Necesidades.necesidades(filtros))
    |> assign(:filtros, to_form(filtros, as: :filtro))
    |> assign(:filtrando?, filtros != @filtros_vacios)
  end

  def handle_event("filtrar", %{"filtro" => filtros}, socket),
    do: {:noreply, socket |> assign(:filtros_actuales, filtros) |> cargar()}

  def handle_event("limpiar", _params, socket),
    do: {:noreply, socket |> assign(:filtros_actuales, @filtros_vacios) |> cargar()}

  def handle_event("nueva", _params, socket) do
    datos = %{"zona" => socket.assigns.usuario.zona, "prioridad" => "media"}
    {:noreply, socket |> assign(:modal, :nueva) |> assign(:form, to_form(datos, as: :necesidad))}
  end

  # Los recursos se piden solo al abrir el modal de asignar, no en cada render.
  def handle_event("asignar", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.necesidades, &(&1.id == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "La necesidad ya no existe.")}

      necesidad ->
        {:noreply,
         socket
         |> assign(:modal, :asignar)
         |> assign(:necesidad, necesidad)
         |> assign(:opciones_recursos, opciones_recursos(necesidad))
         |> assign(:form, to_form(%{"cantidad" => necesidad.faltante}, as: :asignacion))}
    end
  end

  def handle_event("cerrar_modal", _params, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"necesidad" => datos}, socket),
    do: responder(socket, Necesidades.registrar(datos, usuario(socket)))

  def handle_event("guardar", %{"asignacion" => datos}, socket) do
    id = socket.assigns.necesidad.id
    responder(socket, Necesidades.asignar_recurso(id, datos["recurso"], datos["cantidad"], usuario(socket)))
  end

  def handle_event("cambiar_estado", %{"id" => id, "estado" => estado}, socket),
    do: responder(socket, Necesidades.cambiar_estado(id, estado, usuario(socket)))

  defp responder(socket, resultado),
    do: {:noreply, socket |> Respuesta.mostrar(resultado) |> cargar()}

  defp usuario(socket), do: socket.assigns.usuario.usuario

  # Solo recursos de la misma categoría que la necesidad (la lógica lo exige)
  # y con existencias; primero los de la misma zona.
  defp opciones_recursos(necesidad) do
    Recursos.recursos()
    |> Enum.filter(&(&1.categoria == necesidad.tipo and &1.cantidad > 0))
    |> Enum.sort_by(&(&1.zona != necesidad.zona))
    |> Enum.map(
      &{"#{&1.codigo} · #{&1.nombre} — #{&1.cantidad} #{&1.unidad} en #{&1.ubicacion}", &1.codigo}
    )
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      usuario={@usuario}
      activo={@activo}
      zonas_por_codigo={@zonas_por_codigo}
    >
      <.encabezado
        titulo="Necesidades puntuales"
        subtitulo="Ordenadas por prioridad: las críticas se atienden primero."
      >
        <:acciones>
          <button id="nueva-necesidad" class="btn btn-primary btn-sm" phx-click="nueva">
            <.icon name="hero-plus" class="size-4" /> Registrar necesidad
          </button>
        </:acciones>
      </.encabezado>

      <.form
        for={@filtros}
        id="filtros-necesidades"
        phx-change="filtrar"
        class="mb-4 grid grid-cols-2 items-end gap-3 sx-card sx-foco p-4 md:grid-cols-5"
      >
        <.input field={@filtros[:zona]} type="select" label="Zona" prompt="Todas" options={@opciones_zonas} />
        <.input
          field={@filtros[:tipo]}
          type="select"
          label="Tipo"
          prompt="Todos"
          options={opciones(Catalogos.tipos_necesidad())}
        />
        <.input
          field={@filtros[:prioridad]}
          type="select"
          label="Prioridad"
          prompt="Todas"
          options={opciones(Catalogos.prioridades())}
        />
        <.input
          field={@filtros[:estado]}
          type="select"
          label="Estado"
          prompt="Todos"
          options={opciones(Catalogos.estados_necesidad())}
        />
        <div class="col-span-2 mb-2 flex items-center justify-between gap-2 md:col-span-1">
          <span class="text-sm text-base-content/70">{length(@necesidades)} resultados</span>
          <button :if={@filtrando?} type="button" class="btn btn-ghost btn-sm" phx-click="limpiar">
            Limpiar
          </button>
        </div>
      </.form>

      <.tabla_necesidades
        necesidades={@necesidades}
        zonas_por_codigo={@zonas_por_codigo}
        coordina={Sesion.coordina?(@usuario)}
      />

      <.form_necesidad
        form={@form}
        abierto={@modal == :nueva}
        opciones_zonas={@opciones_zonas}
        coordina={Sesion.coordina?(@usuario)}
      />
      <.form_asignar
        form={@form}
        abierto={@modal == :asignar}
        necesidad={@necesidad}
        opciones_recursos={@opciones_recursos}
        zonas_por_codigo={@zonas_por_codigo}
      />
    </Layouts.app>
    """
  end
end
