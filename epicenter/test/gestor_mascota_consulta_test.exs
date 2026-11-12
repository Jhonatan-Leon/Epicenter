defmodule Epicenter.GestorMascotaConsultaTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorMascota

  @base %{
    tipo: :perdida,
    especie: "perro",
    color: "negra",
    tamano: "mediana",
    zona: "zona_norte",
    contacto: "300 123 4567"
  }

  setup do
    ruta = Path.expand("../lib/Datos/Mascota.json", __DIR__)
    original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, original) end)

    # P1: perro perdido, zona_norte, activa
    # P2: gato perdido, zona_norte, activa
    # E1: perro encontrado, zona_sur, resuelta
    # E2: gato encontrado, zona_sur, activa
    {:ok, _} = GestorMascota.registro("P1", @base)
    {:ok, _} = GestorMascota.registro("P2", %{@base | especie: "gato"})
    {:ok, _} = GestorMascota.registro("E1", %{@base | tipo: :encontrada, zona: "zona_sur"})

    {:ok, _} =
      GestorMascota.registro("E2", %{@base | tipo: :encontrada, especie: "gato", zona: "zona_sur"})

    {:ok, _} = GestorMascota.cambiar_estado("E1", :resuelta)

    :ok
  end

  defp ids({:ok, reportes}), do: reportes |> Enum.map(& &1.id) |> Enum.sort()

  describe "consultar/1" do
    test "sin filtros devuelve todos los reportes" do
      assert ids(GestorMascota.consultar()) == ["E1", "E2", "P1", "P2"]
      assert ids(GestorMascota.consultar([])) == ["E1", "E2", "P1", "P2"]
    end

    test "filtra por especie sin distinguir mayúsculas ni espacios" do
      assert ids(GestorMascota.consultar(especie: "perro")) == ["E1", "P1"]
      assert ids(GestorMascota.consultar(especie: "  GATO ")) == ["E2", "P2"]
    end

    test "filtra por zona" do
      assert ids(GestorMascota.consultar(zona: "zona_norte")) == ["P1", "P2"]
      assert ids(GestorMascota.consultar(zona: "zona_sur")) == ["E1", "E2"]
    end

    test "filtra por estado, como átomo o como texto" do
      assert ids(GestorMascota.consultar(estado: :resuelta)) == ["E1"]
      assert ids(GestorMascota.consultar(estado: "resuelta")) == ["E1"]
      assert ids(GestorMascota.consultar(estado: :activa)) == ["E2", "P1", "P2"]
    end

    test "combina varios filtros" do
      assert ids(GestorMascota.consultar(especie: "gato", zona: "zona_sur")) == ["E2"]

      assert ids(GestorMascota.consultar(especie: "perro", zona: "zona_sur", estado: :activa)) ==
               []
    end

    test "acepta los filtros como mapa" do
      assert ids(GestorMascota.consultar(%{especie: "perro", estado: :activa})) == ["P1"]
    end

    test "si nada coincide devuelve una lista vacía" do
      assert {:ok, []} = GestorMascota.consultar(zona: "zona_inexistente")
    end

    test "rechaza una clave de filtro desconocida" do
      assert {:error, :filtro_invalido} = GestorMascota.consultar(color: "negra")
    end

    test "rechaza un valor que no es texto en especie o zona" do
      assert {:error, :filtro_invalido} = GestorMascota.consultar(especie: :perro)
      assert {:error, :filtro_invalido} = GestorMascota.consultar(zona: 5)
    end

    test "rechaza un estado que no existe" do
      assert {:error, :estado_invalido} = GestorMascota.consultar(estado: :perdida)
      assert {:error, :estado_invalido} = GestorMascota.consultar(estado: "cerrada")
    end

    test "rechaza filtros que no son una lista ni un mapa" do
      assert {:error, :filtros_invalidos} = GestorMascota.consultar("perro")
      assert {:error, :filtros_invalidos} = GestorMascota.consultar(nil)
    end

    test "un filtro inválido no devuelve resultados parciales" do
      assert {:error, :filtro_invalido} =
               GestorMascota.consultar(especie: "perro", color: "negra")
    end
  end
end
