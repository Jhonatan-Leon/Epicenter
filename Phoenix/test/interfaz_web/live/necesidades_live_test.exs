defmodule InterfazWeb.NecesidadesLiveTest do
  # Escribe en Necesidad.json, Recurso.json e Historial.json (carpeta temporal de pruebas).
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Interfaz.Fuente.{Necesidades, Recursos}
  alias InterfazWeb.DatosPrueba

  @centro "A1F03C9E7B2D4410"
  @norte "B7D24E901FA3C665"

  setup do
    DatosPrueba.preparar(~w(Necesidad.json Recurso.json Historial.json), [
      DatosPrueba.usuario("laura", "coordinar", @centro),
      DatosPrueba.usuario("ciudadano", "ciudadano", @centro)
    ])
  end

  defp abrir(conn) do
    conn =
      init_test_session(conn,
        usuario: %{usuario: "laura", nombre: "Laura", rol: :coordinador, zona: @centro}
      )

    {:ok, view, _html} = live(conn, ~p"/necesidades")
    view
  end

  defp necesidad(zona, cantidad, prioridad) do
    {:ok, necesidad} =
      Epicenter.GenserverNecesidad.registrar(
        zona,
        "laura",
        "agua",
        "Sector 3",
        cantidad,
        prioridad
      )

    necesidad.id
  end

  defp agua_en_centro(cantidad) do
    {:ok, _mensaje} =
      Recursos.registrar(
        %{
          "nombre" => "Agua potable",
          "categoria" => "agua",
          "unidad" => "litros",
          "cantidad" => to_string(cantidad),
          "minimo" => "10",
          "ubicacion" => "centro_acopio_1",
          "zona" => @centro
        },
        "laura"
      )

    "R001"
  end

  test "registrar una necesidad crítica la guarda y la muestra", %{conn: conn} do
    view = abrir(conn)
    view |> element("#nueva-necesidad") |> render_click()

    html =
      view
      |> form("#form-necesidad",
        necesidad: %{
          tipo: "agua",
          cantidad: "30",
          prioridad: "critica",
          zona: @centro,
          descripcion: "Punto de atención sector 3"
        }
      )
      |> render_submit()

    assert html =~ "registrada."

    assert [%{prioridad: :critica, cantidad: 30, responsable: "laura"}] =
             Necesidades.necesidades()
  end

  test "la lista viene ordenada por prioridad y se puede filtrar", %{conn: conn} do
    baja = necesidad(@centro, 5, "baja")
    critica = necesidad(@centro, 5, "critica")

    assert [%{id: ^critica}, %{id: ^baja}] = Necesidades.necesidades()

    view = abrir(conn)
    view |> form("#filtros-necesidades", filtro: %{prioridad: "critica"}) |> render_change()
    assert has_element?(view, "#necesidad-#{critica}")
    refute has_element?(view, "#necesidad-#{baja}")
  end

  test "el backend revisa el rol y la zona" do
    datos = %{
      "tipo" => "agua",
      "cantidad" => "3",
      "prioridad" => "critica",
      "zona" => @centro,
      "descripcion" => "x"
    }

    assert {:error, "Tu rol no permite esta acción."} = Necesidades.registrar(datos, "ciudadano")

    del_norte = necesidad(@norte, 10, "alta")

    assert {:error, "Solo puedes operar en tu zona asignada."} =
             Necesidades.asignar_recurso(del_norte, "R001", "5", "laura")
  end

  test "asignar descuenta el inventario y un segundo pedido sin existencias se rechaza", %{
    conn: conn
  } do
    recurso = agua_en_centro(50)
    primera = necesidad(@centro, 30, "critica")
    segunda = necesidad(@centro, 25, "alta")

    view = abrir(conn)
    view |> element("#asignar-#{primera}") |> render_click()

    assert view
           |> form("#form-asignar", asignacion: %{recurso: recurso, cantidad: "30"})
           |> render_submit() =~ "Asignado a #{primera}"

    assert [%{cantidad: 20}] = Recursos.recursos()
    assert %{asignada: 30, estado: :asignada} = Necesidades.obtener(primera)

    view |> element("#asignar-#{segunda}") |> render_click()

    assert view
           |> form("#form-asignar", asignacion: %{recurso: recurso, cantidad: "25"})
           |> render_submit() =~ "No hay suficientes unidades en inventario."

    assert [%{cantidad: 20}] = Recursos.recursos()
    assert [%{tipo: :rechazo} | _] = Recursos.movimientos()
  end

  test "dos asignaciones al mismo tiempo no gastan más de lo disponible" do
    recurso = agua_en_centro(50)
    primera = necesidad(@centro, 30, "critica")
    segunda = necesidad(@centro, 30, "critica")

    resultados =
      [primera, segunda]
      |> Enum.map(fn id ->
        Task.async(fn -> Necesidades.asignar_recurso(id, recurso, "30", "laura") end)
      end)
      |> Task.await_many()

    assert Enum.count(resultados, &match?({:ok, _}, &1)) == 1
    assert {:error, "No hay suficientes unidades en inventario."} in resultados
    assert [%{cantidad: 20}] = Recursos.recursos()
  end
end
