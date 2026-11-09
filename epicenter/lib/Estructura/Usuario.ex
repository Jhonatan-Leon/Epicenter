defmodule Epicenter.Usuario do
  @moduledoc """

  """

  @rol_verificar [:ciudadano, :voluntario, :coordinar, :administrador]
  @enforces_keys [:nombre_usuario, :contraseña]
  defstruct [:nombre_usuario , :contraseña, :nombre_completo, :zona_principal, rol: [:ciudadano, :voluntario, :coordinar, :administrador]]

  def nuevo(nombre_usuario, password, rol) do
    {:Ok, %__MODULE__{nombre_usuario: nombre_usuario, contraseña: password, rol: verificar_rol(rol)}}
  end

  def verificacion_rol(%__MODULE__{rol: rol}, rol_verificar) do
    rol.in?(rol_verificar)
  end

end
