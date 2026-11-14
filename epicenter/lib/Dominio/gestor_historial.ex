defmodule Epicenter.GestorHistorial do
  def listar, do: Epicenter.Persistencia.cargar_historiales()

  # Guarda un movimiento nuevo al inicio de la lista.
  def registrar(tipo, codigo_recurso, cantidad, detalle, usuario) do
    with {:ok, movimientos} <- listar(),
         {:ok, movimiento} <-
           Epicenter.Historial.nuevo(
             generar_id(movimientos),
             tipo,
             codigo_recurso,
             cantidad,
             detalle,
             usuario
           ) do
      Epicenter.Persistencia.guardar_historiales([movimiento | movimientos])
      {:ok, movimiento}
    end
  end

  # Movimientos de un solo recurso.
  def de_recurso(codigo_recurso) do
    with {:ok, movimientos} <- listar() do
      {:ok,
       Enum.filter(movimientos, fn movimiento -> movimiento.codigo_recurso == codigo_recurso end)}
    end
  end

  defp generar_id(movimientos) do
    numero = Integer.to_string(length(movimientos) + 1)
    "MV" <> String.pad_leading(numero, 3, "0")
  end
end
