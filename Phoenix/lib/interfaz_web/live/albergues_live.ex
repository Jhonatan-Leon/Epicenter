defmodule InterfazWeb.AlberguesLive do
  @moduledoc """
  Página de albergues. Datos de `Interfaz.Fuente.Albergues`; dibujo en
  `InterfazWeb.Gestiones.Albergues`.
  """
  use InterfazWeb, :live_view

  import InterfazWeb.Gestiones.Albergues

  alias Interfaz.Fuente.{Albergues, Personas}
  alias InterfazWeb.{Respuesta, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :albergues}}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Albergues")
     |> assign(:modal, nil)
     |> assign(:albergue, nil)
     |> assign(:tipo_movimiento, "ingreso")
     |> assign(:opciones_personas, [])
     |> assign(:form, to_form(%{}, as: :albergue))
     |> cargar()}
  end

  defp cargar(socket) do
    socket
    |> assign(:albergues, Albergues.albergues())
    |> assign(:ranking, Albergues.reporte())
  end

  def handle_event("nuevo", _params, socket) do
    form = to_form(%{"zona" => socket.assigns.usuario.zona}, as: :albergue)
    {:noreply, socket |> assign(:modal, :albergue) |> assign(:form, form)}
  end

  # Las personas se leen una vez, al abrir el modal, y no en cada render.
  def handle_event("movimiento", %{"codigo" => codigo, "tipo" => tipo}, socket) do
    albergue = Enum.find(socket.assigns.albergues, &(&1.codigo == codigo))

    {:noreply,
     socket
     |> assign(:modal, :movimiento)
     |> assign(:albergue, albergue)
     |> assign(:tipo_movimiento, tipo)
     |> assign(:opciones_personas, opciones_personas(albergue, tipo))
     |> assign(:form, to_form(%{}, as: :movimiento))}
  end

  def handle_event("cerrar_modal", _params, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"albergue" => datos}, socket) do
    resultado =
      Albergues.registrar(datos["nombre"], datos["zona"], datos["capacidad"], usuario(socket))

    responder(socket, resultado)
  end

  def handle_event("guardar", %{"movimiento" => datos}, socket) do
    codigo = socket.assigns.albergue.codigo

    resultado =
      if socket.assigns.tipo_movimiento == "salida",
        do: Albergues.registrar_salida(codigo, datos["documento"], usuario(socket)),
        else: Albergues.registrar_ingreso(codigo, datos["documento"], usuario(socket))

    responder(socket, resultado)
  end

  defp responder(socket, resultado),
    do: {:noreply, socket |> Respuesta.mostrar(resultado) |> cargar()}

  defp usuario(socket), do: socket.assigns.usuario.usuario

  # Salida: quienes están dentro. Ingreso: personas reportadas que no están aquí.
  defp opciones_personas(%{ocupantes: ocupantes}, "salida") do
    nombres = Map.new(Personas.personas(), &{&1.documento, &1.nombre})
    Enum.map(ocupantes, &{"#{Map.get(nombres, &1, "Sin nombre")} · #{&1}", &1})
  end

  defp opciones_personas(%{ocupantes: ocupantes}, _ingreso) do
    for persona <- Personas.personas(), persona.documento not in ocupantes do
      {"#{persona.nombre} · #{persona.documento}", persona.documento}
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
          <.tarjeta_albergue
            :for={albergue <- @albergues}
            albergue={albergue}
            zonas_por_codigo={@zonas_por_codigo}
            gestiona={Sesion.gestiona?(@usuario)}
          />
        </div>
        <.ranking_ocupacion ranking={@ranking} />
      </div>

      <.form_albergue form={@form} abierto={@modal == :albergue} opciones_zonas={@opciones_zonas} />
      <.form_movimiento_albergue
        form={@form}
        abierto={@modal == :movimiento}
        albergue={@albergue}
        tipo={@tipo_movimiento}
        opciones_personas={@opciones_personas}
      />
    </Layouts.app>
    """
  end
end
