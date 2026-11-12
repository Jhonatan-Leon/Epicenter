defmodule Epicenter.Mensaje do
  @moduledoc """
  """
  @enforce_keys [:codigo, :remitente, :destinatario, :contenido, :fecha_envio]
  defstruct [:codigo, :remitente, :destinatario, :contenido, :estado, :fecha_envio]

  @doc "Estados con los que se marca un mensaje."
  def estados, do: [:pendiente, :entregado]

  def nuevo(remitente, destinatario, contenido) do
    nuevo(nil, remitente, destinatario, contenido, nil)
  end

  def nuevo(_codigo, remitente, destinatario, contenido, _fecha_envio) do
    {:ok,
     %__MODULE__{
       codigo: Utilidad.generar_codigo_unico(),
       remitente: remitente,
       destinatario: destinatario,
       contenido: contenido,
       estado: :pendiente,
       fecha_envio: Utilidad.generar_fecha_actual()
     }}
  end

  def completar_mensaje(%__MODULE__{} = mensaje, estado) do
    {:ok, %__MODULE__{mensaje | estado: estado}}
  end
end
