defmodule InterfazWeb.Respuesta do
  @moduledoc """
  Muestra en pantalla lo que respondió `Interfaz.Fuente.*`. Lo usan todas
  las LiveViews para que el comportamiento sea igual en cada gestión.
  """
  import Phoenix.LiveView, only: [put_flash: 3, clear_flash: 2]
  import Phoenix.Component, only: [assign: 3]

  @doc """
  Éxito: cierra el modal, borra un error anterior y muestra el mensaje.
  Error: deja el modal abierto para corregir y muestra el motivo.
  """
  def mostrar(socket, {:ok, mensaje}) do
    socket
    |> assign(:modal, nil)
    |> clear_flash(:error)
    |> put_flash(:info, mensaje)
  end

  def mostrar(socket, {:error, mensaje}), do: put_flash(socket, :error, to_string(mensaje))
end
