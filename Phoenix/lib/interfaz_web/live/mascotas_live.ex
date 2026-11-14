defmodule InterfazWeb.MascotasLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.Sesion

  on_mount {InterfazWeb.Sesion, {:pagina, :mascotas}}

  @filtros_vacios %{"especie" => "", "zona" => "", "estado" => ""}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Mascotas")
     |> assign(:modal, nil)
     |> assign(:form, to_form(%{}, as: :mascota))
     |> filtrar(@filtros_vacios)}
  end

  def handle_event("filtrar", %{"filtro" => f}, socket), do: {:noreply, filtrar(socket, f)}

  def handle_event("abrir", %{"reporte" => reporte}, socket) do
    form = to_form(%{"reporte" => reporte, "zona" => socket.assigns.usuario.zona}, as: :mascota)
    {:noreply, socket |> assign(:modal, :mascota) |> assign(:form, form)}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  # Cada acción llama a Fuente, que usa Epicenter.GestorMascota y guarda Mascota.json.
  def handle_event("guardar", %{"mascota" => p}, socket),
    do: {:noreply, responder(socket, Fuente.reportar_mascota(p))}

  def handle_event("buscar_coincidencias", _, socket),
    do: {:noreply, responder(socket, Fuente.buscar_coincidencias())}

  def handle_event("confirmar", %{"perdida" => a, "encontrada" => b}, socket),
    do: {:noreply, responder(socket, Fuente.confirmar_coincidencia(a, b))}

  # Éxito: recarga los reportes y las coincidencias, y cierra el modal.
  # Error: deja el modal abierto con lo escrito y muestra el motivo.
  defp responder(socket, {:ok, mensaje}) do
    socket
    |> filtrar(socket.assigns.filtros.params)
    |> assign(:modal, nil)
    |> put_flash(:info, mensaje)
  end

  defp responder(socket, {:error, mensaje}), do: put_flash(socket, :error, mensaje)

  defp filtrar(socket, f) do
    lista = Fuente.consultar_mascotas(f)

    socket
    |> assign(:todas, Fuente.mascotas())
    |> assign(:coincidencias, Fuente.coincidencias())
    |> assign(:perdidas, Enum.filter(lista, &(&1.reporte == :perdida)))
    |> assign(:encontradas, Enum.filter(lista, &(&1.reporte == :encontrada)))
    |> assign(:filtros, to_form(f, as: :filtro))
  end

  defp nombre_mascota(todas, id) do
    case Enum.find(todas, &(&1.id == id)) do
      %{nombre: nombre} when is_binary(nombre) -> nombre
      _sin_nombre -> "Sin nombre"
    end
  end

  attr :m, :map, required: true

  defp tarjeta(assigns) do
    ~H"""
    <article id={"mascota-#{@m.id}"} class="sx-card sx-foco p-4">
      <div class="flex items-start justify-between gap-2">
        <div class="flex items-center gap-3">
          <span class="grid size-10 place-items-center rounded-full bg-base-200">
            <.icon
              name={if @m.especie == :gato, do: "hero-sparkles", else: "hero-heart"}
              class="size-5 text-primary"
            />
          </span>
          
          <div>
            <p class="font-semibold">{@m.nombre || "Sin nombre"}</p>
            
            <p class="text-xs text-base-content/60">{@m.id} · {t(@m.especie)} · {zona(@m.zona)}</p>
          </div>
        </div>
         <.insignia valor={@m.estado} />
      </div>
      
      <div class="mt-3 flex flex-wrap gap-1.5 text-xs">
        <span class="badge badge-sm badge-outline">Color: {@m.color}</span>
        <span class="badge badge-sm badge-outline">Tamaño: {t(@m.tamano)}</span>
      </div>
      
      <p class="mt-2 text-sm text-base-content/80">{@m.caracteristicas}</p>
      
      <p class="mt-2 text-xs text-base-content/60">
        <.icon name="hero-phone" class="size-3.5" /> {@m.contacto}
      </p>
    </article>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
      <.encabezado
        titulo="Mascotas perdidas y encontradas"
        subtitulo="Reportes de la emergencia y posibles coincidencias por similitud."
      >
        <:acciones>
          <button
            id="reportar-perdida"
            class="btn btn-primary btn-sm"
            phx-click="abrir"
            phx-value-reporte="perdida"
          >
            <.icon name="hero-plus" class="size-4" /> Mascota perdida
          </button>
          
          <button
            id="reportar-encontrada"
            class="btn btn-sm"
            phx-click="abrir"
            phx-value-reporte="encontrada"
          >
            <.icon name="hero-plus" class="size-4" /> Mascota encontrada
          </button>
        </:acciones>
      </.encabezado>
      
      <.panel titulo="Posibles coincidencias" class="mb-6">
        <:acciones>
          <button id="buscar-coincidencias" class="btn btn-xs" phx-click="buscar_coincidencias">
            <.icon name="hero-arrow-path" class="size-3.5" /> Buscar de nuevo
          </button>
        </:acciones>
        
        <.vacio
          :if={@coincidencias == []}
          mensaje="Sin coincidencias de 40 puntos o más entre perdidas y encontradas."
          icono="hero-arrows-right-left"
        />
        <div id="coincidencias" class="grid gap-4 md:grid-cols-2">
          <div
            :for={c <- @coincidencias}
            id={"coincidencia-#{c.perdida}-#{c.encontrada}"}
            class="rounded-box border border-base-300 p-4"
          >
            <div class="flex items-center justify-between gap-2">
              <p class="text-sm">
                <span class="font-semibold">{nombre_mascota(@todas, c.perdida)}</span>
                (perdida)
                <.icon name="hero-arrows-right-left" class="mx-1 size-4 text-base-content/50" />
                {nombre_mascota(@todas, c.encontrada)} (encontrada)
              </p>

              <%!-- 70 o más: la lógica la marca como posible coincidencia; 40 o más: candidata --%>
              <span class={[
                "text-2xl font-semibold tabular-nums",
                cond do
                  c.puntaje >= 70 -> "text-success"
                  c.puntaje >= 40 -> "text-warning"
                  true -> "text-base-content/50"
                end
              ]}>{c.puntaje}%</span>
            </div>
            
            <ul class="mt-3 flex flex-wrap gap-1.5">
              <li
                :for={{criterio, coincide} <- c.criterios}
                class={[
                  "badge badge-sm",
                  if(coincide, do: "badge-success badge-soft", else: "badge-ghost line-through")
                ]}
              >
                {t(criterio)}
              </li>
            </ul>
            
            <div :if={Sesion.gestiona?(@usuario)} class="mt-3 flex justify-end">
              <button
                id={"confirmar-#{c.perdida}-#{c.encontrada}"}
                class="btn btn-success btn-sm btn-soft"
                phx-click="confirmar"
                phx-value-perdida={c.perdida}
                phx-value-encontrada={c.encontrada}
                data-confirm="Se cerrarán ambos reportes. ¿Confirmar coincidencia?"
              >
                <.icon name="hero-check" class="size-4" /> Confirmar y cerrar ambos
              </button>
            </div>
          </div>
        </div>
      </.panel>
      
      <.form
        for={@filtros}
        id="filtros-mascotas"
        phx-change="filtrar"
        class="mb-4 flex flex-wrap items-end gap-3"
      >
        <div class="w-40">
          <.input
            field={@filtros[:especie]}
            type="select"
            label="Especie"
            prompt="Todas"
            options={opciones(Fuente.especies())}
          />
        </div>
        
        <div class="w-40">
          <.input
            field={@filtros[:zona]}
            type="select"
            label="Zona"
            prompt="Todas"
            options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
          />
        </div>
        
        <div class="w-48">
          <.input
            field={@filtros[:estado]}
            type="select"
            label="Estado"
            prompt="Todos"
            options={opciones(Fuente.estados_mascota())}
          />
        </div>
      </.form>
      
      <div class="grid gap-6 lg:grid-cols-2">
        <section id="perdidas">
          <h2 class="mb-3 flex items-center gap-2 font-semibold">
            <span class="size-2 rounded-full bg-error"></span>
            Perdidas
            <span class="text-sm font-normal text-base-content/60">({length(@perdidas)})</span>
          </h2>
          
          <div class="space-y-3">
            <.vacio :if={@perdidas == []} mensaje="Sin reportes con esos filtros." />
            <.tarjeta :for={m <- @perdidas} m={m} />
          </div>
        </section>
        
        <section id="encontradas">
          <h2 class="mb-3 flex items-center gap-2 font-semibold">
            <span class="size-2 rounded-full bg-success"></span>
            Encontradas
            <span class="text-sm font-normal text-base-content/60">({length(@encontradas)})</span>
          </h2>
          
          <div class="space-y-3">
            <.vacio :if={@encontradas == []} mensaje="Sin reportes con esos filtros." />
            <.tarjeta :for={m <- @encontradas} m={m} />
          </div>
        </section>
      </div>
      
      <.modal id="modal-mascota" titulo="Reportar mascota" abierto={@modal == :mascota}>
        <.form for={@form} id="form-mascota" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input
              field={@form[:reporte]}
              type="select"
              label="Tipo de reporte"
              options={opciones([:perdida, :encontrada])}
            />
            <.input
              field={@form[:especie]}
              type="select"
              label="Especie"
              options={opciones(Fuente.especies())}
            /> <.input field={@form[:nombre]} label="Nombre (si se conoce)" placeholder="Luna" />
            <.input field={@form[:color]} label="Color" required />
            <.input
              field={@form[:tamano]}
              type="select"
              label="Tamaño"
              options={opciones(Fuente.tamanos())}
            />
            <.input
              field={@form[:zona]}
              type="select"
              label="Zona"
              options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
            />
          </div>
          
          <.input field={@form[:caracteristicas]} type="textarea" rows="2" label="Características" />
          <.input field={@form[:contacto]} label="Contacto" required />
          <.botones_form texto="Reportar" />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
