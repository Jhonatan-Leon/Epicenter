defmodule InterfazWeb.ActividadLiveTest do
  # Escribe en Actividad.log y Usuario.json de la carpeta temporal de pruebas.
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Interfaz.Fuente.{Actividad, Necesidades, Sesion}
  alias InterfazWeb.DatosPrueba

  @centro "A1F03C9E7B2D4410"

  setup do
    DatosPrueba.preparar(~w(Actividad.log Necesidad.json), [
      DatosPrueba.usuario("laura", "coordinar", @centro),
      DatosPrueba.usuario("ciudadano", "ciudadano", @centro)
    ])
  end

  defp conectado?(usuario),
    do: Enum.find(Actividad.usuarios(), &(&1.usuario == usuario)).conectado

  test "conectarse y desconectarse quedan en el registro" do
    assert {:ok, _sesion} = Sesion.conectar("laura", "clave")
    assert conectado?("laura")

    Sesion.desconectar(%{usuario: "laura"})
    refute conectado?("laura")

    assert [%{accion: "Se desconectó"}, %{accion: "Se conectó", resultado: :ok}] =
             Actividad.actividad("laura")
  end

  test "una contraseña equivocada queda como intento fallido" do
    assert {:error, _motivo} = Sesion.conectar("laura", "otra")
    assert [%{accion: "Se conectó", resultado: :error}] = Actividad.actividad("laura")
    refute conectado?("laura")
  end

  test "las operaciones y los rechazos por permiso quedan registrados", %{conn: conn} do
    datos = %{
      "tipo" => "agua",
      "cantidad" => "5",
      "prioridad" => "critica",
      "zona" => @centro,
      "descripcion" => "Sector 3"
    }

    assert {:ok, _mensaje} = Necesidades.registrar(datos, "laura")
    assert {:error, _mensaje} = Necesidades.registrar(datos, "ciudadano")

    assert [%{usuario: "laura", resultado: :ok, accion: "Registró una necesidad crítica"}] =
             Actividad.actividad("laura")

    assert [%{usuario: "ciudadano", resultado: :error, detalle: ":permiso_denegado"}] =
             Actividad.actividad("ciudadano")

    conn =
      init_test_session(conn,
        usuario: %{usuario: "laura", nombre: "Laura", rol: :coordinador, zona: @centro}
      )

    {:ok, view, _html} = live(conn, ~p"/actividad")
    assert has_element?(view, "#actividad-0", "Registró una necesidad crítica")
    assert has_element?(view, "#usuario-ciudadano")
  end
end
