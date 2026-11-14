defmodule Epicenter.GestorPersonaFamiliaTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorPersona

  setup do
    ruta = Path.expand("../lib/Datos/Persona.json", __DIR__)
    original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, original) end)

    :ok
  end

  defp documentos({:ok, personas}), do: personas |> Enum.map(& &1.documento) |> Enum.sort()

  # Tres personas como las del ejemplo de la interfaz.
  defp cargar_personas do
    {:ok, _} = GestorPersona.reportar_persona("1094887123", "Andrés Gómez", "34", "zona_norte", "reportada", "carmen")
    {:ok, _} = GestorPersona.reportar_persona("41923554", "María López", 67, "centro", :sin_informacion, "laura")
    {:ok, _} = GestorPersona.reportar_persona("18512990", "Luis Pérez", "52", "occidente", "reportada", "andres")
    :ok
  end

  describe "reportar_persona/6" do
    test "acepta los datos como texto, como los manda la interfaz" do
      assert {:ok, persona} =
               GestorPersona.reportar_persona("1094887123", " Andrés Gómez ", "34", "zona_norte", "reportada", "carmen")

      assert persona.documento == "1094887123"
      assert persona.nombre == "Andrés Gómez"
      assert persona.edad == 34
      assert persona.codigo_zona == "zona_norte"
      assert persona.estado == :reportada
      assert persona.codigo_albergue == nil
    end

    test "crea el primer registro del historial" do
      {:ok, persona} = GestorPersona.reportar_persona("1", "Ana", 20, "centro", "reportada", "carmen")

      assert [%{estado: :reportada, por: "carmen", fecha: %DateTime{}}] = persona.historial
    end

    test "se guarda y se recupera con átomos y fechas" do
      {:ok, _} = GestorPersona.reportar_persona("1", "Ana", 20, "centro", "en_albergue", "carmen")

      assert {:ok, persona} = GestorPersona.obtener_por_documento("1")
      assert persona.estado == :en_albergue
      assert [%{estado: :en_albergue, por: "carmen", fecha: %DateTime{}}] = persona.historial
    end

    test "rechaza un documento repetido" do
      {:ok, _} = GestorPersona.reportar_persona("1", "Ana", 20, "centro", "reportada")

      assert {:error, :documento_duplicado} =
               GestorPersona.reportar_persona(" 1 ", "Otra", 30, "centro", "reportada")
    end

    test "rechaza campos vacíos" do
      assert {:error, :documento_vacio} = GestorPersona.reportar_persona("  ", "Ana", 20, "centro", "reportada")
      assert {:error, :nombre_vacio} = GestorPersona.reportar_persona("1", "", 20, "centro", "reportada")
      assert {:error, :zona_vacia} = GestorPersona.reportar_persona("1", "Ana", 20, "", "reportada")
      assert {:error, :documento_vacio} = GestorPersona.reportar_persona(nil, "Ana", 20, "centro", "reportada")
    end

    test "rechaza una edad inválida" do
      for edad <- ["", "abc", "-1", "34.5", -5, 121, nil] do
        assert {:error, :edad_invalida} =
                 GestorPersona.reportar_persona("1", "Ana", edad, "centro", "reportada")
      end
    end

    test "rechaza un estado que no existe" do
      assert {:error, :estado_invalido} = GestorPersona.reportar_persona("1", "Ana", 20, "centro", "perdido")
      assert {:error, :estado_invalido} = GestorPersona.reportar_persona("1", "Ana", 20, "centro", nil)
    end

    test "no guarda nada si los datos son inválidos" do
      {:error, _} = GestorPersona.reportar_persona("1", "Ana", "abc", "centro", "reportada")
      assert {:ok, []} = GestorPersona.listar()
    end
  end

  describe "cambiar_estado/3" do
    setup do
      cargar_personas()
    end

    test "cambia el estado y agrega el cambio al historial" do
      assert {:ok, persona} = GestorPersona.cambiar_estado("1094887123", "localizada", "carlos")
      assert persona.estado == :localizada

      assert [
               %{estado: :reportada, por: "carmen"},
               %{estado: :localizada, por: "carlos", fecha: %DateTime{}}
             ] = persona.historial
    end

    test "el historial se conserva al guardar y cargar" do
      {:ok, _} = GestorPersona.cambiar_estado("1094887123", :localizada, "carlos")
      {:ok, _} = GestorPersona.cambiar_estado("1094887123", :en_albergue, "andres")

      assert {:ok, [reportada, localizada, en_albergue]} = GestorPersona.historial("1094887123")
      assert {reportada.estado, localizada.estado, en_albergue.estado} == {:reportada, :localizada, :en_albergue}
      assert en_albergue.por == "andres"
    end

    test "desde sin información solo se puede reportar o localizar" do
      assert {:error, :transicion_invalida} = GestorPersona.cambiar_estado("41923554", "reunificada")
      assert {:error, :transicion_invalida} = GestorPersona.cambiar_estado("41923554", "en_albergue")
      assert {:ok, _} = GestorPersona.cambiar_estado("41923554", "reportada")
    end

    test "rechaza quedarse en el mismo estado" do
      assert {:error, :transicion_invalida} = GestorPersona.cambiar_estado("1094887123", "reportada")
    end

    test "una persona reunificada no cambia más" do
      {:ok, _} = GestorPersona.cambiar_estado("1094887123", "localizada")
      {:ok, _} = GestorPersona.cambiar_estado("1094887123", "reunificada")

      assert {:error, :ya_reunificada} = GestorPersona.cambiar_estado("1094887123", "localizada")
    end

    test "una transición inválida no cambia el historial" do
      {:error, :transicion_invalida} = GestorPersona.cambiar_estado("41923554", "reunificada")
      assert {:ok, [%{estado: :sin_informacion}]} = GestorPersona.historial("41923554")
    end

    test "rechaza un estado que no existe o una persona que no existe" do
      assert {:error, :estado_invalido} = GestorPersona.cambiar_estado("1094887123", "volando")
      assert {:error, "Persona no encontrada"} = GestorPersona.cambiar_estado("999", "localizada")
    end
  end

  describe "buscar/1" do
    setup do
      cargar_personas()
    end

    test "sin filtros devuelve todas las personas" do
      assert documentos(GestorPersona.buscar()) == ["1094887123", "18512990", "41923554"]
    end

    test "el texto busca en el nombre sin importar tildes ni mayúsculas" do
      assert documentos(GestorPersona.buscar(texto: "andres")) == ["1094887123"]
      assert documentos(GestorPersona.buscar(texto: "LÓPEZ")) == ["41923554"]
      assert documentos(GestorPersona.buscar(nombre: "pérez")) == ["18512990"]
    end

    test "el texto también busca en el documento" do
      assert documentos(GestorPersona.buscar(texto: "4192")) == ["41923554"]
    end

    test "el documento se busca exacto" do
      assert documentos(GestorPersona.buscar(documento: "18512990")) == ["18512990"]
      assert {:ok, []} = GestorPersona.buscar(documento: "1851")
    end

    test "filtra por zona y por estado" do
      assert documentos(GestorPersona.buscar(zona: "centro")) == ["41923554"]
      assert documentos(GestorPersona.buscar(estado: :reportada)) == ["1094887123", "18512990"]
      assert documentos(GestorPersona.buscar(estado: "sin_informacion")) == ["41923554"]
    end

    test "acepta el mapa con claves de texto y campos vacíos que manda el formulario" do
      assert documentos(GestorPersona.buscar(%{"texto" => "", "zona" => "", "estado" => ""})) ==
               ["1094887123", "18512990", "41923554"]

      assert documentos(GestorPersona.buscar(%{"texto" => "luis", "zona" => "occidente", "estado" => "reportada"})) ==
               ["18512990"]
    end

    test "combina filtros" do
      assert {:ok, []} = GestorPersona.buscar(zona: "centro", estado: :reportada)
    end

    test "rechaza filtros inválidos" do
      assert {:error, :filtro_invalido} = GestorPersona.buscar(edad: 30)
      assert {:error, :filtro_invalido} = GestorPersona.buscar(zona: 5)
      assert {:error, :estado_invalido} = GestorPersona.buscar(estado: "volando")
      assert {:error, :filtros_invalidos} = GestorPersona.buscar("andres")
    end
  end
end
