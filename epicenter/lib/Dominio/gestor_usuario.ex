defmodule Epicenter.GestorUsuario do
  @moduledoc """
  Modulo disponible para gestionar usuarios, incluyendo login y registro de nuevos usuarios y cualquier otra funcionalidad que se requiera para la gestion de usuarios.
  """
  @doc """
    Esta funcion permite realizar el login de un usuario, verificando que el nombre de usuario y la contraseña sean correctos. Si el login es exitoso, se devuelve un tuple con :ok y el usuario, de lo contrario se devuelve un tuple con :error y un mensaje de error.
  """
  def login(usuario, contrasena, usuarios) do
    usuarios =
      (usuarios ++ Epicenter.Persistencia.carga_usuarios())
      |> Enum.uniq_by(& &1.nombre_usuario)

    case Enum.find(usuarios, fn u -> u.nombre_usuario == usuario end) do
      nil ->
        registro(usuarios, usuario, contrasena)

      perfil ->
        if perfil.contrasena == contrasena do
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
    case Epicenter.Usuario.nuevo(usuario, password, :ciudadano) do
      {:ok, nuevo_usuario} ->
        usuarios =
          (usuarios ++ Epicenter.Persistencia.carga_usuarios())
          |> Enum.uniq_by(& &1.nombre_usuario)

        if Enum.any?(usuarios, fn u -> u.nombre_usuario == usuario end) do
          {:error, "El nombre de usuario ya está en uso"}
        else
          Epicenter.Persistencia.guardar_usuarios([nuevo_usuario | usuarios])
          {:ok, nuevo_usuario}
        end

      {:error, mensaje} ->
        {:error, mensaje}
    end
  end
end
