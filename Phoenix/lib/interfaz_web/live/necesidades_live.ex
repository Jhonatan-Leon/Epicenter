defmodule InterfazWeb.NecesidadesLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.{Accion, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :necesidades}}

  @filtros_vacios %{"zona" => "", "tipo" => "", "prioridad" => "", "estado" => ""}
  @orden %{critica: 0, alta: 1, media: 2, baja: 3}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Necesidades")
     |> assign(:modal, nil)
     |> assign(:necesidad, nil)
     |> assign(:form, to_form(%{}, as: :necesidad))
     |> filtrar(@filtros_vacios)}
  end

  def handle_event("filtrar", %{"filtro" => filtros}, socket),
    do: {:noreply, filtrar(socket, filtros)}

  def handle_event("limpiar", _, socket), do: {:noreply, filtrar(socket, @filtros_vacios)}

  def handle_event("nueva", _, socket) do
    form =
      to_form(%{"zona" => socket.assigns.usuario.zona, "prioridad" => "media"}, as: :necesidad)

    {:noreply, socket |> assign(:modal, :nueva) |> assign(:form, form)}
  end

  def handle_event("asignar", %{"id" => id}, socket) do
    necesidad = Enum.find(Fuente.necesidades(), &(&1.id == id))
    form = to_form(%{"cantidad" => necesidad.cantidad}, as: :asignacion)

    {:noreply,
     socket |> assign(:modal, :asignar) |> assign(:necesidad, necesidad) |> assign(:form, form)}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"necesidad" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "register_need", [
       p["tipo"],
       p["cantidad"],
       p["prioridad"],
       p["zona"],
       p["descripcion"]
     ])}
  end

  def handle_event("guardar", %{"asignacion" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "assign_resource", [
       socket.assigns.necesidad.id,
       p["recurso"],
       p["cantidad"]
     ])}
  end

  def handle_event("cambiar_estado", %{"id" => id, "estado" => estado}, socket),
    do: {:noreply, Accion.enviar(socket, "update_need", [id, estado])}

  defp filtrar(socket, filtros) do
    coincide = fn n, campo, valor -> valor == "" or to_string(Map.fetch!(n, campo)) == valor end

    lista =
      Fuente.necesidades()
      |> Enum.filter(fn n ->
        coincide.(n, :zona, filtros["zona"]) and coincide.(n, :tipo, filtros["tipo"]) and
          coincide.(n, :prioridad, filtros["prioridad"]) and
          coincide.(n, :estado, filtros["estado"])
      end)
      |> Enum.sort_by(&{@orden[&1.prioridad], &1.id})

    socket
    |> assign(:necesidades, lista)
    |> assign(:filtros, to_form(filtros, as: :filtro))
    |> assign(:filtrando?, filtros != @filtros_vacios)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
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
        <.input
          field={@filtros[:zona]}
          type="select"
          label="Zona"
          prompt="Todas"
          options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
        />
        <.input
          field={@filtros[:tipo]}
          type="select"
          label="Tipo"
          prompt="Todos"
          options={opciones(Fuente.tipos_necesidad())}
        />
        <.input
          field={@filtros[:prioridad]}
          type="select"
          label="Prioridad"
          prompt="Todas"
          options={opciones(Fuente.prioridades())}
        />
        <.input
          field={@filtros[:estado]}
          type="select"
          label="Estado"
          prompt="Todos"
          options={opciones(Fuente.estados_necesidad())}
        />
        <div class="col-span-2 mb-2 flex items-center justify-between gap-2 md:col-span-1">
          <span class="text-sm text-base-content/70">{length(@necesidades)} resultados</span>
          <button :if={@filtrando?} type="button" class="btn btn-ghost btn-sm" phx-click="limpiar">Limpiar</button>
        </div>
      </.form>
      
      <div class="sx-card overflow-x-auto">
        <table id="tabla-necesidades" class="table">
          <thead>
            <tr>
              <th>Prioridad</th>
              
              <th>Necesidad</th>
              
              <th>Zona</th>
              
              <th class="text-right">Cantidad</th>
              
              <th>Estado</th>
              
              <th><span class="sr-only">Acciones</span></th>
            </tr>
          </thead>
          
          <tbody>
            <tr :if={@necesidades == []}>
              <td colspan="6"><.vacio mensaje="No hay necesidades con esos filtros." /></td>
            </tr>
            
            <tr :for={n <- @necesidades} id={"necesidad-#{n.id}"} class="hover:bg-base-200/60">
              <td><.insignia valor={n.prioridad} /></td>
              
              <td class="min-w-56">
                <p class="font-medium">
                  {t(n.tipo)} <span class="text-xs font-normal text-base-content/50">{n.id}</span>
                </p>
                
                <p class="text-xs text-base-content/60">{n.descripcion} · reportó {n.responsable}</p>
              </td>
              
              <td class="whitespace-nowrap">{zona(n.zona)}</td>
              
              <td class="text-right tabular-nums">{n.cantidad}</td>
              
              <td><.insignia valor={n.estado} /></td>
              
              <td class="text-right">
                <div
                  :if={Sesion.gestiona?(@usuario) and n.estado not in [:atendida, :cancelada]}
                  class="flex justify-end gap-1"
                >
                  <button
                    id={"asignar-#{n.id}"}
                    class="btn btn-xs btn-primary btn-soft"
                    phx-click="asignar"
                    phx-value-id={n.id}
                  >
                    Asignar
                  </button>
                  
                  <div class="dropdown dropdown-end">
                    <button
                      tabindex="0"
                      class="btn btn-xs btn-ghost btn-square"
                      aria-label="Cambiar estado"
                    >
                      <.icon name="hero-ellipsis-vertical" class="size-4" />
                    </button>
                    
                    <ul
                      tabindex="0"
                      class="dropdown-content menu z-10 w-44 sx-card sx-foco p-1 shadow"
                    >
                      <li :for={e <- [:en_atencion, :atendida, :cancelada] -- [n.estado]}>
                        <button phx-click="cambiar_estado" phx-value-id={n.id} phx-value-estado={e}>
                          Marcar {String.downcase(t(e))}
                        </button>
                      </li>
                    </ul>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      
      <.modal id="modal-necesidad" titulo="Registrar necesidad" abierto={@modal == :nueva}>
        <.form for={@form} id="form-necesidad" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input
              field={@form[:tipo]}
              type="select"
              label="Tipo"
              options={opciones(Fuente.tipos_necesidad())}
            />
            <.input
              field={@form[:cantidad]}
              type="number"
              min="1"
              label="Cantidad requerida"
              required
            />
            <.input
              field={@form[:prioridad]}
              type="select"
              label="Prioridad"
              options={opciones(Fuente.prioridades())}
            />
            <.input
              field={@form[:zona]}
              type="select"
              label="Zona"
              options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
            />
          </div>
          
          <.input
            field={@form[:descripcion]}
            type="textarea"
            label="Descripción"
            rows="2"
            placeholder="Punto de atención sector 3"
            required
          /> <.botones_form texto="Registrar" />
        </.form>
      </.modal>
      
      <.modal
        :if={@necesidad}
        id="modal-asignar"
        titulo={"Asignar recurso a #{@necesidad.id}"}
        abierto={@modal == :asignar}
      >
        <div class="mb-4 rounded-box bg-base-200 p-3 text-sm">
          <p class="font-medium">{t(@necesidad.tipo)} · {@necesidad.cantidad} requeridos</p>
          
          <p class="text-base-content/70">{@necesidad.descripcion} — {zona(@necesidad.zona)}</p>
        </div>
        
        <.form for={@form} id="form-asignar" phx-submit="guardar">
          <.input
            field={@form[:recurso]}
            type="select"
            label="Recurso"
            options={
              for r <- Fuente.recursos(),
                  do:
                    {"#{r.codigo} · #{r.nombre} — #{r.cantidad} #{r.unidad} en #{r.ubicacion}",
                     r.codigo}
            }
          />
          <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad a asignar" required />
          <p class="text-xs text-base-content/60">
            Si otra solicitud toma el mismo recurso al mismo tiempo, el sistema solo confirma lo que haya en inventario.
          </p>
           <.botones_form texto="Asignar" />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
