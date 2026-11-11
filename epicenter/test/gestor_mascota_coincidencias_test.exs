defmodule Epicenter.GestorMascotaCoincidenciasTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorMascota

  @datos %{
    tipo: :perdida,
    especie: "perro",
    nombre: "Luna",
    color: "negra",
    tamano: "mediana",
    zona: "zona_norte",
    contacto: "300 123 4567",
    caracteristicas: "collar rojo"
  }

  setup do
    ruta = Path.expand("../lib/Datos/Mascota.json", __DIR__)
    original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, original) end)

    :ok
  end

  defp registrar(id, cambios \\ %{}) do
    {:ok, mascota} = GestorMascota.registro(id, Map.merge(@datos, cambios))
    mascota
  end

  defp par_coincidente do
    registrar("P1")
    registrar("E1", %{tipo: :encontrada, nombre: "desconocido"})
  end

  describe "coincidencias_posibles/0" do
    test "lista los pares candidatos sin modificar los reportes" do
      par_coincidente()

      assert {:ok, [%{perdida: "P1", encontrada: "E1", puntaje: 100}]} =
               GestorMascota.coincidencias_posibles()

      assert {:ok, %{estado: :activa, coincidencia_con: nil}} = GestorMascota.obtener("P1")
    end

    test "sin reportes no hay coincidencias" do
      assert {:ok, []} = GestorMascota.coincidencias_posibles()
    end
  end

  describe "marcar_coincidencias/0" do
    test "marca ambos reportes y guarda el vínculo" do
      par_coincidente()

      assert {:ok, [%{perdida: "P1", encontrada: "E1"}]} = GestorMascota.marcar_coincidencias()

      assert {:ok, %{estado: :posible_coincidencia, coincidencia_con: "E1"}} =
               GestorMascota.obtener("P1")

      assert {:ok, %{estado: :posible_coincidencia, coincidencia_con: "P1"}} =
               GestorMascota.obtener("E1")
    end

    test "no vuelve a marcar reportes que ya tienen una posible coincidencia" do
      par_coincidente()
      assert {:ok, [_par]} = GestorMascota.marcar_coincidencias()
      assert {:ok, []} = GestorMascota.marcar_coincidencias()
    end

    test "no marca pares por debajo del umbral" do
      registrar("P1")

      registrar("E1", %{
        tipo: :encontrada,
        color: "blanco",
        zona: "zona_sur",
        caracteristicas: ""
      })

      assert {:ok, []} = GestorMascota.marcar_coincidencias()
      assert {:ok, %{estado: :activa}} = GestorMascota.obtener("P1")
    end
  end

  describe "confirmar_coincidencia/2" do
    test "cierra ambos reportes y deja el vínculo" do
      par_coincidente()

      assert {:ok, {perdida, encontrada}} = GestorMascota.confirmar_coincidencia("P1", "E1")
      assert %{estado: :resuelta, coincidencia_con: "E1"} = perdida
      assert %{estado: :resuelta, coincidencia_con: "P1"} = encontrada

      assert {:ok, %{estado: :resuelta}} = GestorMascota.obtener("P1")
      assert {:ok, %{estado: :resuelta}} = GestorMascota.obtener("E1")
    end

    test "también se puede confirmar un par que ya estaba marcado" do
      par_coincidente()
      {:ok, _parejas} = GestorMascota.marcar_coincidencias()

      assert {:ok, _par} = GestorMascota.confirmar_coincidencia("P1", "E1")
    end

    test "no se puede confirmar dos veces" do
      par_coincidente()
      assert {:ok, _par} = GestorMascota.confirmar_coincidencia("P1", "E1")
      assert {:error, :ya_resuelta} = GestorMascota.confirmar_coincidencia("P1", "E1")
    end

    test "si un reporte ya estaba resuelto no cambia ninguno de los dos" do
      par_coincidente()
      registrar("E2", %{tipo: :encontrada})
      {:ok, _par} = GestorMascota.confirmar_coincidencia("P1", "E1")

      assert {:error, :ya_resuelta} = GestorMascota.confirmar_coincidencia("P1", "E2")
      assert {:ok, %{estado: :activa, coincidencia_con: nil}} = GestorMascota.obtener("E2")
    end

    test "exige una perdida y una encontrada" do
      registrar("P1")
      registrar("P2")

      assert {:error, :tipos_incompatibles} = GestorMascota.confirmar_coincidencia("P1", "P2")
    end

    test "informa si algún reporte no existe" do
      registrar("P1")

      assert {:error, "Mascota no encontrada"} =
               GestorMascota.confirmar_coincidencia("P1", "NO_EXISTE")
    end
  end
end
