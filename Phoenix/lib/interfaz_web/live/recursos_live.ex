defmodule InterfazWeb.RecursosLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.{Accion, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :recursos}}

  @filtros_vacios %{"categoria" => "", "zona" => ""}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Recursos")
     |> assign(:modal, nil)
     |> assign(:form, to_form(%{}, as: :recurso))
     |> assign(:movimientos, Fuente.movimientos())
     |> filtrar(@filtros_vacios)}
  end

  def handle_event("filtrar", %{"filtro" => f}, socket), do: {:noreply, filtrar(socket, f)}

  def handle_event("abrir", %{"modal" => modal} = params, socket) do
    modal = String.to_existing_atom(modal)
    datos = if params["codigo"], do: %{"recurso" => params["codigo"]}, else: %{}
    {:noreply, socket |> assign(:modal, modal) |> assign(:form, to_form(datos, as: modal))}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"recurso" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "register_resource", [
       p["codigo"],
       p["nombre"],
       p["cantidad"],
       p["unidad"],
       p["ubicacion"],
       p["categoria"]
     ])}
  end

  def handle_event("guardar", %{"movimiento" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "register_#{p["tipo"]}", [p["recurso"], p["cantidad"], p["detalle"]])}
  end

  def handle_event("guardar", %{"transferencia" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "transfer_resource", [
       p["recurso"],
       p["origen"],
       p["destino"],
       p["cantidad"]
     ])}
  end

  defp filtrar(socket, f) do
    lista =
      Enum.filter(Fuente.recursos(), fn r ->
        (f["categoria"] == "" or to_string(r.categoria) == f["categoria"]) and
          (f["zona"] == "" or r.zona == f["zona"])
      end)

    socket |> assign(:recursos, lista) |> assign(:filtros, to_form(f, as: :filtro))
  end

  defp ubicaciones, do: Fuente.recursos() |> Enum.map(& &1.ubicacion) |> Enum.uniq()

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
      <.encabezado
        titulo="Recursos y centros de apoyo"
        subtitulo="Inventario por centro, entradas, salidas y transferencias."
      >
        <:acciones :if={Sesion.coordina?(@usuario)}>
          <button
            id="nuevo-recurso"
            class="btn btn-primary btn-sm"
            phx-click="abrir"
            phx-value-modal="recurso"
          >
            <.icon name="hero-plus" class="size-4" /> Registrar recurso
          </button>
          
          <button
            id="nuevo-movimiento"
            class="btn btn-sm"
            phx-click="abrir"
            phx-value-modal="movimiento"
          >
            <.icon name="hero-arrows-up-down" class="size-4" /> Entrada / salida
          </button>
          
          <button
            id="nueva-transferencia"
            class="btn btn-sm"
            phx-click="abrir"
            phx-value-modal="transferencia"
          >
            <.icon name="hero-arrows-right-left" class="size-4" /> Transferir
          </button>
        </:acciones>
      </.encabezado>
      
      <.form
        for={@filtros}
        id="filtros-recursos"
        phx-change="filtrar"
        class="mb-4 flex flex-wrap items-end gap-3"
      >
        <div class="w-48">
          <.input
            field={@filtros[:categoria]}
            type="select"
            label="Tipo de recurso"
            prompt="Todos"
            options={opciones(Fuente.tipos_necesidad())}
          />
        </div>
        
        <div class="w-48">
          <.input
            field={@filtros[:zona]}
            type="select"
            label="Zona"
            prompt="Todas"
            options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
          />
        </div>
      </.form>
      
      <div id="inventario" class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <.vacio :if={@recursos == []} mensaje="No hay recursos con esos filtros." />
        <article
          :for={r <- @recursos}
          id={"recurso-#{r.codigo}"}
          class={[
            "rounded-box border bg-base-100 p-4",
            if(r.cantidad < r.minimo, do: "border-error/50", else: "border-base-300")
          ]}
        >
          <div class="flex items-start justify-between gap-2">
            <div>
              <p class="text-xs text-base-content/60">{r.codigo} · {t(r.categoria)}</p>
              
              <h3 class="font-semibold">{r.nombre}</h3>
            </div>
            
            <span :if={r.cantidad < r.minimo} class="badge badge-sm badge-error badge-soft">Bajo mínimo</span>
          </div>
          
          <p class="mt-3 text-3xl font-semibold tabular-nums">
            {r.cantidad} <span class="text-sm font-normal text-base-content/60">{r.unidad}</span>
          </p>
          
          <progress
            class={[
              "progress mt-2 h-2 w-full",
              if(r.cantidad < r.minimo, do: "progress-error", else: "progress-success")
            ]}
            value={min(r.cantidad, r.minimo * 3)}
            max={r.minimo * 3}
          ></progress>
          <div class="mt-3 flex items-center justify-between text-xs text-base-content/60">
            <span><.icon name="hero-map-pin" class="size-3.5" /> {r.ubicacion} · {zona(r.zona)}</span>
            <span>mínimo {r.minimo}</span>
          </div>
          
          <div :if={Sesion.coordina?(@usuario)} class="mt-3 flex gap-2 border-t border-base-300 pt-3">
            <button
              class="btn btn-xs btn-ghost"
              phx-click="abrir"
              phx-value-modal="movimiento"
              phx-value-codigo={r.codigo}
            >Movimiento</button>
            <button
              class="btn btn-xs btn-ghost"
              phx-click="abrir"
              phx-value-modal="transferencia"
              phx-value-codigo={r.codigo}
            >Transferir</button>
          </div>
        </article>
      </div>
      
      <.panel titulo="Historial de movimientos" class="mt-6">
        <div class="overflow-x-auto">
          <table id="tabla-movimientos" class="table table-sm">
            <thead>
              <tr>
                <th>Fecha</th><th>Tipo</th><th>Recurso</th><th class="text-right">Cantidad</th><th>
                  Detalle
                </th><th>Usuario</th>
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
      
      <.modal id="modal-recurso" titulo="Registrar recurso" abierto={@modal == :recurso}>
        <.form for={@form} id="form-recurso" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:codigo]} label="Código" placeholder="R001" required />
            <.input field={@form[:nombre]} label="Nombre" placeholder="Agua potable" required />
            <.input
              field={@form[:categoria]}
              type="select"
              label="Categoría"
              options={opciones(Fuente.tipos_necesidad())}
            />
            <.input
              field={@form[:cantidad]}
              type="number"
              min="0"
              label="Cantidad disponible"
              required
            />
            <.input field={@form[:unidad]} label="Unidad de medida" placeholder="litros" required />
            <.input
              field={@form[:ubicacion]}
              label="Ubicación"
              placeholder="centro_acopio_1"
              required
            />
          </div>
           <.botones_form texto="Registrar" />
        </.form>
      </.modal>
      
      <.modal
        id="modal-movimiento"
        titulo="Registrar entrada o salida"
        abierto={@modal == :movimiento}
      >
        <.form for={@form} id="form-movimiento" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input
              field={@form[:tipo]}
              type="select"
              label="Tipo"
              options={[{"Entrada", "entry"}, {"Salida", "exit"}]}
            />
            <.input
              field={@form[:recurso]}
              type="select"
              label="Recurso"
              options={Enum.map(Fuente.recursos(), &{"#{&1.codigo} · #{&1.nombre}", &1.codigo})}
            />
          </div>
           <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad" required />
          <.input
            field={@form[:detalle]}
            label="Detalle"
            placeholder="Donación, entrega, ajuste…"
            required
          /> <.botones_form />
        </.form>
      </.modal>
      
      <.modal
        id="modal-transferencia"
        titulo="Transferir entre centros"
        abierto={@modal == :transferencia}
      >
        <.form for={@form} id="form-transferencia" phx-submit="guardar">
          <.input
            field={@form[:recurso]}
            type="select"
            label="Recurso"
            options={
              Enum.map(
                Fuente.recursos(),
                &{"#{&1.codigo} · #{&1.nombre} (#{&1.ubicacion})", &1.codigo}
              )
            }
          />
          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:origen]} type="select" label="Origen" options={ubicaciones()} />
            <.input field={@form[:destino]} label="Destino" placeholder="albergue_2" required />
          </div>
           <.input field={@form[:cantidad]} type="number" min="1" label="Cantidad" required />
          <.botones_form texto="Transferir" />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
