defmodule Epicenter.Zona do
  @moduledoc """

  """
  @nivel_afectacion_verificar [:bajo, :medio, :alto, :critica]
  @enforces_keys [:nombre_zona]
  defstruct [ :codigo, :nombre_zona, :nivel_afectacion, persona_afectadas: 0, sectores: []]

  def nueva(nombre_zona) do
    {:osk, %__MODULE__{codigo: Utilidad.generar_codigo_unico(), nombre_zona: nombre_zona, nivel_afectacion: nivel_afectacion_valido?(:bajo), persona_afectadas: 0, sectores: []}}
  end

  def listar_zonas(zonas) do
    Enum.map(zonas, fn zona -> zona.codigo end)
  end

  def nivel_afectacion_valido?(nivel_afectacion) do
    Enum.member?(@nivel_afectacion_verificar, nivel_afectacion)
  end
end
