defmodule InterfazWeb.SesionControllerTest do
  # No es async: el login real lee y escribe epicenter/lib/Datos/Usuario.json.
  use InterfazWeb.ConnCase, async: false

  @usuarios Path.expand("../epicenter/lib/Datos/Usuario.json")

  setup do
    original = File.read!(@usuarios)

    File.write!(@usuarios, """
    [{"nombre_usuario": "ANA", "contrasena": "ClaveSegura", "rol": "coordinar",
      "nombre_completo": null, "zona_principal": null}]
    """)

    on_exit(fn -> File.write!(@usuarios, original) end)
    :ok
  end

  defp conectar(conn, usuario, contrasena) do
    post(conn, ~p"/conectar",
      acceso: %{usuario: usuario, contrasena: contrasena, rol: "ciudadano", zona: "centro"}
    )
  end

  test "un usuario existente entra con su rol de la lógica", %{conn: conn} do
    conn = conectar(conn, "ANA", "ClaveSegura")

    assert redirected_to(conn) == ~p"/"
    assert %{usuario: "ANA", rol: :coordinador} = get_session(conn, :usuario)
  end

  test "con la contraseña equivocada vuelve a conectar con el error", %{conn: conn} do
    conn = conectar(conn, "ANA", "otra")

    assert redirected_to(conn) == ~p"/conectar"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Usuario o contraseña incorrectos"
  end

  test "un usuario nuevo se registra y queda guardado", %{conn: conn} do
    conn = conectar(conn, "laura", "1234")

    assert redirected_to(conn) == ~p"/"
    assert File.read!(@usuarios) =~ "laura"
  end
end
