defmodule InterfazWeb.PaginasTest do
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  setup do
    ruta_usuarios = Epicenter.Persistencia.ruta_datos("Usuario.json")
    original = File.read!(ruta_usuarios)
    usuarios = Jason.decode!(original) |> Enum.reject(&(&1["nombre_usuario"] == "laura"))

    usuarios = [
      %{
        "nombre_usuario" => "ciudadano",
        "contrasena" => "clave",
        "rol" => "ciudadano",
        "nombre_completo" => "Ciudadano",
        "zona_principal" => "Norte"
      },
      %{
        "nombre_usuario" => "laura",
        "contrasena" => "clave",
        "rol" => "coordinar",
        "nombre_completo" => "Laura",
        "zona_principal" => "A1F03C9E7B2D4410"
      }
      | usuarios
    ]

    File.write!(ruta_usuarios, Jason.encode!(usuarios))
    on_exit(fn -> File.write!(ruta_usuarios, original) end)
    :ok
  end

  defp conectado(conn, rol) do
    nombre_usuario = if rol == :ciudadano, do: "ciudadano", else: "laura"

    init_test_session(conn,
      usuario: %{
        usuario: nombre_usuario,
        nombre: "Laura",
        rol: rol,
        zona: "A1F03C9E7B2D4410"
      }
    )
  end

  test "sin sesión redirige a conectar", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/conectar"}}} = live(conn, ~p"/")
  end

  test "la pantalla de conexión se muestra", %{conn: conn} do
    assert html_response(get(conn, ~p"/conectar"), 200) =~ "Conectarse"
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

  test "la autorización de sección usa el rol persistido y no el de la sesión", %{conn: conn} do
    conn =
      init_test_session(conn,
        usuario: %{
          usuario: "ciudadano",
          nombre: "Ciudadano",
          rol: :administrador,
          zona: "B7D24E901FA3C665"
        }
      )

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/actividad")
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
          zona: "A1F03C9E7B2D4410",
          descripcion: "Punto de atención sector 3"
        }
      )
      |> render_submit()

    assert html =~ "register_need agua 30 critica A1F03C9E7B2D4410"
  end

  test "el backend rechaza asignaciones de ciudadanos y limita coordinadores a su zona" do
    assert {:error, :permiso_denegado} =
             Interfaz.Fuente.ejecutar(
               "assign_resource",
               ["N001", "R001", "10"],
               "ciudadano"
             )

    assert {:error, :fuera_de_zona} =
             Interfaz.Fuente.ejecutar(
               "assign_resource",
               ["N003", "R001", "10"],
               "laura"
             )
  end

  test "los filtros de necesidades reducen la lista", %{conn: conn} do
    {:ok, view, _} = live(conectado(conn, :coordinador), ~p"/necesidades")
    view |> form("#filtros-necesidades", filtro: %{prioridad: "critica"}) |> render_change()
    assert has_element?(view, "#necesidad-N003")
    refute has_element?(view, "#necesidad-N004")
  end
end
