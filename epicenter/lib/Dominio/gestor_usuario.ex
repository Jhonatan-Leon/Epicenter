defmodule Epicenter.GestorUsuario do
  @moduledoc """
  Modulo disponible para gestionar usuarios, incluyendo login y registro de nuevos usuarios y cualquier otra funcionalidad que se requiera para la gestion de usuarios.
  """
  @doc """
    Esta funcion permite realizar el login de un usuario, verificando que el nombre de usuario y la contraseña sean correctos. Si el login es exitoso, se devuelve un tuple con :ok y el usuario, de lo contrario se devuelve un tuple con :error y un mensaje de error.
  """
  def login(usuario, contrasena, usuarios) do
    case Enum.find(usuarios, fn u -> u.nombre_usuario == String.upcase(usuario) and u.contraseña == String.upcase(contrasena) end) do
      nil -> {:error, "Usuario o contraseña incorrectos"}
      perfil ->
        if String.upcase(perfil.contraseña) == String.upcase(contrasena) and perfil.nombre_usuario == String.upcase(usuario) do
          {:ok, perfil}
        else
          {:error, "Usuario o contraseña incorrectos"}
        end
    end
  end

  @doc """
    Esta funcion permite registrar un nuevo usuario, verificando que el nombre de usuario no esté en uso. Si el registro es exitoso, se devuelve un tuple con :ok y el nuevo usuario, de lo contrario se devuelve un tuple con :error y un mensaje de error.
  """
  def registro(usuarios, usuario, password) do
    case Epicenter.Usuario.nuevo(usuario, password, [:ciudadano]) do
      {:ok, nuevo_usuario} ->
        if Enum.any?(usuarios, fn u -> u.nombre_usuario == String.upcase(usuario) end) do
          {:error, "El nombre de usuario ya está en uso"}
        else
          nuevos_usuarios = [nuevo_usuario | usuarios]

        end

      {:error, mensaje} ->
        {:error, mensaje}
    end
  end
end
