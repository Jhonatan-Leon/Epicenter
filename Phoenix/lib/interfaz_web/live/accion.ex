defmodule InterfazWeb.Accion do
  @moduledoc """
  Envía una acción de un formulario a `Interfaz.Fuente` y refleja el resultado
  en la pantalla (mensaje y cierre del modal).
  """
  import Phoenix.LiveView, only: [put_flash: 3]
  import Phoenix.Component, only: [assign: 3]

  def enviar(socket, accion, argumentos) do
    case Interfaz.Fuente.ejecutar(accion, argumentos) do
      {:ok, comando} ->
        socket
        |> put_flash(:info, "Solicitud enviada: #{comando}")
        |> assign(:modal, nil)

      {:error, motivo} ->
        put_flash(socket, :error, to_string(motivo))
    end
  end
end
