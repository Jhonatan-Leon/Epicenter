defmodule Epicenter.Actividad do
  @moduledoc """
  Una acción hecha por un usuario. En el archivo se guarda como una línea:
  fecha | usuario | accion | resultado | detalle
  """
  defstruct [:fecha, :usuario, :accion, :resultado, :detalle]

  @separador " | "

  # Convierte la actividad en una línea de texto para Actividad.log
  def a_linea(%__MODULE__{} = actividad) do
    [
      DateTime.to_iso8601(actividad.fecha),
      actividad.usuario,
      actividad.accion,
      actividad.resultado,
      actividad.detalle
    ]
    |> Enum.map(&to_string/1)
    |> Enum.join(@separador)
  end

  # Convierte una línea del archivo en una actividad.
  # parts: 5 deja intacto el detalle aunque traiga el carácter "|".
  def desde_linea(linea) do
    case String.split(linea, @separador, parts: 5) do
      [fecha_texto, usuario, accion, resultado, detalle] ->
        case DateTime.from_iso8601(fecha_texto) do
          {:ok, fecha, _diferencia} ->
            {:ok,
             %__MODULE__{
               fecha: fecha,
               usuario: usuario,
               accion: accion,
               resultado: resultado,
               detalle: detalle
             }}

          {:error, _motivo} ->
            {:error, :fecha_invalida}
        end

      _otra_forma ->
        {:error, :linea_invalida}
    end
  end
end
