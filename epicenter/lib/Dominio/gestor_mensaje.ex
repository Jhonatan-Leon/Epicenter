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

  defp buscar_mensaje(mensajes, codigo) do
    case Enum.find(mensajes, &(&1.codigo == codigo)) do
      nil -> {:error, "Mensaje no encontrado"}
      mensaje -> {:ok, mensaje}
    end
  end
end
