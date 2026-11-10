defmodule Epicenter.MascotaTest do
  use ExUnit.Case, async: true

  alias Epicenter.Mascota

  doctest Epicenter.Mascota

  @datos_validos %{
    tipo: :perdida,
    especie: "Perro",
    nombre: "Luna",
    caracteristicas: "  Collar rojo, oreja izquierda caída  ",
    color: "Negra",
    tamano: "mediana",
    zona: "zona_norte",
    contacto: "300 123 4567"
  }

  defp mascota_valida do
    {:ok, mascota} = Mascota.nuevo("M001", @datos_validos)
    mascota
  end

  describe "nuevo/2" do
    test "crea una mascota válida y normaliza los textos" do
      assert {:ok, mascota} = Mascota.nuevo("M001", @datos_validos)

      assert mascota.id == "M001"
      assert mascota.tipo == :perdida
      assert mascota.especie == "perro"
      assert mascota.nombre == "Luna"
      assert mascota.caracteristicas == "Collar rojo, oreja izquierda caída"
      assert mascota.color == "negra"
      assert mascota.tamano == :mediano
      assert mascota.zona == "zona_norte"
      assert mascota.contacto == "300 123 4567"
      assert mascota.estado == :activa
      assert mascota.coincidencia_con == nil
    end

    test "acepta el tipo como texto, como llega desde comandos y formularios" do
      assert {:ok, %{tipo: :perdida}} = Mascota.nuevo("M001", %{@datos_validos | tipo: "lost"})

      assert {:ok, %{tipo: :encontrada}} =
               Mascota.nuevo("M002", %{@datos_validos | tipo: "found"})

      assert {:ok, %{tipo: :encontrada}} =
               Mascota.nuevo("M003", %{@datos_validos | tipo: " Encontrada "})
    end

    test "un nombre vacío o 'desconocido' se guarda como nil" do
      assert {:ok, %{nombre: nil}} =
               Mascota.nuevo("M001", %{@datos_validos | nombre: "desconocido"})

      assert {:ok, %{nombre: nil}} = Mascota.nuevo("M001", %{@datos_validos | nombre: "   "})
      assert {:ok, %{nombre: nil}} = Mascota.nuevo("M001", Map.delete(@datos_validos, :nombre))
    end

    test "las características son opcionales" do
      datos = Map.delete(@datos_validos, :caracteristicas)
      assert {:ok, %{caracteristicas: ""}} = Mascota.nuevo("M001", datos)
    end

    test "acepta los tamaños con tilde, sin tilde y en femenino" do
      assert {:ok, %{tamano: :pequeno}} =
               Mascota.nuevo("M001", %{@datos_validos | tamano: "Pequeño"})

      assert {:ok, %{tamano: :pequeno}} =
               Mascota.nuevo("M001", %{@datos_validos | tamano: "pequeña"})

      assert {:ok, %{tamano: :mediano}} =
               Mascota.nuevo("M001", %{@datos_validos | tamano: "MEDIANO"})

      assert {:ok, %{tamano: :grande}} =
               Mascota.nuevo("M001", %{@datos_validos | tamano: :grande})
    end

    test "rechaza un tipo inválido" do
      assert {:error, :tipo_invalido} = Mascota.nuevo("M001", %{@datos_validos | tipo: :otro})

      assert {:error, :tipo_invalido} =
               Mascota.nuevo("M001", %{@datos_validos | tipo: "extraviada"})

      assert {:error, :tipo_invalido} = Mascota.nuevo("M001", Map.delete(@datos_validos, :tipo))
    end

    test "rechaza los campos obligatorios vacíos o ausentes" do
      assert {:error, :especie_vacia} = Mascota.nuevo("M001", %{@datos_validos | especie: "  "})
      assert {:error, :color_vacio} = Mascota.nuevo("M001", %{@datos_validos | color: ""})
      assert {:error, :zona_vacia} = Mascota.nuevo("M001", %{@datos_validos | zona: ""})

      assert {:error, :contacto_vacio} =
               Mascota.nuevo("M001", Map.delete(@datos_validos, :contacto))
    end

    test "rechaza un tamaño inválido" do
      assert {:error, :tamano_invalido} =
               Mascota.nuevo("M001", %{@datos_validos | tamano: "gigante"})

      assert {:error, :tamano_invalido} = Mascota.nuevo("M001", %{@datos_validos | tamano: 5})
    end

    test "rechaza datos que no son un mapa o un id que no es texto" do
      assert {:error, :datos_invalidos} = Mascota.nuevo("M001", nil)
      assert {:error, :datos_invalidos} = Mascota.nuevo("M001", [])
      assert {:error, :datos_invalidos} = Mascota.nuevo(1, @datos_validos)
    end

    test "con varios errores informa el primero, en el orden de validación" do
      datos = %{@datos_validos | tipo: :otro, especie: "", zona: ""}
      assert {:error, :tipo_invalido} = Mascota.nuevo("M001", datos)
    end
  end

  describe "cambiar_estado/2" do
    test "un reporte activo puede pasar a posible coincidencia" do
      assert {:ok, %{estado: :posible_coincidencia}} =
               Mascota.cambiar_estado(mascota_valida(), :posible_coincidencia)
    end

    test "una posible coincidencia puede descartarse y volver a activa" do
      {:ok, mascota} = Mascota.cambiar_estado(mascota_valida(), :posible_coincidencia)
      assert {:ok, %{estado: :activa}} = Mascota.cambiar_estado(mascota, :activa)
    end

    test "una posible coincidencia puede resolverse" do
      {:ok, mascota} = Mascota.cambiar_estado(mascota_valida(), :posible_coincidencia)
      assert {:ok, %{estado: :resuelta}} = Mascota.cambiar_estado(mascota, :resuelta)
    end

    test "un reporte activo puede cerrarse directamente" do
      assert {:ok, %{estado: :resuelta}} = Mascota.cambiar_estado(mascota_valida(), :resuelta)
    end

    test "no se puede cerrar dos veces un reporte" do
      {:ok, resuelta} = Mascota.cambiar_estado(mascota_valida(), :resuelta)
      assert {:error, :ya_resuelta} = Mascota.cambiar_estado(resuelta, :resuelta)
    end

    test "un reporte resuelto no puede cambiar a ningún otro estado" do
      {:ok, resuelta} = Mascota.cambiar_estado(mascota_valida(), :resuelta)
      assert {:error, :ya_resuelta} = Mascota.cambiar_estado(resuelta, :activa)
      assert {:error, :ya_resuelta} = Mascota.cambiar_estado(resuelta, :posible_coincidencia)
    end

    test "rechaza quedarse en el mismo estado" do
      assert {:error, :transicion_invalida} = Mascota.cambiar_estado(mascota_valida(), :activa)
    end

    test "rechaza un estado que no existe" do
      assert {:error, :estado_invalido} = Mascota.cambiar_estado(mascota_valida(), :perdida)
    end

    test "no modifica el reporte original (inmutabilidad)" do
      original = mascota_valida()
      {:ok, _cambiada} = Mascota.cambiar_estado(original, :resuelta)
      assert original.estado == :activa
    end
  end
end

# HOL
