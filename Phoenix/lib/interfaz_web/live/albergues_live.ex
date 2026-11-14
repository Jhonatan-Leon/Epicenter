defmodule InterfazWeb.AlberguesLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.{Accion, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :albergues}}

  def mount(_params, _session, socket) do
    albergues = Fuente.albergues()

    {:ok,
     socket
     |> assign(:page_title, "Albergues")
     |> assign(:albergues, albergues)
     |> assign(:ranking, Enum.sort_by(albergues, &(&1.ocupacion / &1.capacidad), :desc))
     |> assign(:modal, nil)
     |> assign(:albergue, nil)
     |> assign(:form, to_form(%{}, as: :albergue))}
  end

  def handle_event("nuevo", _, socket),
    do:
      {:noreply,
       socket |> assign(:modal, :albergue) |> assign(:form, to_form(%{}, as: :albergue))}

  def handle_event("movimiento", %{"codigo" => codigo, "tipo" => tipo}, socket) do
    albergue = Enum.find(socket.assigns.albergues, &(&1.codigo == codigo))
    form = to_form(%{"tipo" => tipo}, as: :movimiento)

    {:noreply,
     socket |> assign(:modal, :movimiento) |> assign(:albergue, albergue) |> assign(:form, form)}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"albergue" => p}, socket) do
    {:noreply,
     Accion.enviar(socket, "register_shelter", [
       p["codigo"],
       p["nombre"],
       p["zona"],
       p["capacidad"]
     ])}
  end

  def handle_event("guardar", %{"movimiento" => p}, socket) do
    accion = if p["tipo"] == "salida", do: "register_exit", else: "register_entry"
    {:noreply, Accion.enviar(socket, accion, [socket.assigns.albergue.codigo, p["documento"]])}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      usuario={@usuario}
      activo={@activo}
      zonas_por_codigo={@zonas_por_codigo}
    >
      <.encabezado titulo="Albergues" subtitulo="Capacidad, ocupación actual y cupos disponibles.">
        <:acciones :if={Sesion.administra?(@usuario)}>
          <button id="nuevo-albergue" class="btn btn-primary btn-sm" phx-click="nuevo">
            <.icon name="hero-plus" class="size-4" /> Registrar albergue
          </button>
        </:acciones>
      </.encabezado>

      <div class="grid gap-6 xl:grid-cols-[1fr_20rem]">
        <div id="lista-albergues" class="grid gap-4 sm:grid-cols-2">
          <article
            :for={a <- @albergues}
            id={"albergue-#{a.codigo}"}
            class="sx-card sx-foco p-5"
          >
            <div class="flex items-start justify-between gap-2">
              <div>
                <p class="text-xs text-base-content/60">
                  {a.codigo} · {zona(a.zona, @zonas_por_codigo)}
                </p>

                <h3 class="text-lg font-semibold">{a.nombre}</h3>
              </div>

              <span :if={a.ocupacion >= a.capacidad} class="badge badge-error badge-soft badge-sm">Lleno</span>
            </div>

            <div class="mt-4 flex items-end justify-between">
              <p class="text-3xl font-semibold tabular-nums">{a.capacidad - a.ocupacion}</p>

              <p class="text-sm text-base-content/60">{a.ocupacion} / {a.capacidad} ocupados</p>
            </div>

            <p class="text-xs text-base-content/60">cupos disponibles</p>
            <.barra valor={a.ocupacion} maximo={a.capacidad} class="mt-3" />
            <div :if={Sesion.gestiona?(@usuario)} class="mt-4 flex gap-2">
              <button
                id={"ingreso-#{a.codigo}"}
                class="btn btn-sm btn-primary btn-soft flex-1"
                phx-click="movimiento"
                phx-value-codigo={a.codigo}
                phx-value-tipo="ingreso"
                disabled={a.ocupacion >= a.capacidad}
              >
                <.icon name="hero-arrow-down-on-square" class="size-4" /> Ingreso
              </button>

              <button
                id={"salida-#{a.codigo}"}
                class="btn btn-sm btn-ghost flex-1"
                phx-click="movimiento"
                phx-value-codigo={a.codigo}
                phx-value-tipo="salida"
                disabled={a.ocupacion == 0}
              >
                <.icon name="hero-arrow-up-on-square" class="size-4" /> Salida
              </button>
            </div>
          </article>
        </div>

        <.panel titulo="Mayor nivel de ocupación">
          <ol id="ranking-albergues" class="space-y-4">
            <li :for={{a, i} <- Enum.with_index(@ranking, 1)} class="flex gap-3">
              <span class="grid size-7 shrink-0 place-items-center rounded-full bg-base-200 text-sm font-semibold">{i}</span>
              <div class="min-w-0 flex-1">
                <p class="truncate text-sm font-medium">{a.nombre}</p>
                <.barra valor={a.ocupacion} maximo={a.capacidad} />
              </div>
            </li>
          </ol>
        </.panel>
      </div>

      <.modal id="modal-albergue" titulo="Registrar albergue" abierto={@modal == :albergue}>
        <.form for={@form} id="form-albergue" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input field={@form[:codigo]} label="Código" placeholder="A01" required />
            <.input
              field={@form[:capacidad]}
              type="number"
              min="1"
              label="Capacidad máxima"
              required
            />
          </div>
          <.input field={@form[:nombre]} label="Nombre" placeholder="Albergue Norte" required />
          <.input
            field={@form[:zona]}
            type="select"
            label="Zona"
            options={@opciones_zonas}
          /> <.botones_form texto="Registrar" />
        </.form>
      </.modal>

      <.modal
        :if={@albergue}
        id="modal-movimiento-albergue"
        titulo={"#{@albergue.nombre} · registrar movimiento"}
        abierto={@modal == :movimiento}
      >
        <p class="mb-3 text-sm text-base-content/70">
          {@albergue.capacidad - @albergue.ocupacion} cupos disponibles de {@albergue.capacidad}.
        </p>

        <.form for={@form} id="form-movimiento-albergue" phx-submit="guardar">
          <div class="grid grid-cols-2 gap-3">
            <.input
              field={@form[:tipo]}
              type="select"
              label="Tipo"
              options={[{"Ingreso", "ingreso"}, {"Salida", "salida"}]}
            /> <.input field={@form[:documento]} label="Documento de la persona" required />
          </div>
          <.botones_form texto="Registrar" />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
