defmodule InterfazWeb.PersonasLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.Accion

  on_mount {InterfazWeb.Sesion, {:pagina, :personas}}

  @busqueda_vacia %{"texto" => "", "zona" => "", "estado" => ""}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Personas y mensajes")
     |> assign(:modal, nil)
     |> assign(:form, to_form(%{}, as: :persona))
     |> assign(:mensaje_form, to_form(%{}, as: :mensaje))
     |> buscar(@busqueda_vacia)
     |> seleccionar(List.first(Fuente.personas()).documento)}
  end

  def handle_event("buscar", %{"busqueda" => b}, socket), do: {:noreply, buscar(socket, b)}

  def handle_event("seleccionar", %{"documento" => doc}, socket),
    do: {:noreply, seleccionar(socket, doc)}

  def handle_event("abrir", %{"modal" => "persona"}, socket) do
    form =
      to_form(%{"zona" => socket.assigns.usuario.zona, "estado" => "reportada"}, as: :persona)

    {:noreply, socket |> assign(:modal, :persona) |> assign(:form, form)}
  end

  def handle_event("abrir", %{"modal" => "estado"}, socket) do
    form = to_form(%{"estado" => to_string(socket.assigns.persona.estado)}, as: :estado)
    {:noreply, socket |> assign(:modal, :estado) |> assign(:form, form)}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"persona" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "report_person", [
       p["documento"],
       p["nombre"],
       p["edad"],
       p["zona"],
       p["estado"]
     ])}
  end

  def handle_event("guardar", %{"estado" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "update_person", [socket.assigns.persona.documento, p["estado"]])}
  end

  def handle_event("enviar_mensaje", %{"mensaje" => p}, socket) do
    socket =
      Accion.enviar(socket, "send_family_message", [
        socket.assigns.persona.documento,
        p["contenido"]
      ])

    {:noreply, assign(socket, :mensaje_form, to_form(%{}, as: :mensaje))}
  end

  def handle_event("marcar", %{"id" => id, "estado" => estado}, socket),
    do: {:noreply, Accion.enviar(socket, "mark_message", [id, estado])}

  defp buscar(socket, b) do
    texto = b["texto"] |> to_string() |> String.trim() |> String.downcase()

    lista =
      Enum.filter(Fuente.personas(), fn p ->
        (texto == "" or String.contains?(String.downcase(p.nombre), texto) or
           String.contains?(String.downcase(p.documento), texto)) and
          (b["zona"] == "" or p.zona == b["zona"]) and
          (b["estado"] == "" or to_string(p.estado) == b["estado"])
      end)

    socket |> assign(:personas, lista) |> assign(:busqueda, to_form(b, as: :busqueda))
  end

  defp seleccionar(socket, documento) do
    persona = Enum.find(Fuente.personas(), &(&1.documento == documento))
    mensajes = Enum.filter(Fuente.mensajes(), &(&1.destinatario == documento))
    socket |> assign(:persona, persona) |> assign(:mensajes, mensajes)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
      <.encabezado
        titulo="Personas y comunicación familiar"
        subtitulo="Busca personas afectadas y deja mensajes para sus familias."
      >
        <:acciones>
          <button
            id="reportar-persona"
            class="btn btn-primary btn-sm"
            phx-click="abrir"
            phx-value-modal="persona"
          >
            <.icon name="hero-user-plus" class="size-4" /> Reportar persona
          </button>
        </:acciones>
      </.encabezado>
      
      <div class="grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]">
        <div class="space-y-4">
          <.form
            for={@busqueda}
            id="busqueda-personas"
            phx-change="buscar"
            class="sx-card sx-foco p-4"
          >
            <.input
              field={@busqueda[:texto]}
              type="search"
              label="Nombre o documento"
              placeholder="Andrés, 1094…"
              phx-debounce="250"
            />
            <div class="grid grid-cols-2 gap-3">
              <.input
                field={@busqueda[:zona]}
                type="select"
                label="Zona"
                prompt="Todas"
                options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
              />
              <.input
                field={@busqueda[:estado]}
                type="select"
                label="Estado"
                prompt="Todos"
                options={opciones(Fuente.estados_persona())}
              />
            </div>
          </.form>
          
          <ul id="lista-personas" class="space-y-2">
            <li :if={@personas == []}>
              <.vacio mensaje="No se encontraron personas." icono="hero-magnifying-glass" />
            </li>
            
            <li :for={p <- @personas} id={"persona-#{p.id}"}>
              <button
                phx-click="seleccionar"
                phx-value-documento={p.documento}
                class={[
                  "flex w-full items-center gap-3 sx-vidrio rounded-box border px-4 py-3 text-left transition hover:border-primary/60",
                  if(@persona && @persona.documento == p.documento,
                    do: "border-primary ring-1 ring-primary",
                    else: "border-base-300"
                  )
                ]}
              >
                <div class="avatar avatar-placeholder">
                  <div class="w-9 rounded-full bg-base-300">
                    <span class="text-sm">{String.first(p.nombre)}</span>
                  </div>
                </div>
                
                <div class="min-w-0 flex-1">
                  <p class="truncate font-medium">{p.nombre}</p>
                  
                  <p class="text-xs text-base-content/60">Doc. {p.documento} · {zona(p.zona)}</p>
                </div>
                 <.insignia valor={p.estado} />
              </button>
            </li>
          </ul>
        </div>
        
        <div :if={@persona} id="detalle-persona" class="space-y-6">
          <.panel titulo={@persona.nombre}>
            <:acciones>
              <button
                id="cambiar-estado"
                class="btn btn-xs"
                phx-click="abrir"
                phx-value-modal="estado"
              >Cambiar estado</button>
            </:acciones>
            
            <dl class="grid grid-cols-2 gap-4 text-sm sm:grid-cols-4">
              <div>
                <dt class="text-base-content/60">Documento</dt><dd class="font-medium">
                  {@persona.documento}
                </dd>
              </div>
              
              <div>
                <dt class="text-base-content/60">Edad</dt><dd class="font-medium">
                  {@persona.edad} años
                </dd>
              </div>
              
              <div>
                <dt class="text-base-content/60">Zona</dt><dd class="font-medium">
                  {zona(@persona.zona)}
                </dd>
              </div>
              
              <div>
                <dt class="text-base-content/60">Estado</dt><dd>
                  <.insignia valor={@persona.estado} />
                </dd>
              </div>
            </dl>
            
            <h3 class="mt-6 mb-3 text-sm font-semibold">Historial de estado</h3>
            
            <ol id="historial-persona" class="relative ml-2 border-l border-base-300">
              <li :for={h <- Enum.reverse(@persona.historial)} class="mb-4 ml-4 last:mb-0">
                <span class="absolute -left-1.5 mt-1.5 size-3 rounded-full border-2 border-base-100 bg-primary"></span>
                <div class="flex flex-wrap items-center gap-2">
                  <.insignia valor={h.estado} />
                  <span class="text-xs text-base-content/60">{h.fecha} · por {h.por}</span>
                </div>
              </li>
            </ol>
          </.panel>
          
          <.panel titulo="Mensajes para la familia">
            <ul id="mensajes-persona" class="space-y-3">
              <li :if={@mensajes == []}>
                <.vacio
                  mensaje="Aún no hay mensajes para esta persona."
                  icono="hero-chat-bubble-left-right"
                />
              </li>
              
              <li :for={m <- @mensajes} id={"mensaje-#{m.id}"} class="rounded-box bg-base-200 p-3">
                <div class="flex flex-wrap items-center justify-between gap-2 text-xs text-base-content/60">
                  <span><span class="font-medium text-base-content">{m.remitente}</span> · {m.fecha}</span>
                  <div class="flex items-center gap-2">
                    <.insignia valor={m.estado} />
                    <button
                      class="btn btn-ghost btn-xs"
                      phx-click="marcar"
                      phx-value-id={m.id}
                      phx-value-estado={if m.estado == :entregado, do: "pendiente", else: "entregado"}
                    >
                      {if m.estado == :entregado, do: "Marcar pendiente", else: "Marcar entregado"}
                    </button>
                  </div>
                </div>
                
                <p class="mt-1 text-sm">{m.contenido}</p>
              </li>
            </ul>
            
            <.form
              for={@mensaje_form}
              id="form-mensaje"
              phx-submit="enviar_mensaje"
              class="mt-4 flex items-end gap-2"
            >
              <div class="flex-1">
                <.input
                  field={@mensaje_form[:contenido]}
                  label="Nuevo mensaje"
                  placeholder="Estoy bien, estoy en el albergue norte"
                  required
                />
              </div>
              
              <button class="btn btn-primary mb-2" phx-disable-with="Enviando...">
                <.icon name="hero-paper-airplane" class="size-4" /> Enviar
              </button>
            </.form>
          </.panel>
        </div>
      </div>
      
      <.modal id="modal-persona" titulo="Reportar persona afectada" abierto={@modal == :persona}>
        <.form for={@form} id="form-persona" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:documento]} label="Documento o referencia" required />
            <.input field={@form[:edad]} type="number" min="0" label="Edad" required />
          </div>
           <.input field={@form[:nombre]} label="Nombre completo" required />
          <div class="grid grid-cols-2 gap-3">
            <.input
              field={@form[:zona]}
              type="select"
              label="Zona"
              options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
            />
            <.input
              field={@form[:estado]}
              type="select"
              label="Estado"
              options={opciones(Fuente.estados_persona())}
            />
          </div>
           <.botones_form texto="Reportar" />
        </.form>
      </.modal>
      
      <.modal
        :if={@persona}
        id="modal-estado"
        titulo={"Estado de #{@persona.nombre}"}
        abierto={@modal == :estado}
      >
        <.form for={@form} id="form-estado" phx-submit="guardar">
          <.input
            field={@form[:estado]}
            type="select"
            label="Nuevo estado"
            options={opciones(Fuente.estados_persona())}
          />
          <p class="text-xs text-base-content/60">El cambio queda en el historial de la persona.</p>
           <.botones_form texto="Actualizar" />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
