defmodule Epicenter.GenserverTest do
  use ExUnit.Case, async: false

  alias Epicenter.Persistencia

  setup do
    ruta = Path.expand("../lib/Datos/Usuario.json", __DIR__)
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

  test "inicia los GenServers de gestores y rechaza operaciones no permitidas" do
    servidores = [
      Epicenter.GenserverAlbergue,
      Epicenter.GenserverCentroApoyo,
      Epicenter.GenserverHistorial,
      Epicenter.GenserverInventario,
      Epicenter.GenserverMascota,
      Epicenter.GenserverMensaje,
      Epicenter.GenserverNecesidad,
      Epicenter.GenserverPersona,
      Epicenter.GenserverRecurso,
      Epicenter.GenserverZona,
      Epicenter.GenserverZonas
    ]

    Enum.each(servidores, fn servidor ->
      assert is_pid(Process.whereis(servidor))

      assert {:error, :operacion_no_soportada} =
               GenServer.call(servidor, {:ejecutar, :operacion_desconocida, []})
    end)

    assert {:error, "Albergue no encontrado"} =
             Epicenter.GenserverAlbergue.obtener("__inexistente__")
  end
end
