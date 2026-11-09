defmodule InterfazWeb.ActividadLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente

  on_mount {InterfazWeb.Sesion, {:pagina, :actividad}}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Usuarios y actividad")
     |> assign(:usuarios, Fuente.usuarios())
     |> assign(:filtro, "")
     |> assign(:actividad, Fuente.actividad())}
  end

  def handle_event("filtrar", %{"usuario" => usuario}, socket) do
    actividad =
      if usuario == "",
        do: Fuente.actividad(),
        else: Enum.filter(Fuente.actividad(), &(&1.usuario == usuario))

    {:noreply, socket |> assign(:filtro, usuario) |> assign(:actividad, actividad)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
      <.encabezado
        titulo="Usuarios y actividad"
        subtitulo="Quién está conectado y qué operaciones ha realizado cada usuario."
      />
      <div class="grid gap-6 xl:grid-cols-[22rem_1fr]">
        <.panel titulo="Usuarios">
          <ul id="lista-usuarios" class="space-y-1">
            <li>
              <button
                phx-click="filtrar"
                phx-value-usuario=""
                class={[
                  "flex w-full items-center rounded-field px-3 py-2 text-left text-sm hover:bg-base-200",
                  @filtro == "" && "bg-base-200 font-medium"
                ]}
              >
                Todos los usuarios
              </button>
            </li>
            
            <li :for={u <- @usuarios} id={"usuario-#{u.usuario}"}>
              <button
                phx-click="filtrar"
                phx-value-usuario={u.usuario}
                class={[
                  "flex w-full items-center gap-3 rounded-field px-3 py-2 text-left hover:bg-base-200",
                  @filtro == u.usuario && "bg-base-200"
                ]}
              >
                <span
                  class={[
                    "size-2 shrink-0 rounded-full",
                    if(u.conectado, do: "bg-success", else: "bg-base-300")
                  ]}
                  title={if u.conectado, do: "Conectado", else: "Desconectado"}
                ></span>
                <div class="min-w-0 flex-1">
                  <p class="truncate text-sm font-medium">{u.nombre}</p>
                  
                  <p class="text-xs text-base-content/60">{u.usuario} · {zona(u.zona)}</p>
                </div>
                 <span class="badge badge-sm badge-ghost">{t(u.rol)}</span>
              </button>
            </li>
          </ul>
        </.panel>
        
        <.panel titulo="Registro de actividad">
          <ol id="registro-actividad" class="space-y-3">
            <li :if={@actividad == []}>
              <.vacio mensaje="Este usuario no tiene actividad registrada." />
            </li>
            
            <li :for={{a, i} <- Enum.with_index(@actividad)} id={"actividad-#{i}"} class="flex gap-3">
              <.icon
                name={if a.resultado == :ok, do: "hero-check-circle", else: "hero-x-circle"}
                class={[
                  "mt-0.5 size-5 shrink-0",
                  if(a.resultado == :ok, do: "text-success", else: "text-error")
                ]}
              />
              <div class="min-w-0 flex-1">
                <p class="break-all font-mono text-sm">{a.accion}</p>
                
                <p class="text-xs text-base-content/60">
                  {a.fecha} · {a.usuario}<span :if={a.detalle}> · {a.detalle}</span>
                </p>
              </div>
            </li>
          </ol>
        </.panel>
      </div>
    </Layouts.app>
    """
  end
end
