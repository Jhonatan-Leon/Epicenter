defmodule Epicenter.Persistencia do
  @path_usuarios Path.join(__DIR__, "Usuario.json")
  @path_zonas Path.join(__DIR__, "Zonas.json")
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

  def guardar_zonas(zonas) do
    lista = Enum.map(Map.values(zonas), fn zona -> zona_a_mapa(zona) end)
    {:ok, data} = Jason.encode(lista, pretty: true)
    File.write!(@path_zonas, data)
    zonas
  end

  defp zona_a_mapa(zona) do
    %{
      codigo: zona.codigo,
      nombre: zona.nombre,
      nivel: zona.nivel,
      sectores: Enum.map(zona.sectores, fn s -> sector_a_mapa(s) end)
    }
  end

  defp sector_a_mapa(sector) do
    %{
      codigo: sector.codigo,
      nombre: sector.nombre,
      nivel: sector.nivel,
      afectadas: sector.afectadas,
      puntos: Enum.map(sector.puntos, fn p -> punto_a_mapa(p) end)
    }
  end

  defp punto_a_mapa(punto), do: %{codigo: punto.codigo, nombre: punto.nombre}

  def carga_zonas do
    case File.read(@path_zonas) do
      {:ok, contenido} ->
        mapa = JSON.decode!(contenido)
        # Conversion de struct
        Enum.map(mapa, fn zona -> map_a_struct(zona) end)

      {:error, razon} ->
        IO.puts("Error al cargar zonas: #{razon}")
        []
    end
  end

  defp mapa_a_zona(mapa) do
    %Zona{
      codigo: mapa["codigo"],
      nombre: mapa["nombre"],
      nivel: nivel_a_atomo(mapa["nivel"]),
      sectores: Enum.map(mapa["sectores"], fn s -> mapa_a_sector(s) end)
    }
  end

  defp mapa_a_sector(mapa) do
    %Sector{
      codigo: mapa["codigo"],
      nombre: mapa["nombre"],
      nivel: nivel_a_atomo(mapa["nivel"]),
      afectadas: mapa["afectadas"],
      puntos: Enum.map(mapa["puntos"], fn p -> mapa_a_punto(p) end)
    }
  end

  defp mapa_a_punto(mapa), do: %PuntoAtencion{codigo: mapa["codigo"], nombre: mapa["nombre"]}

  defp nivel_a_atomo("critico"), do: :critico
  defp nivel_a_atomo("alto"), do: :alto
  defp nivel_a_atomo("medio"), do: :medio
  defp nivel_a_atomo("bajo"), do: :bajo
end
