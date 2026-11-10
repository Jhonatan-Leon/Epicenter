defmodule Epicenter.GestorMascota do
  def listar, do: Epicenter.Persistencia.cargar_mascotas()

  def registro(datos) when is_map(datos) do
    registro(Utilidad.generar_codigo_unico(), datos)
  end

  def registro(_datos), do: {:error, "Los datos de la mascota deben ser un mapa"}

  def registro(id, datos) do
    with {:ok, mascota} <- Epicenter.Mascota.nuevo(id, datos),
         {:ok, mascota} <- crear(mascota) do
      {:ok, mascota}
    end
  end

  def obtener(id) do
    with {:ok, mascotas} <- listar() do
      case Enum.find(mascotas, &(&1.id == id)) do
        nil -> {:error, "Mascota no encontrada"}
        mascota -> {:ok, mascota}
      end
    end
  end

  def crear(%Epicenter.Mascota{} = mascota) do
    with {:ok, mascotas} <- listar() do
      if Enum.any?(mascotas, &(&1.id == mascota.id)) do
        {:error, "La mascota ya existe"}
      else
        Epicenter.Persistencia.guardar_mascotas([mascota | mascotas])
        {:ok, mascota}
      end
    end
  end

  def crear(_), do: {:error, "La mascota no es válida"}

  def actualizar(id, %Epicenter.Mascota{id: id} = mascota) do
    with {:ok, mascotas} <- listar() do
      if Enum.any?(mascotas, &(&1.id == id)) do
        Epicenter.Persistencia.guardar_mascotas(
          Enum.map(mascotas, fn existente ->
            if existente.id == id, do: mascota, else: existente
          end)
        )

        {:ok, mascota}
      else
        {:error, "Mascota no encontrada"}
      end
    end
  end

  def actualizar(_id, _mascota), do: {:error, "La mascota no es válida"}

  def cambiar_estado(id, nuevo_estado) do
    with {:ok, mascotas} <- listar(),
         {:ok, mascota} <- buscar_mascota(mascotas, id),
         {:ok, mascota_actualizada} <- Epicenter.Mascota.cambiar_estado(mascota, nuevo_estado) do
      guardar_actualizacion(mascotas, mascota_actualizada)
    end
  end

  def eliminar(id) do
    with {:ok, mascotas} <- listar() do
      case Enum.find(mascotas, &(&1.id == id)) do
        nil ->
          {:error, "Mascota no encontrada"}

        mascota ->
          Epicenter.Persistencia.guardar_mascotas(Enum.reject(mascotas, &(&1.id == id)))
          {:ok, mascota}
      end
    end
  end

  defp buscar_mascota(mascotas, id) do
    case Enum.find(mascotas, &(&1.id == id)) do
      nil -> {:error, "Mascota no encontrada"}
      mascota -> {:ok, mascota}
    end
  end

  defp guardar_actualizacion(mascotas, mascota_actualizada) do
    Epicenter.Persistencia.guardar_mascotas(
      Enum.map(mascotas, fn existente ->
        if existente.id == mascota_actualizada.id, do: mascota_actualizada, else: existente
      end)
    )

    {:ok, mascota_actualizada}
  end
end
