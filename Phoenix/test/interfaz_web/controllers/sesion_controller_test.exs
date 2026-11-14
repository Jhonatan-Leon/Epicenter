defmodule InterfazWeb.SesionControllerTest do
  # No es async: el login real lee y escribe epicenter/lib/Datos/Usuario.json.
  use InterfazWeb.ConnCase, async: false

  setup do
    ruta_usuarios = Epicenter.Persistencia.ruta_datos("Usuario.json")
    original = File.read!(ruta_usuarios)

    File.write!(ruta_usuarios, """
    [{"nombre_usuario": "ANA", "contrasena": "ClaveSegura", "rol": "coordinar",
      "nombre_completo": null, "zona_principal": null},
     {"nombre_usuario": "hola", "contrasena": "137", "rol": "ciudadano",
      "nombre_completo": null, "zona_principal": null}]
    """)

    on_exit(fn -> File.write!(ruta_usuarios, original) end)
    :ok
  end

  defp conectar(conn, usuario, contrasena) do
    post(conn, ~p"/conectar", acceso: %{usuario: usuario, contrasena: contrasena})
  end

  defp registrar(conn, datos), do: post(conn, ~p"/registrar", registro: datos)

  test "la pantalla de conexión solo pide usuario y contraseña", %{conn: conn} do
    html = html_response(get(conn, ~p"/conectar"), 200)

    assert html =~ ~s(name="acceso[usuario]")
    assert html =~ ~s(name="acceso[contrasena]")
    refute html =~ ~s(name="acceso[rol]")
    refute html =~ ~s(name="acceso[zona]")
  end

  test "un usuario existente entra con su rol de la lógica", %{conn: conn} do
    conn = conectar(conn, "ANA", "ClaveSegura")

    assert redirected_to(conn) == ~p"/"
    assert %{usuario: "ANA", rol: :coordinador} = get_session(conn, :usuario)
  end

  test "un usuario existente con contraseña corta todavía puede entrar", %{conn: conn} do
    assert redirected_to(conectar(conn, "hola", "137")) == ~p"/"
  end

  test "con la contraseña equivocada vuelve a conectar con el error", %{conn: conn} do
    conn = conectar(conn, "ANA", "otra")

    assert redirected_to(conn) == ~p"/conectar"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Usuario o contraseña incorrectos"
  end

  test "un dato inválido se rechaza sin llegar a la lógica", %{conn: conn} do
    antes = File.read!(Epicenter.Persistencia.ruta_datos("Usuario.json"))
    conn = conectar(conn, "ana maria", "1234")

    assert redirected_to(conn) == ~p"/conectar"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "El usuario no puede tener espacios."
    assert File.read!(Epicenter.Persistencia.ruta_datos("Usuario.json")) == antes
  end

  test "un usuario nuevo ve el paso de registro y todavía no se guarda", %{conn: conn} do
    antes = File.read!(Epicenter.Persistencia.ruta_datos("Usuario.json"))
    html = conn |> conectar("laura", "1234") |> html_response(200)

    assert html =~ "Completa tu registro"
    assert html =~ ~s(name="registro[nombre_completo]")
    assert html =~ ~s(name="registro[rol]")
    assert html =~ ~s(name="registro[zona]")
    assert html =~ ~s(<option value="Sur">Sur</option>)
    refute html =~ ~s(value="coordinador")
    refute html =~ ~s(value="administrador")
    assert File.read!(Epicenter.Persistencia.ruta_datos("Usuario.json")) == antes
  end

  test "al completar el registro se guarda el usuario completo", %{conn: conn} do
    conn =
      registrar(conn, %{
        usuario: "laura",
        contrasena: "1234",
        nombre_completo: "Laura Gómez",
        rol: "voluntario",
        zona: "Norte"
      })

    assert redirected_to(conn) == ~p"/"

    assert %{usuario: "laura", nombre: "Laura Gómez", rol: :voluntario, zona: "B7D24E901FA3C665"} =
             get_session(conn, :usuario)

    {:ok, usuarios} = Epicenter.Persistencia.carga_usuarios()
    laura = Enum.find(usuarios, &(&1.nombre_usuario == "laura"))

    assert laura.rol == :voluntario
    assert laura.nombre_completo == "Laura Gómez"
    # En el JSON queda el nombre de la zona; en la sesión, su código.
    assert laura.zona_principal == "Norte"
  end

  test "al volver a conectarse conserva rol, nombre y zona", %{conn: conn} do
    registrar(conn, %{
      usuario: "laura",
      contrasena: "1234",
      nombre_completo: "Laura Gómez",
      rol: "voluntario",
      zona: "Norte"
    })

    conn = conectar(build_conn(), "laura", "1234")

    assert %{nombre: "Laura Gómez", rol: :voluntario, zona: "B7D24E901FA3C665"} =
             get_session(conn, :usuario)
  end

  test "un usuario con la zona guardada por nombre entra con su código", %{conn: conn} do
    File.write!(Epicenter.Persistencia.ruta_datos("Usuario.json"), """
    [{"nombre_usuario": "steven", "contrasena": "1234", "rol": "administrador",
      "nombre_completo": "Steven Sanchez", "zona_principal": "Centro"}]
    """)

    conn = conectar(conn, "steven", "1234")
    assert %{rol: :administrador, zona: "A1F03C9E7B2D4410"} = get_session(conn, :usuario)
  end

  test "el registro rechaza coordinador y muestra el error en el mismo paso", %{conn: conn} do
    html =
      conn
      |> registrar(%{
        usuario: "laura",
        contrasena: "1234",
        nombre_completo: "Laura Gómez",
        rol: "coordinador",
        zona: "Centro"
      })
      |> html_response(200)

    assert html =~ "Completa tu registro"
    assert html =~ "Al registrarte solo puedes ser ciudadano o voluntario."
  end
end
