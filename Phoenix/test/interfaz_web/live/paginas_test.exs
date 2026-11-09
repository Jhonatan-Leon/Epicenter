defmodule InterfazWeb.PaginasTest do
  use InterfazWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp conectado(conn, rol) do
    init_test_session(conn,
      usuario: %{usuario: "laura", nombre: "Laura", rol: rol, zona: "centro"}
    )
  end

  test "sin sesión redirige a conectar", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/conectar"}}} = live(conn, ~p"/")
  end

  test "la pantalla de conexión se muestra", %{conn: conn} do
    assert html_response(get(conn, ~p"/conectar"), 200) =~ "Conectarse"
  end

  test "conectar guarda la sesión y entra al resumen", %{conn: conn} do
    conn =
      post(conn, ~p"/conectar",
        acceso: %{usuario: "laura", contrasena: "1234", rol: "coordinador", zona: "centro"}
      )

    assert redirected_to(conn) == ~p"/"
  end

  for ruta <- ~w(/ /zonas /necesidades /recursos /personas /mascotas /albergues /actividad) do
    test "el coordinador ve #{ruta}", %{conn: conn} do
      {:ok, _view, html} = live(conectado(conn, :coordinador), unquote(ruta))
      assert html =~ "Epicenter"
    end
  end

  test "un ciudadano no entra a recursos", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/"}}} = live(conectado(conn, :ciudadano), ~p"/recursos")
  end

  test "registrar una necesidad muestra el comando enviado", %{conn: conn} do
    {:ok, view, _} = live(conectado(conn, :coordinador), ~p"/necesidades")
    view |> element("#nueva-necesidad") |> render_click()

    html =
      view
      |> form("#form-necesidad",
        necesidad: %{
          tipo: "agua",
          cantidad: "30",
          prioridad: "critica",
          zona: "centro",
          descripcion: "Punto de atención sector 3"
        }
      )
      |> render_submit()

    assert html =~ "register_need agua 30 critica centro"
  end

  test "registrar una zona solo pide nombre y nivel", %{conn: conn} do
    {:ok, view, _} = live(conectado(conn, :coordinador), ~p"/zonas")
    view |> element("#nueva-zona") |> render_click()
    refute has_element?(view, "#form-zona input[name='zona[codigo]']")

    html =
      view
      |> form("#form-zona", zona: %{nombre: "Norte", nivel: "alto"})
      |> render_submit()

    assert html =~ "register_zone Norte alto"
  end

  test "los filtros de necesidades reducen la lista", %{conn: conn} do
    {:ok, view, _} = live(conectado(conn, :coordinador), ~p"/necesidades")
    view |> form("#filtros-necesidades", filtro: %{prioridad: "critica"}) |> render_change()
    assert has_element?(view, "#necesidad-N003")
    refute has_element?(view, "#necesidad-N004")
  end
end
