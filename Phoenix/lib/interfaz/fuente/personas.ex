defmodule Interfaz.Fuente.Personas do
  @moduledoc "Personas reportadas y su historial de estados, por `Epicenter.GenserverPersona`."

  import Interfaz.Fuente.Comun

  alias Epicenter.GenserverPersona

  @doc "Todas las personas reportadas."
  def personas, do: buscar(%{})

  @doc "Comando `find_person`: por texto (nombre o documento), zona y estado."
  def buscar(filtros) do
    %{
      texto: Map.get(filtros, "texto", ""),
      zona: Map.get(filtros, "zona", ""),
      estado: Map.get(filtros, "estado", "")
    }
    |> GenserverPersona.buscar()
    |> lista(&a_mapa/1)
  end

  @doc "Comando `report_person`."
  def reportar(documento, nombre, edad, zona, estado, usuario) do
    con_permiso(usuario, :registrar_persona, zona, fn actor ->
      documento
      |> GenserverPersona.reportar_persona(nombre, edad, zona, estado, actor.nombre_usuario)
      |> responder(&"Persona #{&1.nombre} reportada.")
    end)
  end

  @doc "Comando `update_person`: el cambio queda en el historial."
  def cambiar_estado(documento, estado, usuario) do
    case GenserverPersona.obtener_por_documento(documento) do
      {:ok, persona} ->
        con_permiso(usuario, :actualizar_persona, persona.codigo_zona, fn actor ->
          documento
          |> GenserverPersona.cambiar_estado(estado, actor.nombre_usuario)
          |> responder(&"Estado de #{&1.nombre} actualizado.")
        end)

      {:error, motivo} ->
        {:error, traducir(motivo)}
    end
  end

  defp a_mapa(persona) do
    %{
      id: persona.id,
      documento: persona.documento,
      nombre: persona.nombre,
      edad: persona.edad,
      zona: persona.codigo_zona,
      estado: persona.estado,
      albergue: persona.codigo_albergue,
      historial:
        Enum.map(persona.historial || [], fn cambio ->
          %{fecha: fecha_corta(cambio.fecha), estado: cambio.estado, por: cambio.por}
        end)
    }
  end
end
