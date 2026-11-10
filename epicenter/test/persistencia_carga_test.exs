defmodule Epicenter.PersistenciaCargaTest do
  use ExUnit.Case, async: true

  alias Epicenter.Persistencia

  test "carga un documento externo y lo convierte a la estructura solicitada" do
    ruta =
      crear_archivo_temporal(
        Jason.encode!([
          %{
            "codigo" => "recurso-1",
            "nombre" => "Agua",
            "categoria" => "bebida",
            "unidad_medida" => "litros",
            "cantidad_disponible" => 12
          }
        ])
      )

    assert {:ok, [%Epicenter.Recurso{codigo: "recurso-1", cantidad_disponible: 12}]} =
             Persistencia.cargar_archivo(ruta, Epicenter.Recurso)
  end

  test "carga mascotas usando sus campos y conserva el estado del reporte" do
    ruta =
      crear_archivo_temporal(
        Jason.encode!([
          %{
            "id" => "mascota-1",
            "tipo" => "perdida",
            "especie" => "Perro",
            "nombre" => "Luna",
            "caracteristicas" => "Collar rojo",
            "color" => "Negra",
            "tamano" => "mediano",
            "zona" => "zona-norte",
            "contacto" => "555-0100",
            "estado" => "posible_coincidencia",
            "coincidencia_con" => "mascota-2"
          }
        ])
      )

    assert {:ok,
            [
              %Epicenter.Mascota{
                id: "mascota-1",
                tipo: :perdida,
                especie: "perro",
                zona: "zona-norte",
                estado: :posible_coincidencia,
                coincidencia_con: "mascota-2"
              }
            ]} = Persistencia.cargar_archivo(ruta, Epicenter.Mascota)
  end

  test "acepta los nombres anteriores de zona y características al cargar mascotas" do
    ruta =
      crear_archivo_temporal(
        Jason.encode!([
          %{
            "id" => "mascota-antigua",
            "tipo" => "encontrada",
            "especie" => "Gato",
            "carateristicas" => "Collar azul",
            "color" => "Blanco",
            "tamano" => "pequeno",
            "codigo_zona" => "zona-sur",
            "contacto" => "555-0120"
          }
        ])
      )

    assert {:ok, [%Epicenter.Mascota{zona: "zona-sur", caracteristicas: "Collar azul"}]} =
             Persistencia.cargar_archivo(ruta, Epicenter.Mascota)
  end

  test "devuelve el error de lectura sin lanzar una excepción" do
    ruta =
      Path.join(
        System.tmp_dir!(),
        "archivo-inexistente-#{System.unique_integer([:positive])}.json"
      )

    archivo = Path.expand(ruta)

    assert {:error, %{archivo: ^archivo, etapa: :lectura, razon: :enoent}} =
             Persistencia.cargar_archivo(ruta, Epicenter.Recurso)
  end

  test "informa cuando el contenido no es JSON válido" do
    ruta = crear_archivo_temporal("{contenido inválido")

    assert {:error, %{etapa: :decodificacion, razon: %Jason.DecodeError{}}} =
             Persistencia.cargar_archivo(ruta, Epicenter.Recurso)
  end

  test "rechaza raíces y registros con una forma inesperada" do
    ruta_raiz = crear_archivo_temporal(Jason.encode!(%{"codigo" => "recurso-1"}))
    ruta_registro = crear_archivo_temporal(Jason.encode!([nil]))
    ruta_campos = crear_archivo_temporal(Jason.encode!([%{"codigo" => "recurso-1"}]))

    assert {:error, %{etapa: :validacion, razon: :se_esperaba_una_lista}} =
             Persistencia.cargar_archivo(ruta_raiz, Epicenter.Recurso)

    assert {:error, %{etapa: :validacion, registro: 1, razon: :registro_no_es_objeto}} =
             Persistencia.cargar_archivo(ruta_registro, Epicenter.Recurso)

    assert {:error, %{etapa: :validacion, registro: 1, razon: {:campos_requeridos, campos}}} =
             Persistencia.cargar_archivo(ruta_campos, Epicenter.Recurso)

    assert :nombre in campos
  end

  test "rechaza estructuras que no tienen conversor de carga" do
    ruta = crear_archivo_temporal("[]")

    assert {:error, %{etapa: :estructura, razon: :no_soportada}} =
             Persistencia.cargar_archivo(ruta, Epicenter.Zona)
  end

  defp crear_archivo_temporal(contenido) do
    ruta =
      Path.join(
        System.tmp_dir!(),
        "epicenter-carga-#{System.unique_integer([:positive])}.json"
      )

    File.write!(ruta, contenido)
    ExUnit.Callbacks.on_exit(fn -> File.rm(ruta) end)
    ruta
  end
end
