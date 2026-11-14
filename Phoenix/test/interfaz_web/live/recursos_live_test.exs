defmodule InterfazWeb.RecursosLiveTest do
  # Escribe en Recurso.json e Historial.json de la lógica: no corre en paralelo y
  # deja los archivos como estaban.
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias InterfazWeb.DatosPrueba

  @archivos ~w(Recurso.json Historial.json)
  @norte "B7D24E901FA3C665"

  setup do
    DatosPrueba.preparar(@archivos, [DatosPrueba.usuario("laura", "administrador", "Norte")])
    :ok
  end

  defp abrir(conn) do
    conn =
      init_test_session(conn,
        usuario: %{usuario: "laura", nombre: "Laura Gómez", rol: :administrador, zona: @norte}
      )

    {:ok, view, _html} = live(conn, ~p"/recursos")
    view
  end

  defp registrar_agua(view) do
    view |> element("#nuevo-recurso") |> render_click()

    view
    |> form("#form-recurso",
      recurso: %{
        nombre: "Agua potable",
        categoria: "agua",
        cantidad: "50",
        unidad: "litros",
        minimo: "40",
        ubicacion: "centro_acopio_1",
        zona: @norte
      }
    )
    |> render_submit()
  end

  test "registrar un recurso lo guarda con código y deja la entrada en el historial", %{
    conn: conn
  } do
    view = abrir(conn)
    assert registrar_agua(view) =~ "Recurso R001 · Agua potable registrado."

    assert [%{codigo: "R001", cantidad: 50, minimo: 40, zona: @norte}] =
             Interfaz.Fuente.Recursos.recursos()

    assert [%{tipo: :entrada, recurso: "R001", cantidad: 50}] = Interfaz.Fuente.Recursos.movimientos()
    assert has_element?(view, "#recurso-R001")
  end

  test "una salida mayor a lo disponible se rechaza y queda en el historial", %{conn: conn} do
    view = abrir(conn)
    registrar_agua(view)

    view |> element("#nuevo-movimiento") |> render_click()

    html =
      view
      |> form("#form-movimiento",
        movimiento: %{tipo: "salida", recurso: "R001", cantidad: "60", detalle: "Entrega"}
      )
      |> render_submit()

    assert html =~ "No hay suficientes unidades en inventario."
    assert [%{cantidad: 50}] = Interfaz.Fuente.Recursos.recursos()
    assert [%{tipo: :rechazo} | _] = Interfaz.Fuente.Recursos.movimientos()

    html =
      view
      |> form("#form-movimiento",
        movimiento: %{tipo: "salida", recurso: "R001", cantidad: "30", detalle: "Entrega"}
      )
      |> render_submit()

    assert html =~ "Salida registrada"
    assert [%{cantidad: 20}] = Interfaz.Fuente.Recursos.recursos()
  end

  test "transferir crea el recurso en el destino", %{conn: conn} do
    view = abrir(conn)
    registrar_agua(view)

    view |> element("#nueva-transferencia") |> render_click()

    html =
      view
      |> form("#form-transferencia",
        transferencia: %{recurso: "R001", destino: "albergue_2", cantidad: "10", zona: @norte}
      )
      |> render_submit()

    assert html =~ "Transferencia hecha a albergue_2."

    assert [
             %{ubicacion: "centro_acopio_1", cantidad: 40},
             %{ubicacion: "albergue_2", cantidad: 10}
           ] =
             Interfaz.Fuente.Recursos.recursos()
  end
end
