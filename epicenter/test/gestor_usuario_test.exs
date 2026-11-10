defmodule Epicenter.GestorUsuarioTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorUsuario
  alias Epicenter.Persistencia
  alias Epicenter.Usuario

  setup do
    ruta = Path.expand("../lib/Datos/Usuario.json", __DIR__)
    contenido_original = File.read!(ruta)
    File.write!(ruta, "[]")

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    :ok
  end

  test "autentica comparando la contraseña tal como se recibe" do
    usuario = %Usuario{nombre_usuario: "Ana", contrasena: "ClaveSegura"}

    assert {:error, "Usuario o contraseña incorrectos"} =
             GestorUsuario.login("Ana", "clavesegura", [usuario])
  end

  test "registra el usuario automáticamente y permite iniciar sesión después" do
    assert {:ok, usuario} = GestorUsuario.login("Ana", "ClaveSegura", [])
    assert usuario.nombre_usuario == "Ana"

    assert {:ok, [%Usuario{nombre_usuario: "Ana", contrasena: "ClaveSegura"}]} =
             Persistencia.carga_usuarios()

    assert {:ok, ^usuario} =
             GestorUsuario.login("Ana", "ClaveSegura", [usuario])
  end

  test "registra primero los datos obligatorios y luego completa el perfil buscando por usuario" do
    assert {:ok, %Usuario{nombre_usuario: "Ana"}} =
             GestorUsuario.registro([], "Ana", "ClaveSegura")

    assert {:ok, otro_usuario} = GestorUsuario.registro([], "Luis", "OtraClave")

    assert {:ok, usuario_completo} =
             GestorUsuario.completar_informacion("Ana", "Ana Pérez", "zona-1")

    assert usuario_completo.nombre_usuario == "Ana"
    assert usuario_completo.contrasena == "ClaveSegura"
    assert usuario_completo.nombre_completo == "Ana Pérez"
    assert usuario_completo.zona_principal == "zona-1"

    assert {:ok, [^otro_usuario, ^usuario_completo]} = Persistencia.carga_usuarios()
  end
end
