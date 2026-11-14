defmodule Interfaz.Fuente.Zonas do
  @moduledoc """
  Zonas, sectores y puntos de atención, por `Epicenter.GenserverZonas`.

  La lógica de zonas trabaja sobre el mapa completo: se carga el JSON, el
  GenServer aplica el cambio y el resultado se guarda.
  """

  import Interfaz.Fuente.Comun

  alias Epicenter.{GenserverZonas, Persistencia}
  alias Interfaz.Fuente.Catalogos

  @doc "Zonas ordenadas por nombre, con el total de personas afectadas."
  def zonas do
    Persistencia.carga_zonas()
    |> GenserverZonas.listar()
    |> Enum.map(fn zona ->
      zona
      |> Map.from_struct()
      |> Map.put(:afectadas, Epicenter.Zona.total_afectadas(zona))
    end)
    |> Enum.sort_by(& &1.nombre)
  end

  @doc "Comando `register_zone`: el código lo genera la lógica."
  def registrar_zona(nombre, nivel, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre de la zona."),
         {:ok, nivel} <- atomo(nivel, Catalogos.niveles(), "Nivel de afectación no válido.") do
      con_permiso(usuario, :administrar_configuracion, nil, fn _actor ->
        Persistencia.carga_zonas()
        |> GenserverZonas.registrar(nombre, nivel)
        |> guardar("Zona #{nombre} registrada.")
      end)
    end
  end

  @doc "Comando `register_sector`: el sector queda dentro de la zona elegida."
  def registrar_sector(codigo_zona, nombre, nivel, afectadas, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del sector."),
         {:ok, nivel} <- atomo(nivel, Catalogos.niveles(), "Nivel de afectación no válido."),
         {:ok, afectadas} <-
           entero(
             afectadas,
             0,
             "Las personas afectadas deben ser un número entero mayor o igual a 0."
           ) do
      con_permiso(usuario, :registrar_sector, codigo_zona, fn _actor ->
        Persistencia.carga_zonas()
        |> GenserverZonas.registrar_sector(codigo_zona, nombre, nivel, afectadas)
        |> guardar("Sector #{nombre} registrado.")
      end)
    end
  end

  @doc "Comando `register_point`: el punto queda dentro del sector elegido."
  def registrar_punto(codigo_zona, codigo_sector, nombre, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del punto de atención.") do
      con_permiso(usuario, :registrar_punto_atencion, codigo_zona, fn _actor ->
        Persistencia.carga_zonas()
        |> GenserverZonas.registrar_punto(codigo_zona, codigo_sector, nombre)
        |> guardar("Punto de atención #{nombre} registrado.")
      end)
    end
  end

  @doc "Sectores y puntos acumulados de una zona (`nil` si no existe)."
  def estadisticas(codigo_zona) do
    case GenserverZonas.estadisticas(Persistencia.carga_zonas(), codigo_zona) do
      {:ok, estadisticas} -> estadisticas
      {:error, _motivo} -> nil
    end
  end

  # Si la lógica respondió {:ok, zonas}, se guardan; si no, se traduce el error.
  defp guardar({:ok, zonas}, mensaje) do
    Persistencia.guardar_zonas(zonas)
    {:ok, mensaje}
  end

  defp guardar({:error, motivo}, _mensaje), do: {:error, traducir(motivo)}
end
