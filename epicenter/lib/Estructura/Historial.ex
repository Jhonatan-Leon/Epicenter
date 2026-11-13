defmodule Epicenter.Historial do
  @moduledoc """
    Son los movimientos del inventario
  """
  @tipos [:entrada, :salida, :asignacion, :transferencia, :rechazo]

  @enforce_keys [:id, :tipo, :codigo_recurso, :cantidad]
  defstruct [:id, :tipo, :codigo_recurso, :cantidad, :detalle, :usuario, :fecha]

  def tipos, do: @tipos

  def nuevo(id, tipo, codigo_recurso, cantidad, detalle, usuario) when tipo in @tipos do
    {:ok,
     %__MODULE__{
       id: id,
       tipo: tipo,
       codigo_recurso: codigo_recurso,
       cantidad: cantidad,
       detalle: detalle,
       usuario: usuario,
       fecha: Utilidad.generar_fecha_actual()
     }}
  end

  def nuevo(_id, _tipo, _codigo_recurso, _cantidad, _detalle, _usuario),
    do: {:error, :tipo_movimiento_invalido}
end
