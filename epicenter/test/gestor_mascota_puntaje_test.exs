defmodule Epicenter.GestorMascotaPuntajeTest do
  use ExUnit.Case, async: true

  alias Epicenter.{GestorMascota, Mascota}

  @base %{
    tipo: :perdida,
    especie: "perro",
    color: "negra",
    tamano: "mediana",
    zona: "zona_norte",
    contacto: "300 123 4567",
    caracteristicas: "collar rojo"
  }

  defp mascota(id, cambios \\ %{}) do
    {:ok, mascota} = Mascota.nuevo(id, Map.merge(@base, cambios))
    mascota
  end

  describe "puntaje/2" do
    test "dos reportes idénticos suman 100" do
      assert GestorMascota.puntaje(mascota("P1"), mascota("E1", %{tipo: :encontrada})) ==
               100
    end

    test "los pesos suman 100" do
      assert GestorMascota.pesos() |> Map.values() |> Enum.sum() == 100
    end

    test "una especie distinta descarta el par" do
      gato = mascota("E1", %{tipo: :encontrada, especie: "gato"})
      assert GestorMascota.puntaje(mascota("P1"), gato) == 0
    end
  end

  describe "desglose/2" do
    test "el color acepta género y colores compuestos" do
      perdida = mascota("P1")

      igual = mascota("E1", %{tipo: :encontrada, color: "Negro"})
      compuesto = mascota("E2", %{tipo: :encontrada, color: "negro con blanco"})
      distinto = mascota("E3", %{tipo: :encontrada, color: "blanco"})

      assert GestorMascota.desglose(perdida, igual).color == 20
      assert GestorMascota.desglose(perdida, compuesto).color == 10
      assert GestorMascota.desglose(perdida, distinto).color == 0
    end

    test "el tamaño vale completo si es igual, la mitad si es adyacente y 0 si no" do
      mediana = mascota("P1")
      assert GestorMascota.desglose(mediana, mascota("E1", %{tamano: "mediano"})).tamano == 15
      assert GestorMascota.desglose(mediana, mascota("E2", %{tamano: "grande"})).tamano == 7

      pequena = mascota("P2", %{tamano: "pequeño"})
      assert GestorMascota.desglose(pequena, mascota("E3", %{tamano: "grande"})).tamano == 0
    end

    test "la zona solo suma si es la misma" do
      perdida = mascota("P1")
      assert GestorMascota.desglose(perdida, mascota("E1")).zona == 20
      assert GestorMascota.desglose(perdida, mascota("E2", %{zona: "zona_sur"})).zona == 0
    end

    test "las características usan la proporción de palabras en común" do
      perdida = mascota("P1")
      parcial = mascota("E1", %{caracteristicas: "collar azul"})
      assert GestorMascota.desglose(perdida, parcial).caracteristicas == 5
    end

    test "las características ignoran tildes y mayúsculas" do
      a = mascota("P1", %{caracteristicas: "Oreja CAÍDA"})
      b = mascota("E1", %{caracteristicas: "oreja caida"})
      assert GestorMascota.desglose(a, b).caracteristicas == 15
    end

    test "sin características en alguno de los reportes no suman" do
      a = mascota("P1", %{caracteristicas: ""})
      b = mascota("E1", %{caracteristicas: "collar rojo"})
      assert GestorMascota.desglose(a, b).caracteristicas == 0
      assert GestorMascota.desglose(a, a).caracteristicas == 0
    end
  end

  describe "calcular_coincidencias/2" do
    test "devuelve solo los pares con puntaje de 40 o más, de mayor a menor" do
      perdida = mascota("P1")

      exacta = mascota("E1", %{tipo: :encontrada})

      parcial =
        mascota("E2", %{
          tipo: :encontrada,
          tamano: "grande",
          zona: "zona_sur",
          caracteristicas: ""
        })

      bajo =
        mascota("E3", %{
          tipo: :encontrada,
          color: "blanco",
          tamano: "pequeño",
          zona: "zona_sur",
          caracteristicas: ""
        })

      gato = mascota("E4", %{tipo: :encontrada, especie: "gato"})

      resultado =
        GestorMascota.calcular_coincidencias([perdida, bajo, parcial, gato, exacta])

      assert [
               %{perdida: "P1", encontrada: "E1", puntaje: 100},
               %{perdida: "P1", encontrada: "E2", puntaje: 57}
             ] = resultado
    end

    test "ignora los reportes resueltos y los del mismo tipo" do
      perdida = mascota("P1")
      otra_perdida = mascota("P2")
      {:ok, resuelta} = Mascota.cambiar_estado(mascota("E1", %{tipo: :encontrada}), :resuelta)

      assert GestorMascota.calcular_coincidencias([perdida, otra_perdida, resuelta]) == []
    end

    test "incluye el desglose de cada coincidencia" do
      [coincidencia] =
        GestorMascota.calcular_coincidencias([
          mascota("P1"),
          mascota("E1", %{tipo: :encontrada})
        ])

      assert coincidencia.desglose == %{
               especie: 30,
               color: 20,
               zona: 20,
               tamano: 15,
               caracteristicas: 15
             }
    end

    test "con una lista vacía no hay coincidencias" do
      assert GestorMascota.calcular_coincidencias([]) == []
    end
  end

  describe "seleccionar_para_marcar/2" do
    test "aplica el umbral de 70 y deja cada reporte en una sola pareja" do
      coincidencias = [
        %{perdida: "P1", encontrada: "E1", puntaje: 90},
        %{perdida: "P1", encontrada: "E2", puntaje: 80},
        %{perdida: "P2", encontrada: "E1", puntaje: 75},
        %{perdida: "P3", encontrada: "E3", puntaje: 60},
        %{perdida: "P4", encontrada: "E4", puntaje: 70}
      ]

      assert [%{perdida: "P1", encontrada: "E1"}, %{perdida: "P4", encontrada: "E4"}] =
               GestorMascota.seleccionar_para_marcar(coincidencias)
    end
  end
end
