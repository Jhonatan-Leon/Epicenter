defmodule Interfaz.Fuente.Recursos do
  @moduledoc """
  Inventario de recursos y su historial de movimientos, por
  `Epicenter.GenserverRecurso` y `Epicenter.GenserverHistorial`.
  Cada cambio de cantidad pasa por el GenServer, una operación a la vez.
  """

  import Interfaz.Fuente.Comun

  alias Epicenter.{GenserverHistorial, GenserverRecurso, Recurso}

  @doc "Recursos ordenados por código."
  def recursos do
    GenserverRecurso.listar() |> lista(&a_mapa/1) |> Enum.sort_by(& &1.codigo)
  end

  @doc "Comando `critical_resources`: los que están por debajo de su mínimo."
  def criticos, do: GenserverRecurso.criticos() |> lista(&a_mapa/1)

  @doc "Historial de movimientos, del más reciente al más antiguo."
  def movimientos, do: GenserverHistorial.listar() |> lista(&movimiento_a_mapa/1)

  @doc "Comando `register_resource`. El código (R001, R002…) lo genera la lógica."
  def registrar(datos, usuario) do
    with {:ok, nombre} <- texto(datos["nombre"], "Escribe el nombre del recurso."),
         {:ok, unidad} <- texto(datos["unidad"], "Escribe la unidad de medida."),
         {:ok, ubicacion} <- texto(datos["ubicacion"], "Escribe la ubicación."),
         {:ok, zona} <- texto(datos["zona"], "Elige una zona.") do
      con_permiso(usuario, :gestionar_recursos, zona, fn actor ->
        %{
          nombre: nombre,
          categoria: datos["categoria"],
          unidad_medida: unidad,
          cantidad: datos["cantidad"],
          minimo: datos["minimo"],
          ubicacion: ubicacion,
          codigo_zona: zona
        }
        |> GenserverRecurso.registrar(actor.nombre_usuario)
        |> responder(&"Recurso #{&1.codigo} · #{&1.nombre} registrado.")
      end)
    end
  end

  @doc "Entrada de inventario."
  def registrar_entrada(codigo, cantidad, usuario) do
    con_recurso(codigo, usuario, :gestionar_recursos, fn actor ->
      codigo
      |> GenserverRecurso.registrar_entrada(cantidad, actor.nombre_usuario)
      |> responder(&"Entrada registrada: #{&1.nombre} queda en #{cantidad_texto(&1)}.")
    end)
  end

  @doc "Salida de inventario. Si no alcanza, el rechazo queda en el historial."
  def registrar_salida(codigo, cantidad, motivo, usuario) do
    with {:ok, motivo} <- texto(motivo, "Escribe el motivo de la salida.") do
      con_recurso(codigo, usuario, :gestionar_recursos, fn actor ->
        codigo
        |> GenserverRecurso.registrar_salida(cantidad, motivo, actor.nombre_usuario)
        |> responder(&"Salida registrada: #{&1.nombre} queda en #{cantidad_texto(&1)}.")
      end)
    end
  end

  @doc "Comando `transfer_resource`: de la ubicación actual a `destino`, en `zona_destino`."
  def transferir(codigo, cantidad, destino, zona_destino, usuario) do
    with {:ok, destino} <- texto(destino, "Escribe el destino."),
         {:ok, zona_destino} <- texto(zona_destino, "Elige la zona del destino.") do
      con_recurso(codigo, usuario, :transferir_recursos, fn actor ->
        codigo
        |> GenserverRecurso.transferir(cantidad, destino, zona_destino, actor.nombre_usuario)
        |> responder(
          &"Transferencia hecha a #{destino}. En #{&1.ubicacion} quedan #{cantidad_texto(&1)}."
        )
      end)
    end
  end

  # El permiso se revisa contra la zona donde está el recurso.
  defp con_recurso(codigo, usuario, permiso, funcion) do
    case GenserverRecurso.obtener(codigo) do
      {:ok, recurso} -> con_permiso(usuario, permiso, recurso.codigo_zona, funcion)
      {:error, motivo} -> {:error, traducir(motivo)}
    end
  end

  defp cantidad_texto(%Recurso{} = recurso),
    do: "#{recurso.cantidad_disponible} #{recurso.unidad_medida}"

  defp a_mapa(%Recurso{} = recurso) do
    %{
      codigo: recurso.codigo,
      nombre: recurso.nombre,
      categoria: recurso.categoria,
      cantidad: recurso.cantidad_disponible,
      minimo: recurso.minimo,
      unidad: recurso.unidad_medida,
      ubicacion: recurso.ubicacion,
      zona: recurso.codigo_zona,
      critico: Recurso.critico?(recurso)
    }
  end

  defp movimiento_a_mapa(movimiento) do
    %{
      id: movimiento.id,
      fecha: fecha_corta(movimiento.fecha),
      tipo: movimiento.tipo,
      recurso: movimiento.codigo_recurso,
      cantidad: movimiento.cantidad,
      detalle: movimiento.detalle,
      usuario: movimiento.usuario
    }
  end
end
