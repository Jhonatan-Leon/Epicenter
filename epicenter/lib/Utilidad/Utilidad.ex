defmodule Utilidad do
  @moduledoc """
  """
  def generar_codigo_unico() do
    :crypto.strong_rand_bytes(8) |> Base.encode16()
  end

  def generar_fecha_actual() do
    DateTime.utc_now()
  end

  def verificar_cantidad(cantidad) when cantidad < 0 do
    {:error, "La cantidad no puede ser negativa"}
  end

  def verificar_cantidad(cantidad) when is_number(cantidad), do: :ok
  def verificar_cantidad(_cantidad), do: {:error, "La cantidad debe ser un número"}

  # def verificar_zona(codigo_zona) do
  #   zonas = Epicenter.Zona.listar_zonas(Epicenter.Zona)

  #   if codigo_zona in zonas do
  #     {:ok, codigo_zona}
  #   else
  #     {:error, "La zona no existe"}
  #   end
  # end
end
