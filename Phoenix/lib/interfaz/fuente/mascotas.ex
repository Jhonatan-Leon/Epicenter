defmodule Interfaz.Fuente.Mascotas do
  @moduledoc "Reportes de mascotas y coincidencias, por `Epicenter.GenserverMascota`."

  import Interfaz.Fuente.Comun

  alias Epicenter.GenserverMascota
  alias Interfaz.Fuente.Catalogos

  @doc "Todos los reportes."
  def mascotas, do: consultar(%{})

  @doc "Comando `list_pets`: por especie, zona y estado. Los vacíos se quitan aquí."
  def consultar(filtros) do
    filtros =
      for {clave, campo} <- [{"especie", :especie}, {"zona", :zona}, {"estado", :estado}],
          valor = Map.get(filtros, clave, ""),
          valor not in [nil, ""],
          do: {campo, valor}

    filtros |> GenserverMascota.consultar() |> lista(&a_mapa/1)
  end

  @doc "Comando `report_pet`."
  def reportar(datos_formulario, usuario) do
    datos = %{
      tipo: datos_formulario["reporte"],
      especie: datos_formulario["especie"],
      nombre: datos_formulario["nombre"],
      color: datos_formulario["color"],
      tamano: datos_formulario["tamano"],
      zona: datos_formulario["zona"],
      contacto: datos_formulario["contacto"],
      caracteristicas: datos_formulario["caracteristicas"]
    }

    con_permiso(usuario, :reportar_mascota, datos.zona, fn _actor ->
      datos
      |> GenserverMascota.registro()
      |> responder(&"Mascota #{InterfazWeb.Formato.t(&1.tipo)} reportada.")
    end)
  end

  @doc "Parejas candidatas (40 puntos o más), con los criterios que coincidieron."
  def coincidencias,
    do: GenserverMascota.coincidencias_posibles() |> lista(&coincidencia_a_mapa/1)

  @doc "Comando `match_pets`: marca como posible coincidencia las parejas de 70 o más."
  def buscar_coincidencias(usuario, codigo_zona) do
    con_permiso(usuario, :validar_coincidencias_mascotas, codigo_zona, fn _actor ->
      case GenserverMascota.marcar_coincidencias(codigo_zona) do
        {:ok, []} -> {:ok, "No hay parejas nuevas con 70 puntos o más para marcar."}
        {:ok, [_una]} -> {:ok, "Se marcó 1 posible coincidencia."}
        {:ok, parejas} -> {:ok, "Se marcaron #{length(parejas)} posibles coincidencias."}
        {:error, motivo} -> {:error, traducir(motivo)}
      end
    end)
  end

  @doc "Comando `confirm_match`: cierra ambos reportes. Deben ser de la zona autorizada."
  def confirmar_coincidencia(id_perdida, id_encontrada, usuario, codigo_zona) do
    with {:ok, mascotas} <- GenserverMascota.listar(),
         perdida when not is_nil(perdida) <- Enum.find(mascotas, &(&1.id == id_perdida)),
         encontrada when not is_nil(encontrada) <-
           Enum.find(mascotas, &(&1.id == id_encontrada)),
         true <- perdida.zona == codigo_zona and encontrada.zona == codigo_zona do
      con_permiso(usuario, :validar_coincidencias_mascotas, codigo_zona, fn _actor ->
        id_perdida
        |> GenserverMascota.confirmar_coincidencia(id_encontrada)
        |> responder(fn _par -> "Coincidencia confirmada. Ambos reportes quedaron resueltos." end)
      end)
    else
      false -> {:error, "Las mascotas deben pertenecer a la zona autorizada."}
      nil -> {:error, "Mascota no encontrada."}
      {:error, motivo} -> {:error, traducir(motivo)}
    end
  end

  defp a_mapa(mascota) do
    %{
      id: mascota.id,
      reporte: mascota.tipo,
      especie: especie(mascota.especie),
      nombre: mascota.nombre,
      color: mascota.color,
      tamano: mascota.tamano,
      zona: mascota.zona,
      contacto: mascota.contacto,
      caracteristicas: mascota.caracteristicas,
      estado: mascota.estado,
      coincidencia_con: mascota.coincidencia_con
    }
  end

  # La lógica guarda la especie como texto ("perro"); la interfaz usa el átomo si es conocido.
  defp especie(texto),
    do: Enum.find(Catalogos.especies(), texto, &(to_string(&1) == texto))

  defp coincidencia_a_mapa(coincidencia) do
    %{
      perdida: coincidencia.perdida,
      encontrada: coincidencia.encontrada,
      puntaje: coincidencia.puntaje,
      criterios:
        for criterio <- [:especie, :color, :tamano, :zona, :caracteristicas] do
          {criterio, Map.get(coincidencia.desglose, criterio, 0) > 0}
        end
    }
  end
end
