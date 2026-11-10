defmodule Epicenter.Persona do
  @moduledoc """
  """
  @enforce_keys [:id, :documento, :tipo_documento, :nombre, :codigo_zona, :codigo_albergue]
  defstruct [
    :id,
    :documento,
    :tipo_documento,
    :nombre,
    :edad,
    :codigo_zona,
    :estado,
    :codigo_albergue,
    :historial
  ]

  def nuevo(documento, tipo_documento, nombre, codigo_zona, codigo_albergue) do
    {:ok,
     %__MODULE__{
       id: Utilidad.generar_codigo_unico(),
       documento: documento,
       tipo_documento: tipo_documento,
       nombre: nombre,
       codigo_zona: codigo_zona,
       codigo_albergue: codigo_albergue
     }}
  end

  def nuevo(
        documento,
        tipo_documento,
        nombre,
        edad,
        codigo_zona,
        estado,
        codigo_albergue,
        historial
      ) do
    with {:ok, persona} <-
           nuevo(documento, tipo_documento, nombre, codigo_zona, codigo_albergue) do
      completar_persona(persona, edad, estado, historial)
    end
  end

  def completar_persona(%__MODULE__{} = persona, edad, estado, historial) do
    {:ok,
     %__MODULE__{
       persona
       | edad: edad,
         estado: estado,
         historial: historial
     }}
  end

  # defp verificar_zona(codigo_zona) do
  #   case Epicenter.Zona.nueva(codigo_zona) do
  #     {:ok, _zona} -> {:ok, codigo_zona}
  #     {:error, _} -> {:error, "Zona inválida"}
  #   end
  # end

  # defp verificar_albergue(codigo_albergue) do
  #   case Epicenter.CentroApoyo.nuevo(codigo_albergue) do
  #     {:ok, _albergue} -> {:ok, codigo_albergue}
  #     {:error, _} -> {:error, "Albergue inválido"}
  #   end
  # end
end
