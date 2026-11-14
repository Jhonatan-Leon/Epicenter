defmodule Interfaz.Fuente.Mensajes do
  @moduledoc "Mensajes familiares, por `Epicenter.GenserverMensaje`."

  import Interfaz.Fuente.Comun

  alias Epicenter.GenserverMensaje

  @doc "Todos los mensajes (para el resumen)."
  def mensajes, do: GenserverMensaje.listar() |> lista(&a_mapa/1)

  @doc "Comando `list_family_messages`: los de una persona, del más reciente al más antiguo."
  def de_persona(documento) do
    case GenserverMensaje.listar_por_persona(documento) do
      {:ok, mensajes} ->
        mensajes
        |> Enum.sort_by(& &1.fecha_envio, {:desc, DateTime})
        |> Enum.map(&a_mapa/1)

      {:error, _motivo} ->
        []
    end
  end

  @doc "Comando `send_family_message`. El remitente es el usuario conectado."
  def enviar(usuario, documento, contenido) do
    con_permiso(usuario, :enviar_mensaje, nil, fn actor ->
      (actor.nombre_completo || actor.nombre_usuario)
      |> GenserverMensaje.enviar(documento, contenido)
      |> responder(fn _mensaje -> "Mensaje enviado." end)
    end)
  end

  @doc "Comando `mark_message`: `:entregado` o `:pendiente`."
  def marcar(codigo, estado, usuario) do
    con_permiso(usuario, :marcar_mensaje, nil, fn _actor ->
      codigo
      |> GenserverMensaje.marcar(estado)
      |> responder(&"Mensaje marcado como #{InterfazWeb.Formato.t(&1.estado)}.")
    end)
  end

  defp a_mapa(mensaje) do
    %{
      id: mensaje.codigo,
      fecha: fecha_corta(mensaje.fecha_envio),
      remitente: mensaje.remitente,
      destinatario: mensaje.destinatario,
      contenido: mensaje.contenido,
      estado: mensaje.estado
    }
  end
end
