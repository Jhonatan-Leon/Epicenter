defmodule Epicenter.GestorUsuario do
  @moduledoc """
  Modulo disponible para gestionar usuarios, incluyendo login y registro de nuevos usuarios y cualquier otra funcionalidad que se requiera para la gestion de usuarios.
  """
  @doc """
    Esta funcion permite realizar el login de un usuario, verificando que el nombre de usuario y la contraseña sean correctos. Si el login es exitoso, se devuelve un tuple con :ok y el usuario, de lo contrario se devuelve un tuple con :error y un mensaje de error.
  """
  def login(usuario, contrasena, usuarios) do
    with {:ok, usuarios_guardados} <- Epicenter.Persistencia.carga_usuarios() do
      usuarios =
        (usuarios ++ usuarios_guardados)
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
  end

  @doc """
    Esta funcion permite registrar un nuevo usuario, verificando que el nombre de usuario no esté en uso. Si el registro es exitoso, se devuelve un tuple con :ok y el nuevo usuario, de lo contrario se devuelve un tuple con :error y un mensaje de error.
  """
  def registro(usuarios, usuario, password) do
    case Epicenter.Usuario.nuevo(usuario, password, :ciudadano) do
      {:ok, nuevo_usuario} ->
        with {:ok, usuarios_guardados} <- Epicenter.Persistencia.carga_usuarios() do
          usuarios =
            (usuarios ++ usuarios_guardados)
            |> Enum.uniq_by(& &1.nombre_usuario)

          if Enum.any?(usuarios, fn u -> u.nombre_usuario == usuario end) do
            {:error, "El nombre de usuario ya está en uso"}
          else
            Epicenter.Persistencia.guardar_usuarios([nuevo_usuario | usuarios])
            {:ok, nuevo_usuario}
          end
        end

      {:error, mensaje} ->
        {:error, mensaje}
    end
  end

  def completar_informacion(nombre_usuario, nombre_completo, zona_principal) do
    with {:ok, usuarios} <- listar(),
         {:ok, usuario} <- buscar_usuario(usuarios, nombre_usuario) do
      with {:ok, usuario_actualizado} <-
             Epicenter.Usuario.completar_usuario(usuario, nombre_completo, zona_principal) do
        guardar_usuario_actualizado(usuarios, usuario, usuario_actualizado)
      end
    else
      {:error, razon} -> {:error, razon}
    end
  end

  def listar, do: Epicenter.Persistencia.carga_usuarios()

  def obtener(nombre_usuario) do
    with {:ok, usuarios} <- listar() do
      case Enum.find(usuarios, &(&1.nombre_usuario == nombre_usuario)) do
        nil -> {:error, "Usuario no encontrado"}
        usuario -> {:ok, usuario}
      end
    end
  end

  def actualizar(nombre_usuario, %Epicenter.Usuario{nombre_usuario: nombre_usuario} = usuario) do
    with {:ok, usuarios} <- listar() do
      if Enum.any?(usuarios, &(&1.nombre_usuario == nombre_usuario)) do
        Epicenter.Persistencia.guardar_usuarios(
          Enum.map(usuarios, fn existente ->
            if existente.nombre_usuario == nombre_usuario, do: usuario, else: existente
          end)
        )

        {:ok, usuario}
      else
        {:error, "Usuario no encontrado"}
      end
    end
  end

  def actualizar(_nombre_usuario, _usuario), do: {:error, "El usuario no es válido"}

  def eliminar(nombre_usuario) do
    with {:ok, usuarios} <- listar() do
      case Enum.find(usuarios, &(&1.nombre_usuario == nombre_usuario)) do
        nil ->
          {:error, "Usuario no encontrado"}

        usuario ->
          Epicenter.Persistencia.guardar_usuarios(
            Enum.reject(usuarios, &(&1.nombre_usuario == nombre_usuario))
          )

          {:ok, usuario}
      end
    end
  end

  defp buscar_usuario(usuarios, nombre_usuario) do
    case Enum.find(usuarios, &(&1.nombre_usuario == nombre_usuario)) do
      nil -> {:error, "Usuario no encontrado"}
      usuario -> {:ok, usuario}
    end
  end

  defp guardar_usuario_actualizado(usuarios, usuario, usuario_actualizado) do
    usuarios_actualizados =
      Enum.map(usuarios, fn existente ->
        if existente.nombre_usuario == usuario.nombre_usuario,
          do: usuario_actualizado,
          else: existente
      end)

    Epicenter.Persistencia.guardar_usuarios(usuarios_actualizados)
    {:ok, usuario_actualizado}
  end
end
