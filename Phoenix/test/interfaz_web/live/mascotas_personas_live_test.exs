defmodule InterfazWeb.MascotasPersonasLiveTest do
  # Estas pruebas escriben en Mascota.json, Persona.json y Mensaje.json de la
  # lógica, por eso no corren en paralelo y dejan los archivos como estaban.
  use InterfazWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  @datos Path.expand("../../../../epicenter/lib/Datos", __DIR__)
  @archivos ~w(Mascota.json Persona.json Mensaje.json)
  @norte "B7D24E901FA3C665"

  setup do
    originales = for a <- @archivos, do: {a, File.read!(Path.join(@datos, a))}
    for a <- @archivos, do: File.write!(Path.join(@datos, a), "[]")
    on_exit(fn -> for {a, contenido} <- originales, do: File.write!(Path.join(@datos, a), contenido) end)
    :ok
  end

  defp conectado(conn) do
    init_test_session(conn,
      usuario: %{usuario: "laura", nombre: "Laura Gómez", rol: :coordinador, zona: @norte}
    )
  end

  defp reportar_mascota(view, tipo, datos) do
    view |> element("#reportar-#{tipo}") |> render_click()

    view
    |> form("#form-mascota", mascota: Map.merge(%{reporte: tipo, zona: @norte}, datos))
    |> render_submit()
  end

  describe "mascotas" do
    test "reportar una perdida y una encontrada parecidas muestra la coincidencia", %{conn: conn} do
      {:ok, view, _} = live(conectado(conn), ~p"/mascotas")

      html =
        reportar_mascota(view, "perdida", %{
          especie: "perro",
          nombre: "Luna",
          color: "negro",
          tamano: "mediano",
          contacto: "300 123 4567",
          caracteristicas: "collar rojo"
        })

      assert html =~ "Mascota Perdida reportada."

      reportar_mascota(view, "encontrada", %{
        especie: "perro",
        color: "negro",
        tamano: "mediano",
        contacto: "Carlos",
        caracteristicas: "collar rojo"
      })

      {:ok, mascotas} = Epicenter.GestorMascota.listar()
      assert length(mascotas) == 2
      assert has_element?(view, "#coincidencias [id^='coincidencia-']", "Luna")
    end

    test "buscar coincidencias las marca y confirmar cierra ambos reportes", %{conn: conn} do
      {:ok, view, _} = live(conectado(conn), ~p"/mascotas")
      datos = %{especie: "gato", color: "gris", tamano: "pequeno", contacto: "311", caracteristicas: "ojos verdes"}
      reportar_mascota(view, "perdida", Map.put(datos, :nombre, "Michi"))
      reportar_mascota(view, "encontrada", datos)

      assert view |> element("#buscar-coincidencias") |> render_click() =~
               "Se marcó 1 posible coincidencia."

      {:ok, [perdida]} = Epicenter.GestorMascota.consultar(estado: :posible_coincidencia, especie: "gato") |> primeras_perdidas()
      encontrada = perdida.coincidencia_con

      view |> element("#confirmar-#{perdida.id}-#{encontrada}") |> render_click()

      {:ok, resueltas} = Epicenter.GestorMascota.consultar(estado: :resuelta)
      assert length(resueltas) == 2
    end

    test "un reporte sin color muestra el error de la lógica", %{conn: conn} do
      {:ok, view, _} = live(conectado(conn), ~p"/mascotas")

      html =
        reportar_mascota(view, "perdida", %{especie: "perro", color: " ", tamano: "grande", contacto: "300"})

      assert html =~ "Escribe el color."
    end
  end

  defp primeras_perdidas({:ok, lista}), do: {:ok, Enum.filter(lista, &(&1.tipo == :perdida))}

  describe "personas y mensajes" do
    test "reportar, cambiar estado y enviar un mensaje", %{conn: conn} do
      {:ok, view, _} = live(conectado(conn), ~p"/personas")
      view |> element("#reportar-persona") |> render_click()

      html =
        view
        |> form("#form-persona",
          persona: %{documento: "1094", nombre: "Andrés Gómez", edad: "34", zona: @norte, estado: "reportada"}
        )
        |> render_submit()

      assert html =~ "Persona Andrés Gómez reportada."
      assert has_element?(view, "#detalle-persona", "Andrés Gómez")

      view |> element("#cambiar-estado") |> render_click()
      view |> form("#form-estado", estado: %{estado: "localizada"}) |> render_submit()

      {:ok, historial} = Epicenter.GestorPersona.historial("1094")
      assert Enum.map(historial, & &1.estado) == [:reportada, :localizada]
      assert Enum.all?(historial, &(&1.por == "laura"))

      view
      |> form("#form-mensaje", mensaje: %{contenido: "Estoy bien, en el albergue norte"})
      |> render_submit()

      assert has_element?(view, "#mensajes-persona", "Estoy bien, en el albergue norte")
      # El campo se reemplaza por uno nuevo y vacío.
      assert has_element?(view, "#mensaje-contenido-1")
      refute has_element?(view, "#mensaje-contenido-1[value]")
      {:ok, [mensaje]} = Epicenter.GestorMensaje.listar_por_persona("1094")
      assert mensaje.remitente == "Laura Gómez"
    end

    test "no deja reportar dos veces el mismo documento", %{conn: conn} do
      {:ok, view, _} = live(conectado(conn), ~p"/personas")
      persona = %{documento: "555", nombre: "Ana Ruiz", edad: "40", zona: @norte, estado: "reportada"}

      view |> element("#reportar-persona") |> render_click()
      view |> form("#form-persona", persona: persona) |> render_submit()
      view |> element("#reportar-persona") |> render_click()

      assert view |> form("#form-persona", persona: persona) |> render_submit() =~
               "Ya hay una persona reportada con ese documento."
    end
  end
end
