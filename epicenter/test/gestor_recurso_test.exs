defmodule GestorRecursoTest do
  use ExUnit.Case, async: false

  setup do
    ruta = Path.expand("../lib/Datos/Inventario.json", __DIR__)
    contenido_original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    :ok
  end

  test "registra inventarios mediante el GenServer usando el struct vigente" do
    assert {:ok,
            %Epicenter.Inventario{
              id: id,
              codigo_recurso: "recurso-1",
              codigo_centro: "centro-1",
              zonas: ["zona-1"],
              cantidad_disponible: 10
            } = inventario} =
             Epicenter.GenserverInventario.registro(
               "recurso-1",
               "centro-1",
               ["zona-1"],
               10
             )

    assert is_binary(id)
    assert {:ok, [^inventario]} = Epicenter.GenserverInventario.listar()
  end
end
