defmodule InterfazWeb.ResumenLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente

  on_mount {InterfazWeb.Sesion, {:pagina, :resumen}}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Resumen")
     |> assign(:resumen, Fuente.resumen())
     |> assign(:pendientes, Enum.take(Fuente.necesidades_pendientes(), 5))
     |> assign(:criticos, Fuente.recursos_criticos())
     |> assign(
       :albergues,
       Enum.sort_by(Fuente.albergues(), &(&1.ocupacion / &1.capacidad), :desc)
     )
     |> assign(:zonas, Fuente.zonas())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
      <.encabezado
        titulo="Resumen de la emergencia"
        subtitulo="Estado global: recursos restantes, necesidades, personas, mensajes y mascotas."
      >
        <:acciones>
          <.link navigate={~p"/necesidades"} class="btn btn-primary btn-sm">
            <.icon name="hero-plus" class="size-4" /> Registrar necesidad
          </.link>
        </:acciones>
      </.encabezado>

      <div id="indicadores" class="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <.indicador
          titulo="Necesidades abiertas"
          valor={@resumen.necesidades_pendientes}
          detalle={"#{@resumen.necesidades_criticas} con prioridad crítica"}
          icono="hero-lifebuoy"
          tono="text-error"
        />
        <.indicador
          titulo="Recursos críticos"
          valor={@resumen.recursos_criticos}
          detalle={"de #{@resumen.recursos_total} recursos registrados"}
          icono="hero-cube"
          tono="text-warning"
        />
        <.indicador
          titulo="Personas localizadas"
          valor={@resumen.personas_localizadas}
          detalle={"de #{@resumen.personas_total} reportadas · #{@resumen.mensajes_pendientes} mensajes por entregar"}
          icono="hero-user-group"
          tono="text-info"
        />
        <.indicador
          titulo="Ocupación de albergues"
          valor={"#{@resumen.ocupacion}/#{@resumen.capacidad}"}
          detalle={"#{@resumen.mascotas_activas} reportes de mascotas activos"}
          icono="hero-home-modern"
          tono="text-success"
        />
      </div>

      <div class="mt-6 grid gap-6 xl:grid-cols-3">
        <.panel titulo="Necesidades por atender" class="xl:col-span-2">
          <:acciones>
            <.link navigate={~p"/necesidades"} class="btn btn-ghost btn-xs">Ver todas</.link>
          </:acciones>
          <ul id="necesidades-pendientes" class="divide-y divide-base-300">
            <li :for={n <- @pendientes} id={"pendiente-#{n.id}"} class="flex items-center gap-3 py-3">
              <.insignia valor={n.prioridad} />
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-medium">
                  {t(n.tipo)} · {n.cantidad} — {n.descripcion}
                </p>
                <p class="text-xs text-base-content/60">
                  {n.id} · {zona(n.zona)} · reportó {n.responsable}
                </p>
              </div>
              <.insignia valor={n.estado} />
            </li>
          </ul>
        </.panel>

        <.panel titulo="Recursos bajo el mínimo">
          <.vacio
            :if={@criticos == []}
            mensaje="Ningún recurso está bajo el mínimo."
            icono="hero-check-circle"
          />
          <ul id="recursos-criticos" class="space-y-4">
            <li :for={r <- @criticos} id={"critico-#{r.codigo}"}>
              <div class="flex items-baseline justify-between gap-2 text-sm">
                <span class="font-medium">{r.nombre}</span>
                <span class="tabular-nums text-base-content/70">{r.cantidad} / {r.minimo} {r.unidad}</span>
              </div>
              <progress
                class="progress progress-error mt-1 h-2 w-full"
                value={r.cantidad}
                max={r.minimo}
              ></progress>
              <p class="mt-1 text-xs text-base-content/60">{r.codigo} · {r.ubicacion}</p>
            </li>
          </ul>
        </.panel>

        <.panel titulo="Albergues con mayor ocupación" class="xl:col-span-2">
          <div id="albergues-ocupacion" class="space-y-3">
            <div
              :for={a <- @albergues}
              id={"ocupacion-#{a.codigo}"}
              class="grid grid-cols-[8rem_1fr] items-center gap-3 sm:grid-cols-[12rem_1fr_5rem]"
            >
              <p class="truncate text-sm font-medium">{a.nombre}</p>
              <.barra valor={a.ocupacion} maximo={a.capacidad} />
              <p class="hidden text-right text-xs tabular-nums text-base-content/60 sm:block">
                {a.ocupacion}/{a.capacidad}
              </p>
            </div>
          </div>
        </.panel>

        <.panel titulo="Zonas afectadas">
          <ul id="zonas-resumen" class="space-y-3">
            <li :for={z <- @zonas} class="flex items-center justify-between gap-2">
              <div>
                <p class="text-sm font-medium">{z.nombre}</p>
                <p class="text-xs text-base-content/60">{z.afectadas} personas afectadas</p>
              </div>
              <.insignia valor={z.nivel} />
            </li>
          </ul>
        </.panel>
      </div>
    </Layouts.app>
    """
  end
end
