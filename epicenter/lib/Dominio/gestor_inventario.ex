defmodule Epicenter.GestorInventario do
  def listar, do: Epicenter.Persistencia.cargar_inventarios()

  def registro(codigo_recurso, codigo_centro, zonas, cantidad_disponible) do
    with {:ok, inventario} <-
<<<<<<< HEAD
           Epicenter.Inventario.nuevo(
=======
           Epicenter.Invetnario.nuevo(
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
             codigo_recurso,
             codigo_centro,
             zonas,
             cantidad_disponible
           ),
         {:ok, inventario} <- crear(inventario) do
      {:ok, inventario}
    end
  end

  def registro(codigo_recurso, codigo_centro) do
<<<<<<< HEAD
    with {:ok, inventario} <- Epicenter.Inventario.nuevo(codigo_recurso, codigo_centro),
=======
    with {:ok, inventario} <- Epicenter.Invetnario.nuevo(codigo_recurso, codigo_centro),
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
         {:ok, inventario} <- crear(inventario) do
      {:ok, inventario}
    end
  end

  def completar_informacion(id, zonas, cantidad_disponible) do
    with {:ok, inventarios} <- listar(),
         {:ok, inventario} <- buscar_inventario(inventarios, id),
         {:ok, inventario_actualizado} <-
<<<<<<< HEAD
           Epicenter.Inventario.completar_inventario(inventario, zonas, cantidad_disponible) do
=======
           Epicenter.Invetnario.completar_inventario(inventario, zonas, cantidad_disponible) do
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
      inventarios_actualizados =
        Enum.map(inventarios, fn existente ->
          if existente.id == id, do: inventario_actualizado, else: existente
        end)

      Epicenter.Persistencia.guardar_inventarios(inventarios_actualizados)
      {:ok, inventario_actualizado}
    end
  end

  def obtener(id) do
    with {:ok, inventarios} <- listar() do
      case Enum.find(inventarios, &(&1.id == id)) do
        nil -> {:error, "Inventario no encontrado"}
        inventario -> {:ok, inventario}
      end
    end
  end

<<<<<<< HEAD
  def crear(%Epicenter.Inventario{} = inventario) do
=======
  def crear(%Epicenter.Invetnario{} = inventario) do
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
    with {:ok, inventarios} <- listar() do
      if Enum.any?(inventarios, &(&1.id == inventario.id)) do
        {:error, "El inventario ya existe"}
      else
        Epicenter.Persistencia.guardar_inventarios([inventario | inventarios])
        {:ok, inventario}
      end
    end
  end

  def crear(_), do: {:error, "El inventario no es válido"}

<<<<<<< HEAD
  def actualizar(id, %Epicenter.Inventario{id: id} = inventario) do
=======
  def actualizar(id, %Epicenter.Invetnario{id: id} = inventario) do
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
    with {:ok, inventarios} <- listar() do
      if Enum.any?(inventarios, &(&1.id == id)) do
        Epicenter.Persistencia.guardar_inventarios(
          Enum.map(inventarios, fn existente ->
            if existente.id == id, do: inventario, else: existente
          end)
        )

        {:ok, inventario}
      else
        {:error, "Inventario no encontrado"}
      end
    end
  end

  def actualizar(_id, _inventario), do: {:error, "El inventario no es válido"}

  def eliminar(id) do
    with {:ok, inventarios} <- listar() do
      case Enum.find(inventarios, &(&1.id == id)) do
        nil ->
          {:error, "Inventario no encontrado"}

        inventario ->
          Epicenter.Persistencia.guardar_inventarios(Enum.reject(inventarios, &(&1.id == id)))
          {:ok, inventario}
      end
    end
  end

  defp buscar_inventario(inventarios, id) do
    case Enum.find(inventarios, &(&1.id == id)) do
      nil -> {:error, "Inventario no encontrado"}
      inventario -> {:ok, inventario}
    end
  end
end
