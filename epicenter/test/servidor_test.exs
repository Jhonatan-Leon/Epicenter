defmodule Epicenter.GenserverTest do
  use ExUnit.Case, async: false

  alias Epicenter.Persistencia

  setup do
    ruta = Persistencia.ruta_datos("Usuario.json")
    contenido_original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    :ok
  end

  test "inicia bajo la aplicación y responde a las consultas de usuarios" do
    assert is_pid(Process.whereis(Epicenter.Genserver))
    assert {:ok, usuarios} = Epicenter.Genserver.listar()
    assert is_list(usuarios)
  end

  test "autentica y registra usuarios mediante login/2" do
    assert {:ok, usuario} = Epicenter.Genserver.login("Ana", "ClaveSegura")
    assert usuario.nombre_usuario == "Ana"

    assert {:error, "Usuario o contraseña incorrectos"} =
             Epicenter.Genserver.login("Ana", "clave-incorrecta")

    assert {:ok, ^usuario} = Epicenter.Genserver.login("Ana", "ClaveSegura")

    assert {:ok, [%{nombre_usuario: "Ana"}]} = Persistencia.carga_usuarios()
  end
end
