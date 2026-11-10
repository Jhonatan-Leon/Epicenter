defmodule InterfazWeb.ZonasLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.{Accion, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :zonas}}

  def mount(_params, _session, socket) do
    zonas = Fuente.zonas()

    {:ok,
     socket
     |> assign(:page_title, "Zonas")
     |> assign(:zonas, zonas)
     |> assign(:seleccion, List.first(zonas).codigo)
     |> assign(:modal, nil)
     |> assign(:form, to_form(%{}, as: :zona))}
  end

  def handle_event("seleccionar", %{"codigo" => codigo}, socket),
    do: {:noreply, assign(socket, :seleccion, codigo)}

  def handle_event("abrir", %{"modal" => modal}, socket) do
    modal = String.to_existing_atom(modal)
    {:noreply, socket |> assign(:modal, modal) |> assign(:form, to_form(%{}, as: modal))}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"zona" => p}, socket),
    do: {:noreply, Accion.enviar(socket, "register_zone", [p["nombre"], p["nivel"]])}

  def handle_event("guardar", %{"sector" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "register_sector", [
       p["zona"],
       p["codigo"],
       p["nombre"],
       p["nivel"],
       p["afectadas"]
     ])}
  end

  def handle_event("guardar", %{"punto" => p}, socket),
    do:
      {:noreply, Accion.enviar(socket, "register_point", [p["sector"], p["codigo"], p["nombre"]])}

  def render(assigns) do
    zona = Enum.find(assigns.zonas, &(&1.codigo == assigns.seleccion))
    assigns = assign(assigns, zona: zona, estadisticas: Fuente.estadisticas_zona(zona.codigo))

    ~H"""
    <Layouts.app flash={@flash} usuario={@usuario} activo={@activo}>
      <.encabezado
        titulo="Zonas afectadas"
        subtitulo="Estructura zona → sectores → puntos de atención."
      >
        <:acciones :if={Sesion.coordina?(@usuario)}>
          <button
            id="nueva-zona"
            class="btn btn-primary btn-sm"
            phx-click="abrir"
            phx-value-modal="zona"
          >
            <.icon name="hero-plus" class="size-4" /> Zona
          </button>
          
          <button id="nuevo-sector" class="btn btn-sm" phx-click="abrir" phx-value-modal="sector">Sector</button>
          <button id="nuevo-punto" class="btn btn-sm" phx-click="abrir" phx-value-modal="punto">Punto de atención</button>
        </:acciones>
      </.encabezado>
      
      <div class="grid gap-6 lg:grid-cols-[20rem_1fr]" data-sx-nivel={@zona.nivel}>
        <nav id="lista-zonas" class="space-y-2" aria-label="Zonas">
          <button
            :for={z <- @zonas}
            id={"zona-#{z.codigo}"}
            phx-click="seleccionar"
            phx-value-codigo={z.codigo}
            class={[
              "flex w-full items-center justify-between gap-2 sx-vidrio rounded-box border px-4 py-3 text-left transition hover:border-primary/60",
              if(z.codigo == @seleccion,
                do: "border-primary ring-1 ring-primary",
                else: "border-base-300"
              )
            ]}
          >
            <div>
              <p class="font-medium">{z.nombre}</p>
              
              <p class="text-xs text-base-content/60">
                {length(z.sectores)} sectores · {z.afectadas} afectadas
              </p>
            </div>
             <.insignia valor={z.nivel} />
          </button>
        </nav>
        
        <div class="space-y-6">
          <div id="estadisticas-zona" class="sx-escalonar grid grid-cols-2 gap-4 2xl:grid-cols-4">
            <.indicador titulo="Personas afectadas" valor={@zona.afectadas} icono="hero-users" />
            <.indicador
              titulo="Sectores · puntos"
              valor={"#{@estadisticas.sectores} · #{@estadisticas.puntos}"}
              icono="hero-map-pin"
              tono="text-info"
            />
            <.indicador
              titulo="Necesidades abiertas"
              valor={@estadisticas.necesidades}
              icono="hero-lifebuoy"
              tono="text-error"
            />
            <.indicador
              titulo="Cupos en albergues"
              valor={@estadisticas.cupos}
              icono="hero-home-modern"
              tono="text-success"
            />
          </div>
          
          <.panel titulo={"Estructura de #{@zona.nombre}"}>
            <:acciones><.insignia valor={@zona.nivel} /></:acciones>
            
            <.vacio
              :if={@zona.sectores == []}
              mensaje="Esta zona aún no tiene sectores registrados."
              icono="hero-map"
            />
            <ul id="arbol-zona" class="space-y-3">
              <li
                :for={s <- @zona.sectores}
                id={"sector-#{s.codigo}"}
                class="rounded-box border border-base-300"
              >
                <div class="flex flex-wrap items-center justify-between gap-2 bg-base-200/60 px-4 py-2">
                  <div class="flex items-center gap-2">
                    <.icon name="hero-squares-2x2" class="size-4 text-base-content/60" />
                    <span class="font-medium">{s.nombre}</span>
                    <span class="text-xs text-base-content/60">{s.codigo}</span>
                  </div>
                  
                  <div class="flex items-center gap-3 text-xs text-base-content/70">
                    {s.afectadas} afectadas <.insignia valor={s.nivel} />
                  </div>
                </div>
                
                <ul class="px-4 py-2">
                  <li :if={s.puntos == []} class="py-1 text-sm text-base-content/50">
                    Sin puntos de atención
                  </li>
                  
                  <li
                    :for={p <- s.puntos}
                    id={"punto-#{p.codigo}"}
                    class="flex items-center gap-2 border-l-2 border-base-300 py-1 pl-4 text-sm"
                  >
                    <.icon name="hero-map-pin" class="size-4 text-primary" /> {p.nombre}
                    <span class="text-xs text-base-content/50">{p.codigo}</span>
                  </li>
                </ul>
              </li>
            </ul>
          </.panel>
        </div>
      </div>
      
      <.modal id="modal-zona" titulo="Registrar zona" abierto={@modal == :zona}>
        <.form for={@form} id="form-zona" phx-submit="guardar">
          <.input field={@form[:nombre]} label="Nombre" placeholder="Norte" required />
          <.input
            field={@form[:nivel]}
            type="select"
            label="Nivel de afectación"
            options={opciones(Fuente.niveles())}
          />
          <p class="text-xs text-base-content/60">El código de la zona lo genera el sistema.</p>
           <.botones_form texto="Registrar" />
        </.form>
      </.modal>
      
      <.modal id="modal-sector" titulo="Registrar sector" abierto={@modal == :sector}>
        <.form for={@form} id="form-sector" phx-submit="guardar">
          <.input
            field={@form[:zona]}
            type="select"
            label="Zona"
            options={Enum.map(@zonas, &{&1.nombre, &1.codigo})}
          />
          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:codigo]} label="Código" required />
            <.input field={@form[:nombre]} label="Nombre" required />
            <.input
              field={@form[:nivel]}
              type="select"
              label="Nivel"
              options={opciones(Fuente.niveles())}
            />
            <.input
              field={@form[:afectadas]}
              type="number"
              min="0"
              label="Personas afectadas"
              required
            />
          </div>
           <.botones_form />
        </.form>
      </.modal>
      
      <.modal id="modal-punto" titulo="Registrar punto de atención" abierto={@modal == :punto}>
        <.form for={@form} id="form-punto" phx-submit="guardar">
          <.input
            field={@form[:sector]}
            type="select"
            label="Sector"
            options={for z <- @zonas, s <- z.sectores, do: {"#{z.nombre} · #{s.nombre}", s.codigo}}
          />
          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:codigo]} label="Código" required />
            <.input field={@form[:nombre]} label="Nombre" required />
          </div>
           <.botones_form />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
