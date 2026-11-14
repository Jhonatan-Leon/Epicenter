defmodule InterfazWeb.RecursosLive do
  @moduledoc """
  Página de recursos. Aquí solo hay estado y eventos; el dibujo está en
  `InterfazWeb.Gestiones.Recursos` y los datos en `Interfaz.Fuente.Recursos`.
  """
  use InterfazWeb, :live_view

  import InterfazWeb.Gestiones.Recursos

  alias Interfaz.Fuente.{Catalogos, Recursos}
  alias InterfazWeb.{Respuesta, Sesion}

  on_mount {InterfazWeb.Sesion, {:pagina, :recursos}}

  @filtros_vacios %{"categoria" => "", "zona" => ""}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Recursos")
     |> assign(:modal, nil)
     |> assign(:form, to_form(%{}, as: :recurso))
     |> assign(:filtros_actuales, @filtros_vacios)
     |> cargar()}
  end

  # Se lee la lógica una sola vez por cambio; todo lo demás se calcula de aquí.
  defp cargar(socket) do
    todos = Recursos.recursos()
    filtros = socket.assigns.filtros_actuales

    socket
    |> assign(:recursos, Enum.filter(todos, &cumple_filtros?(&1, filtros)))
    |> assign(:filtros, to_form(filtros, as: :filtro))
    |> assign(:opciones_recursos, opciones_recursos(todos))
    |> assign(:ubicaciones, todos |> Enum.map(& &1.ubicacion) |> Enum.uniq())
    |> assign(:movimientos, Recursos.movimientos())
  end

  def handle_event("filtrar", %{"filtro" => filtros}, socket),
    do: {:noreply, socket |> assign(:filtros_actuales, filtros) |> cargar()}

  def handle_event("abrir", %{"modal" => modal} = params, socket) do
    zona = socket.assigns.usuario.zona

    {modal, datos} =
      case modal do
        "recurso" -> {:recurso, %{"zona" => zona}}
        "movimiento" -> {:movimiento, %{"tipo" => "entrada", "recurso" => params["codigo"]}}
        "transferencia" -> {:transferencia, %{"recurso" => params["codigo"], "zona" => zona}}
      end

    {:noreply, socket |> assign(:modal, modal) |> assign(:form, to_form(datos, as: modal))}
  end

  def handle_event("cerrar_modal", _params, socket), do: {:noreply, assign(socket, :modal, nil)}

  def handle_event("guardar", %{"recurso" => datos}, socket),
    do: responder(socket, Recursos.registrar(datos, usuario(socket)))

  def handle_event("guardar", %{"movimiento" => %{"tipo" => "salida"} = datos}, socket) do
    socket
    |> responder(
      Recursos.registrar_salida(datos["recurso"], datos["cantidad"], datos["detalle"], usuario(socket))
    )
  end

  def handle_event("guardar", %{"movimiento" => datos}, socket),
    do: responder(socket, Recursos.registrar_entrada(datos["recurso"], datos["cantidad"], usuario(socket)))

  def handle_event("guardar", %{"transferencia" => datos}, socket) do
    socket
    |> responder(
      Recursos.transferir(
        datos["recurso"],
        datos["cantidad"],
        datos["destino"],
        datos["zona"],
        usuario(socket)
      )
    )
  end

  # Se recarga también si hubo error: un rechazo por falta de inventario queda en el historial.
  defp responder(socket, resultado),
    do: {:noreply, socket |> Respuesta.mostrar(resultado) |> cargar()}

  defp usuario(socket), do: socket.assigns.usuario.usuario

  defp cumple_filtros?(recurso, filtros) do
    (filtros["categoria"] in [nil, ""] or to_string(recurso.categoria) == filtros["categoria"]) and
      (filtros["zona"] in [nil, ""] or recurso.zona == filtros["zona"])
  end

  defp opciones_recursos(recursos) do
    for r <- recursos,
        do: {"#{r.codigo} · #{r.nombre} — #{r.cantidad} #{r.unidad} en #{r.ubicacion}", r.codigo}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      usuario={@usuario}
      activo={@activo}
      zonas_por_codigo={@zonas_por_codigo}
    >
      <.encabezado
        titulo="Recursos y centros de apoyo"
        subtitulo="Inventario por centro, entradas, salidas y transferencias."
      >
        <:acciones :if={Sesion.gestiona?(@usuario)}>
          <button
            id="nuevo-recurso"
            class="btn btn-primary btn-sm"
            phx-click="abrir"
            phx-value-modal="recurso"
          >
            <.icon name="hero-plus" class="size-4" /> Registrar recurso
          </button>
          <button id="nuevo-movimiento" class="btn btn-sm" phx-click="abrir" phx-value-modal="movimiento">
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

      <.form for={@filtros} id="filtros-recursos" phx-change="filtrar" class="mb-4 flex flex-wrap items-end gap-3">
        <div class="w-48">
          <.input
            field={@filtros[:categoria]}
            type="select"
            label="Tipo de recurso"
            prompt="Todos"
            options={opciones(Catalogos.categorias_recurso())}
          />
        </div>
        <div class="w-48">
          <.input
            field={@filtros[:zona]}
            type="select"
            label="Zona"
            prompt="Todas"
            options={@opciones_zonas}
          />
        </div>
      </.form>

      <div id="inventario" class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        <.vacio :if={@recursos == []} mensaje="No hay recursos con esos filtros." />
        <.tarjeta_recurso
          :for={recurso <- @recursos}
          recurso={recurso}
          zonas_por_codigo={@zonas_por_codigo}
          gestiona={Sesion.gestiona?(@usuario)}
        />
      </div>

      <.tabla_movimientos movimientos={@movimientos} />

      <.form_recurso form={@form} abierto={@modal == :recurso} opciones_zonas={@opciones_zonas} />
      <.form_movimiento
        form={@form}
        abierto={@modal == :movimiento}
        opciones_recursos={@opciones_recursos}
      />
      <.form_transferencia
        form={@form}
        abierto={@modal == :transferencia}
        opciones_recursos={@opciones_recursos}
        opciones_zonas={@opciones_zonas}
        ubicaciones={@ubicaciones}
      />
    </Layouts.app>
    """
  end
end
