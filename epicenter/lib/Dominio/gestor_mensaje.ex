defmodule Epicenter.GestorMensaje do
  def listar, do: Epicenter.Persistencia.cargar_mensajes()

  def registro(remitente, destinatario, contenido) do
    with {:ok, mensaje} <- Epicenter.Mensaje.nuevo(remitente, destinatario, contenido),
         {:ok, mensaje} <- crear(mensaje) do
      {:ok, mensaje}
    end
  end

  def registro(codigo, remitente, destinatario, contenido, fecha_envio) do
    with {:ok, mensaje} <-
           Epicenter.Mensaje.nuevo(codigo, remitente, destinatario, contenido, fecha_envio),
         {:ok, mensaje} <- crear(mensaje) do
      {:ok, mensaje}
    end
  end

  def completar_informacion(codigo, estado) do
    with {:ok, mensajes} <- listar(),
         {:ok, mensaje} <- buscar_mensaje(mensajes, codigo),
         {:ok, mensaje_actualizado} <- Epicenter.Mensaje.completar_mensaje(mensaje, estado) do
      mensajes_actualizados =
        Enum.map(mensajes, fn existente ->
          if existente.codigo == codigo, do: mensaje_actualizado, else: existente
        end)

      Epicenter.Persistencia.guardar_mensajes(mensajes_actualizados)
      {:ok, mensaje_actualizado}
    end
  end

  def obtener(codigo) do
    with {:ok, mensajes} <- listar() do
      case Enum.find(mensajes, &(&1.codigo == codigo)) do
        nil -> {:error, "Mensaje no encontrado"}
        mensaje -> {:ok, mensaje}
      end
    end
  end

  def crear(%Epicenter.Mensaje{} = mensaje) do
    with {:ok, mensajes} <- listar() do
      if Enum.any?(mensajes, &(&1.codigo == mensaje.codigo)) do
        {:error, "El mensaje ya existe"}
      else
        Epicenter.Persistencia.guardar_mensajes([mensaje | mensajes])
        {:ok, mensaje}
      end
    end
  end

  def crear(_), do: {:error, "El mensaje no es válido"}

  def actualizar(codigo, %Epicenter.Mensaje{codigo: codigo} = mensaje) do
    with {:ok, mensajes} <- listar() do
      if Enum.any?(mensajes, &(&1.codigo == codigo)) do
        Epicenter.Persistencia.guardar_mensajes(
          Enum.map(mensajes, fn existente ->
            if existente.codigo == codigo, do: mensaje, else: existente
          end)
        )

        {:ok, mensaje}
      else
        {:error, "Mensaje no encontrado"}
      end
    end
  end

  def actualizar(_codigo, _mensaje), do: {:error, "El mensaje no es válido"}

  def eliminar(codigo) do
    with {:ok, mensajes} <- listar() do
      case Enum.find(mensajes, &(&1.codigo == codigo)) do
        nil ->
          {:error, "Mensaje no encontrado"}

        mensaje ->
          Epicenter.Persistencia.guardar_mensajes(Enum.reject(mensajes, &(&1.codigo == codigo)))
          {:ok, mensaje}
      end
    end
  end

  # ===== Comunicación entre familiares: enviar, consultar y marcar mensajes =====

  @doc """
  Envía un mensaje dirigido a una persona (comando `send_family_message`).

  El destinatario es el documento de una persona ya reportada. El mensaje queda
  `:pendiente` y con la fecha actual. Devuelve `{:ok, mensaje}` o
  `{:error, motivo}`: `:remitente_vacio`, `:destinatario_vacio`,
  `:contenido_vacio` o `"Persona no encontrada"`.
  """
  def enviar(remitente, documento_destinatario, contenido) do
    with {:ok, remitente} <- texto_obligatorio(remitente, :remitente_vacio),
         {:ok, documento} <- texto_obligatorio(documento_destinatario, :destinatario_vacio),
         {:ok, contenido} <- texto_obligatorio(contenido, :contenido_vacio),
         {:ok, _persona} <- Epicenter.GestorPersona.obtener_por_documento(documento) do
      registro(remitente, documento, contenido)
    end
  end

  @doc """
  Mensajes dirigidos a una persona (comando `list_family_messages`), del más
  reciente al más antiguo.
  """
  def listar_por_persona(documento) do
    with {:ok, documento} <- texto_obligatorio(documento, :destinatario_vacio),
         {:ok, mensajes} <- listar() do
      {:ok, Enum.filter(mensajes, &(&1.destinatario == documento))}
    end
  end

  @doc """
  Marca un mensaje como `:entregado` o `:pendiente` (átomo o texto).

  Devuelve `{:ok, mensaje}` o `{:error, motivo}`: `:estado_invalido` o
  `"Mensaje no encontrado"`.
  """
  def marcar(codigo, estado) do
    with {:ok, estado} <- validar_estado(estado),
         {:ok, mensajes} <- listar(),
         {:ok, mensaje} <- buscar_mensaje(mensajes, codigo) do
      actualizado = %{mensaje | estado: estado}

      Epicenter.Persistencia.guardar_mensajes(
        Enum.map(mensajes, fn existente ->
          if existente.codigo == codigo, do: actualizado, else: existente
        end)
      )

      {:ok, actualizado}
    end
  end

  defp texto_obligatorio(valor, motivo) when is_binary(valor) do
    case String.trim(valor) do
      "" -> {:error, motivo}
      texto -> {:ok, texto}
    end
  end

  defp texto_obligatorio(_valor, motivo), do: {:error, motivo}

  defp validar_estado(estado) when is_atom(estado) or is_binary(estado) do
    texto = estado |> to_string() |> String.trim()

    case Enum.find(Epicenter.Mensaje.estados(), &(Atom.to_string(&1) == texto)) do
      nil -> {:error, :estado_invalido}
      valido -> {:ok, valido}
    end
  end

  defp validar_estado(_estado), do: {:error, :estado_invalido}

  defp buscar_mensaje(mensajes, codigo) do
    case Enum.find(mensajes, &(&1.codigo == codigo)) do
      nil -> {:error, "Mensaje no encontrado"}
      mensaje -> {:ok, mensaje}
    end
  end
end
