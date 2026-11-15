defmodule Epicenter.GestorActividad do
  @moduledoc "Escribe y lee el registro de actividad (Actividad.log)"

  alias Epicenter.{Actividad, Persistencia}

  defp ruta, do: Persistencia.ruta_datos("Actividad.log")

  # Agrega una línea al final del archivo (no reescribe lo anterior)
  def registrar(usuario, accion, resultado, detalle \\ "") do
    actividad = %Actividad{
      fecha: DateTime.utc_now(),
      usuario: to_string(usuario),
      accion: to_string(accion),
      resultado: to_string(resultado),
      detalle: una_sola_linea(detalle)
    }

    File.write(ruta(), Actividad.a_linea(actividad) <> "\n", [:append])
    {:ok, actividad}
  end

  # Todas las actividades, de la más reciente a la más antigua
  def listar do
    case File.read(ruta()) do
      {:ok, contenido} ->
        lineas = String.split(contenido, "\n", trim: true)
        {:ok, leer_lineas(lineas, [])}

      # Si el archivo todavía no existe, no hay actividad
      {:error, :enoent} ->
        {:ok, []}

      {:error, motivo} ->
        {:error, motivo}
    end
  end

  # Recursiva: convierte cada línea y descarta las dañadas.
  # Como va agregando al inicio, la lista queda de la más reciente a la más antigua.
  defp leer_lineas([], actividades), do: actividades

  defp leer_lineas([linea | resto], actividades) do
    case Actividad.desde_linea(linea) do
      {:ok, actividad} -> leer_lineas(resto, [actividad | actividades])
      {:error, _motivo} -> leer_lineas(resto, actividades)
    end
  end

  def de_usuario(usuario) do
    with {:ok, actividades} <- listar() do
      {:ok, Enum.filter(actividades, fn actividad -> actividad.usuario == usuario end)}
    end
  end

  # Un usuario está conectado si su último connect/disconnect fue un connect.
  # Los intentos fallidos (contraseña equivocada) no cuentan.
  def conectados do
    with {:ok, actividades} <- listar() do
      conectados =
        actividades
        |> Enum.filter(fn actividad ->
          actividad.accion in ["connect", "disconnect"] and actividad.resultado == "ok"
        end)
        |> Enum.uniq_by(fn actividad -> actividad.usuario end)
        |> Enum.filter(fn actividad -> actividad.accion == "connect" end)
        |> Enum.map(fn actividad -> actividad.usuario end)

      {:ok, conectados}
    end
  end

  # Un salto de línea en el detalle partiría el registro en dos
  defp una_sola_linea(texto), do: texto |> to_string() |> String.replace(["\r", "\n"], " ")
end
