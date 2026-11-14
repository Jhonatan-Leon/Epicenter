defmodule Epicenter.GestorAlbergueTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorAlbergue
  alias Epicenter.Persistencia

  setup do
    codigo_zona = Persistencia.carga_zonas() |> Map.keys() |> hd()
    ruta = Persistencia.ruta_datos("Albergue.json")
    contenido_original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    {:ok, codigo_zona: codigo_zona}
  end

  test "crea, consulta, actualiza y elimina un albergue persistido", %{codigo_zona: zona} do
    assert {:ok, albergue} = GestorAlbergue.registro("Refugio", zona, 10)
    assert {:ok, [^albergue]} = GestorAlbergue.listar()
    assert {:ok, ^albergue} = GestorAlbergue.obtener(albergue.codigo)

    actualizado = %{albergue | capacidad: 20}
    assert {:ok, ^actualizado} = GestorAlbergue.actualizar(albergue.codigo, actualizado)
    assert {:ok, [%{capacidad: 20}]} = Persistencia.cargar_albergues()

    assert {:ok, ^actualizado} = GestorAlbergue.eliminar(albergue.codigo)
    assert {:ok, []} == GestorAlbergue.listar()
  end
end
