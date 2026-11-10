defmodule Epicenter.GestorAlbergueTest do
  use ExUnit.Case, async: false

  alias Epicenter.Persistencia

  setup do
    ruta = Path.expand("../lib/Datos/Albergue.json", __DIR__)
    contenido_original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    :ok
  end

  test "crea, consulta, actualiza y elimina un albergue persistido" do
    codigo_zona = "A1F03C9E7B2D4410"
    assert {:ok, albergue} = Epicenter.GenserverAlbergue.registro("Refugio", codigo_zona, 10)
    assert {:ok, [^albergue]} = Epicenter.GenserverAlbergue.listar()
    assert {:ok, ^albergue} = Epicenter.GenserverAlbergue.obtener(albergue.codigo)

    actualizado = %{albergue | capacidad: 20}

    assert {:ok, ^actualizado} =
             Epicenter.GenserverAlbergue.actualizar(albergue.codigo, actualizado)

    assert {:ok, [%{capacidad: 20}]} = Persistencia.cargar_albergues()

    assert {:ok, ^actualizado} = Epicenter.GenserverAlbergue.eliminar(albergue.codigo)
    assert {:ok, []} == Epicenter.GenserverAlbergue.listar()
  end
end
