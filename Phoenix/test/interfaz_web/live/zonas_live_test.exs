defmodule InterfazWeb.ZonasLiveTest do
  # Estas pruebas escriben en epicenter/lib/Datos/Zonas.json, por eso no corren en
  # paralelo y guardan una copia del archivo para dejarlo igual al terminar.
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  @centro "A1F03C9E7B2D4410"
  @centro_historico "C3E19A07F5B26D81"

  setup do
    ruta_zonas = Epicenter.Persistencia.ruta_datos("Zonas.json")
    ruta_usuarios = Epicenter.Persistencia.ruta_datos("Usuario.json")
    original = File.read!(ruta_zonas)
    usuarios_originales = File.read!(ruta_usuarios)

    usuarios =
      Jason.decode!(usuarios_originales) |> Enum.reject(&(&1["nombre_usuario"] == "laura"))

    File.write!(
      ruta_usuarios,
      Jason.encode!([
        %{
          "nombre_usuario" => "admin",
          "contrasena" => "clave",
          "rol" => "administrador",
          "nombre_completo" => "Admin",
          "zona_principal" => nil
        },
        %{
          "nombre_usuario" => "laura",
          "contrasena" => "clave",
          "rol" => "coordinar",
          "nombre_completo" => "Laura",
          "zona_principal" => "Centro"
        }
        | usuarios
      ])
    )

    on_exit(fn -> File.write!(ruta_zonas, original) end)
    on_exit(fn -> File.write!(ruta_usuarios, usuarios_originales) end)
    :ok
  end

  defp abrir(conn, modal, usuario \\ "laura") do
    {rol, nombre, zona} =
      if usuario == "admin",
        do: {:administrador, "Admin", nil},
        else: {:coordinador, "Laura", @centro}

    conn =
      init_test_session(conn,
        usuario: %{usuario: usuario, nombre: nombre, rol: rol, zona: zona}
      )

    {:ok, view, _html} = live(conn, ~p"/zonas")
    view |> element("#nuevo-#{modal}, #nueva-#{modal}") |> render_click()
    view
  end

  test "muestra las zonas guardadas en el JSON", %{conn: conn} do
    view = abrir(conn, "zona", "admin")
    assert has_element?(view, "#zona-#{@centro}")
    assert has_element?(view, "#sector-#{@centro_historico}")
  end

  test "registrar una zona la guarda en el JSON", %{conn: conn} do
    view = abrir(conn, "zona", "admin")
    refute has_element?(view, "#form-zona input[name='zona[codigo]']")

    html =
      view
      |> form("#form-zona", zona: %{nombre: "Zona de prueba", nivel: "alto"})
      |> render_submit()

    assert html =~ "Zona Zona de prueba registrada."
    assert Enum.any?(Interfaz.Fuente.zonas(), &(&1.nombre == "Zona de prueba"))
  end

  test "no deja repetir el nombre de una zona", %{conn: conn} do
    html =
      abrir(conn, "zona", "admin")
      |> form("#form-zona", zona: %{nombre: "Centro", nivel: "alto"})
      |> render_submit()

    assert html =~ "Ya existe una zona con ese nombre."
  end

  test "registrar un sector lo agrega a su zona", %{conn: conn} do
    view = abrir(conn, "sector")

    view
    |> form("#form-sector",
      sector: %{zona: @centro, nombre: "Sector de prueba", nivel: "medio", afectadas: "40"}
    )
    |> render_submit()

    centro = Enum.find(Interfaz.Fuente.zonas(), &(&1.codigo == @centro))
    assert Enum.any?(centro.sectores, &(&1.nombre == "Sector de prueba"))
  end

  test "registrar un punto lo agrega a su sector", %{conn: conn} do
    view = abrir(conn, "punto")

    view
    |> form("#form-punto", punto: %{sector: "#{@centro}:#{@centro_historico}", nombre: "Carpa"})
    |> render_submit()

    assert has_element?(view, "#sector-#{@centro_historico}", "Carpa")
  end
end
