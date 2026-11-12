defmodule Epicenter.Historial do
  @moduledoc """
  """
  @enforce_keys [:id, :id_invetario, :usuario, :id_necesidad, :codigo_destino]
  defstruct [
    :id,
    :id_invetario,
    :usuario,
    :id_necesidad,
    :codigo_destino,
    :tipo,
    cantidad: 0,
    fecha: nil
  ]

  def nuevo(id_invetario, usuario, id_necesidad, codigo_destino) do
    {:ok,
     %__MODULE__{
       id: Utilidad.generar_codigo_unico(),
       id_invetario: id_invetario,
       usuario: usuario,
       id_necesidad: id_necesidad,
       codigo_destino: codigo_destino
     }}
  end

  def nuevo(id_invetario, usuario, id_necesidad, codigo_destino, tipo, cantidad, _fecha) do
    with {:ok, historial} <- nuevo(id_invetario, usuario, id_necesidad, codigo_destino) do
      completar_historial(historial, tipo, cantidad, Utilidad.generar_fecha_actual())
    end
  end

  def completar_historial(%__MODULE__{} = historial, tipo, cantidad, fecha) do
    {:ok,
     %__MODULE__{
       historial
       | tipo: tipo,
         cantidad: cantidad,
         fecha: fecha
     }}
  end
end
