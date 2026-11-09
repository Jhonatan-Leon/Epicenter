defmodule Epicenter.Mensaje do
  @moduledoc """
  """
  @enforce_keys [:codigo, :remitente, :destinatario, :contenido, :fecha_envio]
  defstruct [:codigo, :remitente, :destinatario, :contenido, :estado, :fecha_envio]

  def nuevo(codigo, remitente, destinatario, contenido, fecha_envio) do
    {:ok, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), remitente: remitente, destinatario: destinatario, contenido: contenido, estado: :pendiente, fecha_envio: Utilidad.generar_fecha_actual()}}
  end
end
