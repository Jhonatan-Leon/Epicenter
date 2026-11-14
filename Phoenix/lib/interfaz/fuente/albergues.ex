defmodule Interfaz.Fuente.Albergues do
  @moduledoc "Albergues, ingresos y salidas, por `Epicenter.GenserverAlbergue`."

  import Interfaz.Fuente.Comun

  alias Epicenter.{Albergue, GenserverAlbergue}

  @doc "Albergues ordenados por nombre."
  def albergues do
    GenserverAlbergue.listar() |> lista(&a_mapa/1) |> Enum.sort_by(& &1.nombre)
  end

  @doc "Reporte de ocupación: de mayor a menor."
  def reporte, do: GenserverAlbergue.reporte_ocupacion() |> lista(&a_mapa/1)

  @doc "Cupos libres sumando los albergues de una zona."
  def cupos_de_zona(codigo_zona) do
    case GenserverAlbergue.listar() do
      {:ok, albergues} -> GenserverAlbergue.cupos_por_zona(albergues, codigo_zona)
      {:error, _motivo} -> 0
    end
  end

  @doc "Comando `register_shelter`: el código lo genera la lógica."
  def registrar(nombre, zona, capacidad, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del albergue."),
         {:ok, capacidad} <-
           entero(capacidad, 1, "La capacidad debe ser un número entero mayor que 0.") do
      con_permiso(usuario, :registrar_albergue, zona, fn _actor ->
        nombre
        |> GenserverAlbergue.registro(zona, capacidad)
        |> responder(&"Albergue #{&1.nombre} registrado.")
      end)
    end
  end

  @doc "Comando `register_entry`: la persona entra y su estado pasa a en albergue."
  def registrar_ingreso(codigo, documento, usuario) do
    con_albergue(codigo, usuario, :registrar_ingreso_albergue, fn actor ->
      codigo
      |> GenserverAlbergue.registrar_ingreso(documento, actor.nombre_usuario)
      |> responder(&"Ingreso registrado en #{&1.nombre}.")
    end)
  end

  @doc "Comando `register_exit`."
  def registrar_salida(codigo, documento, usuario) do
    con_albergue(codigo, usuario, :registrar_salida_albergue, fn _actor ->
      codigo
      |> GenserverAlbergue.registrar_salida(documento)
      |> responder(&"Salida registrada de #{&1.nombre}.")
    end)
  end

  # El permiso se revisa contra la zona del albergue.
  defp con_albergue(codigo, usuario, permiso, funcion) do
    case GenserverAlbergue.obtener(codigo) do
      {:ok, albergue} -> con_permiso(usuario, permiso, albergue.codigo_zona, funcion)
      {:error, motivo} -> {:error, traducir(motivo)}
    end
  end

  defp a_mapa(albergue) do
    %{
      codigo: albergue.codigo,
      nombre: albergue.nombre,
      zona: albergue.codigo_zona,
      capacidad: albergue.capacidad,
      ocupacion: Albergue.ocupacion(albergue),
      cupos: Albergue.cupos(albergue),
      ocupantes: albergue.ocupantes
    }
  end
end
