defmodule Epicenter.Usuario do
  @moduledoc """

  """

  @rol_verificar [:ciudadano, :voluntario, :coordinar, :administrador]
  @enforce_keys [:nombre_usuario, :contrasena]
  defstruct [
    :nombre_usuario,
    :contrasena,
    :nombre_completo,
    :zona_principal,
    rol: [:ciudadano, :voluntario, :coordinar, :administrador]
  ]

  def nuevo(nombre_usuario, password, rol \\ :ciudadano) do
    {:ok,
     %__MODULE__{nombre_usuario: nombre_usuario, contrasena: password, rol: verificar_rol(rol)}}
  end

  def verificar_rol(rol) do
    if rol in @rol_verificar do
    if rol in @rol_verificar do
      rol
    else
      :ciudadano
    end
  end

  def completar_usuario(%__MODULE__{} = usuario, nombre_completo, zona_principal) do
    {:ok, %__MODULE__{usuario | nombre_completo: nombre_completo, zona_principal: zona_principal}}
  end
  def completar_usuario(%__MODULE__{} = usuario, nombre_completo, zona_principal) do
    {:ok, %__MODULE__{usuario | nombre_completo: nombre_completo, zona_principal: zona_principal}}
  end
end
