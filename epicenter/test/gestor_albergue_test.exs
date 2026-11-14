defmodule Epicenter.GestorAlbergueTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorAlbergue
  alias Epicenter.Persistencia

  setup do
    ruta = Path.expand("../lib/Datos/Albergue.json", __DIR__)
    contenido_original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    :ok
  end

  test "crea, consulta, actualiza y elimina un albergue persistido" do
    assert {:ok, albergue} = GestorAlbergue.registro("Refugio", "zona-1", 10)
    assert {:ok, [^albergue]} = GestorAlbergue.listar()
    assert {:ok, ^albergue} = GestorAlbergue.obtener(albergue.codigo)

    actualizado = %{albergue | capacidad: 20}
    assert {:ok, ^actualizado} = GestorAlbergue.actualizar(albergue.codigo, actualizado)
    assert {:ok, [%{capacidad: 20}]} = Persistencia.cargar_albergues()

    assert {:ok, ^actualizado} = GestorAlbergue.eliminar(albergue.codigo)
    assert {:ok, []} == GestorAlbergue.listar()
  end
end
