defmodule Epicenter.Invetnario do
  @moduledoc """
  """
  @enforce_keys [:id, :codigo_recurso, :codigo_centro]
  defstruct [:id, :zonas, :codigo_recurso, :codigo_centro, cantidad_disponible: 0 ]
end
