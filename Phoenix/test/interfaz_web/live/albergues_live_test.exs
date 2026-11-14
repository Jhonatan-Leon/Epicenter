defmodule InterfazWeb.AlberguesLiveTest do
  # Escribe en Albergue.json y Persona.json de la lógica: no corre en paralelo y
  # deja los archivos como estaban.
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias InterfazWeb.DatosPrueba

  @archivos ~w(Albergue.json Persona.json)
  @norte "B7D24E901FA3C665"

  setup do
    DatosPrueba.preparar(@archivos, [DatosPrueba.usuario("laura", "administrador", "Norte")])

    for {doc, nombre} <- [{"111", "Ana Ruiz"}, {"222", "Luis Pérez"}] do
      {:ok, _} =
        Epicenter.GestorPersona.reportar_persona(doc, nombre, "30", @norte, "reportada", "laura")
    end

    :ok
  end

  defp abrir(conn) do
    conn =
      init_test_session(conn,
        usuario: %{usuario: "laura", nombre: "Laura Gómez", rol: :administrador, zona: @norte}
      )

    {:ok, view, _html} = live(conn, ~p"/albergues")
    view
  end

  defp registrar_albergue(view, nombre, capacidad) do
    view |> element("#nuevo-albergue") |> render_click()

    view
    |> form("#form-albergue", albergue: %{nombre: nombre, capacidad: capacidad, zona: @norte})
    |> render_submit()
  end

  defp movimiento(view, codigo, tipo, documento) do
    view |> element("##{tipo}-#{codigo}") |> render_click()

    view
    |> form("#form-movimiento-albergue", movimiento: %{documento: documento})
    |> render_submit()
  end

  test "registrar un albergue lo guarda sin pedir código", %{conn: conn} do
    view = abrir(conn)
    view |> element("#nuevo-albergue") |> render_click()
    refute has_element?(view, "#form-albergue input[name='albergue[codigo]']")

    assert registrar_albergue(view, "Coliseo", "2") =~ "Albergue Coliseo registrado."
    assert [%{nombre: "Coliseo", capacidad: 2, ocupacion: 0}] = Interfaz.Fuente.Albergues.albergues()
  end

  test "ingreso, albergue lleno y salida", %{conn: conn} do
    view = abrir(conn)
    registrar_albergue(view, "Coliseo", "1")
    [%{codigo: codigo}] = Interfaz.Fuente.Albergues.albergues()

    assert movimiento(view, codigo, "ingreso", "111") =~ "Ingreso registrado en Coliseo."
    assert [%{ocupacion: 1, ocupantes: ["111"]}] = Interfaz.Fuente.Albergues.albergues()

    # La persona queda "en albergue" en su historial.
    {:ok, %{estado: :en_albergue}} = Epicenter.GestorPersona.obtener_por_documento("111")

    # Con el albergue lleno el botón de ingreso queda deshabilitado.
    assert has_element?(view, "#ingreso-#{codigo}[disabled]")

    assert movimiento(view, codigo, "salida", "111") =~ "Salida registrada de Coliseo."
    assert [%{ocupacion: 0}] = Interfaz.Fuente.Albergues.albergues()
  end

  test "la lógica no deja superar la capacidad", %{conn: conn} do
    abrir(conn) |> registrar_albergue("Escuela", "1")
    [%{codigo: codigo}] = Interfaz.Fuente.Albergues.albergues()

    assert {:ok, _} = Interfaz.Fuente.Albergues.registrar_ingreso(codigo, "111", "laura")

    assert {:error, "El albergue está lleno: no hay cupos disponibles."} =
             Interfaz.Fuente.Albergues.registrar_ingreso(codigo, "222", "laura")
  end

  test "el ranking ordena por ocupación", %{conn: conn} do
    view = abrir(conn)
    registrar_albergue(view, "Grande", "10")
    registrar_albergue(view, "Pequeño", "1")
    pequeno = Enum.find(Interfaz.Fuente.Albergues.albergues(), &(&1.nombre == "Pequeño"))
    {:ok, _} = Interfaz.Fuente.Albergues.registrar_ingreso(pequeno.codigo, "111", "laura")

    assert [%{nombre: "Pequeño"}, %{nombre: "Grande"}] = Interfaz.Fuente.Albergues.reporte()
  end
end
