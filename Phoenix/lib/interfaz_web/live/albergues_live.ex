defmodule InterfazWeb.AlberguesLive do
  use InterfazWeb, :live_view

  alias Interfaz.Fuente
  alias InterfazWeb.Sesion

  on_mount {InterfazWeb.Sesion, {:pagina, :albergues}}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Albergues")
     |> assign(:modal, nil)
     |> assign(:albergue, nil)
     |> assign(:tipo_movimiento, "ingreso")
     |> assign(:form, to_form(%{}, as: :albergue))
     |> cargar()}
  end

  # Albergues y ranking salen de Epicenter.GestorAlbergue (Albergue.json).
  defp cargar(socket) do
    socket
    |> assign(:albergues, Fuente.albergues())
    |> assign(:ranking, Fuente.reporte_albergues())
  end

  def handle_event("nuevo", _, socket) do
    form = to_form(%{"zona" => socket.assigns.usuario.zona}, as: :albergue)
    {:noreply, socket |> assign(:modal, :albergue) |> assign(:form, form)}
  end

  def handle_event("movimiento", %{"codigo" => codigo, "tipo" => tipo}, socket) do
    albergue = Enum.find(socket.assigns.albergues, &(&1.codigo == codigo))
    form = to_form(%{"tipo" => tipo}, as: :movimiento)

    {:noreply,
     socket
     |> assign(:modal, :movimiento)
     |> assign(:albergue, albergue)
     |> assign(:tipo_movimiento, tipo)
     |> assign(:form, form)}
  end

  def handle_event("cerrar_modal", _, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"albergue" => p}, socket) do
    resultado = Fuente.registrar_albergue(p["nombre"], p["zona"], p["capacidad"])
    {:noreply, responder(socket, resultado)}
  end

  def handle_event("guardar", %{"movimiento" => p}, socket) do
    codigo = socket.assigns.albergue.codigo

    resultado =
      if socket.assigns.tipo_movimiento == "salida",
        do: Fuente.registrar_salida(codigo, p["documento"]),
        else: Fuente.registrar_ingreso(codigo, p["documento"], socket.assigns.usuario.usuario)

    {:noreply, responder(socket, resultado)}
  end

  # Éxito: recarga los albergues y cierra el modal. Error: muestra el motivo.
  defp responder(socket, {:ok, mensaje}),
    do: socket |> cargar() |> assign(:modal, nil) |> put_flash(:info, mensaje)

  defp responder(socket, {:error, mensaje}), do: put_flash(socket, :error, mensaje)

  # Ingreso: personas reportadas que no están ya en este albergue.
  # Salida: las personas que están dentro.
  defp opciones_movimiento(%{ocupantes: ocupantes}, "salida") do
    nombres = Map.new(Fuente.personas(), &{&1.documento, &1.nombre})
    Enum.map(ocupantes, &{"#{Map.get(nombres, &1, "Sin nombre")} · #{&1}", &1})
  end

  defp opciones_movimiento(%{ocupantes: ocupantes}, _ingreso) do
    for p <- Fuente.personas(), p.documento not in ocupantes do
      {"#{p.nombre} · #{p.documento}", p.documento}
    end
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

      <.vacio
        :if={@albergues == []}
        mensaje="Todavía no hay albergues registrados."
        icono="hero-home-modern"
      />

      <div :if={@albergues != []} class="grid gap-6 xl:grid-cols-[1fr_20rem]">
        <div id="lista-albergues" class="grid gap-4 sm:grid-cols-2">
          <article
            :for={a <- @albergues}
            id={"albergue-#{a.codigo}"}
            class="sx-card sx-foco p-5"
          >
            <div class="flex items-start justify-between gap-2">
              <div>
                <p class="text-xs text-base-content/60">{zona(a.zona, @zonas_por_codigo)}</p>

                <h3 class="text-lg font-semibold">{a.nombre}</h3>
              </div>

              <span :if={a.ocupacion >= a.capacidad} class="badge badge-error badge-soft badge-sm">Lleno</span>
            </div>

            <div class="mt-4 flex items-end justify-between">
              <p class="text-3xl font-semibold tabular-nums">{a.cupos}</p>

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
                <p class="mt-1 text-xs text-base-content/60">
                  {a.ocupacion} / {a.capacidad} ocupados
                </p>
              </div>
            </li>
          </ol>
        </.panel>
      </div>

      <.modal id="modal-albergue" titulo="Registrar albergue" abierto={@modal == :albergue}>
        <.form for={@form} id="form-albergue" phx-submit="guardar">
          <.input field={@form[:nombre]} label="Nombre" placeholder="Albergue Norte" required />
          <div class="grid grid-cols-2 gap-3">
            <.input
              field={@form[:capacidad]}
              type="number"
              min="1"
              label="Capacidad máxima"
              required
            />
            <.input
              field={@form[:zona]}
              type="select"
              label="Zona"
              options={Enum.map(Fuente.zonas(), &{&1.nombre, &1.codigo})}
            />
          </div>
          <p class="text-xs text-base-content/60">El código del albergue lo genera el sistema.</p>
          <.botones_form texto="Registrar" />
        </.form>
      </.modal>

      <.modal
        :if={@albergue}
        id="modal-movimiento-albergue"
        titulo={"#{@albergue.nombre} · #{if @tipo_movimiento == "salida", do: "registrar salida", else: "registrar ingreso"}"}
        abierto={@modal == :movimiento}
      >
        <p class="mb-3 text-sm text-base-content/70">
          {@albergue.cupos} cupos disponibles de {@albergue.capacidad}.
        </p>

        <.form for={@form} id="form-movimiento-albergue" phx-submit="guardar">
          <% opciones = opciones_movimiento(@albergue, @tipo_movimiento) %>
          <.vacio
            :if={opciones == []}
            mensaje={
              if @tipo_movimiento == "salida",
                do: "No hay personas en este albergue.",
                else: "No hay personas reportadas para ingresar. Repórtalas en «Personas y mensajes»."
            }
            icono="hero-user-group"
          />
          <.input
            :if={opciones != []}
            field={@form[:documento]}
            type="select"
            label="Persona"
            options={opciones}
          />
          <.botones_form texto="Registrar" />
        </.form>
      </.modal>
    </Layouts.app>
    """
  end
end
