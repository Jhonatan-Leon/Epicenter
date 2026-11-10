defmodule Epicenter.Persistencia do
  @path_usuarios Path.join(__DIR__, "Usuario.json")
  @moduledoc """
    Modulo para la persistencia de datos, que incluye la carga de usuarios desde archivos y la conversión de mapas a structs.

    ##Funciones
    - carga_usuarios/0: Carga los usuarios desde un archivo y devuelve una lista
    - map_a_struct/1: Convierte un mapa de usuario a struct de usuario

  """
  def carga_usuarios do
    case File.read(@path_usuarios) do
      {:ok, contenido} ->
        mapa = JSON.decode!(contenido)
        # Conversion de struct
        Enum.map(mapa, fn usuario -> map_a_struct(usuario) end)

      {:error, razon} ->
        IO.puts("Error al cargar usuarios: #{razon}")
        []
    end
  end

  def map_a_struct(usuario) do
    %Epicenter.Usuario{
      nombre_usuario: usuario["nombre_usuario"],
      contrasena: usuario["contrasena"],
      rol: rol_a_atomos(usuario["rol"])
    }
  end

  defp rol_a_atomos(roles) when is_list(roles), do: Enum.map(roles, &rol_a_atomo/1)
  defp rol_a_atomos(rol), do: rol_a_atomo(rol)

  defp rol_a_atomo("ciudadano"), do: :ciudadano
  defp rol_a_atomo("voluntario"), do: :voluntario
  defp rol_a_atomo("coordinar"), do: :coordinar
  defp rol_a_atomo("administrador"), do: :administrador
  defp rol_a_atomo(rol) when rol in [:ciudadano, :voluntario, :coordinar, :administrador], do: rol
  defp rol_a_atomo(_rol), do: :ciudadano

  def guardar_usuarios(usuarios) do
    list =
      Enum.map(usuarios, fn u ->
        Map.from_struct(u) |> Map.put(:contrasena, to_string(u.contrasena))
      end)

    {:ok, data} = Jason.encode(list, pretty: true)
    File.write!(@path_usuarios, data)
    usuarios
  end
end
