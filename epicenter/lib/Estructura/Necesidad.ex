defmodule Epicenter.Necesidad do
  @moduledoc """
  """
  @enforce_keys [:id, :codigo_zona, :reportador_por]
  defstruct [
    :id,
    :codigo_zona,
    :reportador_por,
    :tipo,
    :descripicion,
    :cantidad,
    :prioridad,
    :estado,
    :destino
  ]

  def nuevo(codigo_zona, reportador_por) do
    {:ok,
     %__MODULE__{
       id: Utilidad.generar_codigo_unico(),
       codigo_zona: codigo_zona,
       reportador_por: reportador_por
     }}
  end
  # se necesita verificar las zonas antes de pasar el codigo de zona
  def nuevo(codigo_zona, reportador_por, tipo, descripicion, cantidad, prioridad, estado, destino) do
    with {:ok, codigo_zona} <- Utilidad.verificar_zona(codigo_zona),
         {:ok, necesidad} <- nuevo(codigo_zona, reportador_por) do
      completar_necesidad(necesidad, tipo, descripicion, cantidad, prioridad, estado, destino)
    end
  end

  def completar_necesidad(
        %__MODULE__{} = necesidad,
        tipo,
        descripicion,
        cantidad,
        prioridad,
        estado,
        destino
      ) do
    {:ok,
     %__MODULE__{
       necesidad
       | tipo: tipo,
         descripicion: descripicion,
         cantidad: cantidad,
         prioridad: prioridad,
         estado: estado,
         destino: destino
     }}
  end
end
