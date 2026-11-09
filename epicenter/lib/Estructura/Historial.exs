defmodule Epicenter.Historial do
  @moduledoc """
  """
  @enforce_keys [:id, :id_invetario, :usuario, :id_necesidad, :codigo_destino]
  defstruct [:id, :id_invetario, :usuario, :id_necesidad, :codigo_destino, :tipo, cantidad: 0, fecha: nil]

  def nuevo(id_invetario, usuario, id_necesidad, codigo_destino, tipo, cantidad, fecha) do
    {:Ok, %__MODULE__{id: Utilidad.generar_codigo_unico(), id_invetario: id_invetario, usuario: usuario, id_necesidad: id_necesidad, codigo_destino: codigo_destino, tipo: tipo, cantidad: cantidad, fecha: Utilidad.generar_fecha_actual()}}
  end
end
