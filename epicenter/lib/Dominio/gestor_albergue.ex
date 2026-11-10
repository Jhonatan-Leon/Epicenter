defmodule Epicenter.GestorAlbergue do
  def listar, do: Epicenter.Persistencia.cargar_albergues()

  def registro(nombre, codigo_zona, capacidad) do
    with {:ok, albergue} <- Epicenter.Albergue.nuevo(nombre, codigo_zona, capacidad),
         {:ok, albergue} <- crear(albergue) do
      {:ok, albergue}
    end
  end

  def completar_informacion(codigo, ocupantes, recursos, necesidades) do
    with {:ok, albergues} <- listar(),
         {:ok, albergue} <- buscar_albergue(albergues, codigo),
         {:ok, albergue_actualizado} <-
           Epicenter.Albergue.completar_albergue(albergue, ocupantes, recursos, necesidades) do
      albergues_actualizados =
        Enum.map(albergues, fn existente ->
          if existente.codigo == codigo, do: albergue_actualizado, else: existente
        end)

      Epicenter.Persistencia.guardar_albergues(albergues_actualizados)
      {:ok, albergue_actualizado}
    end
  end

  def obtener(codigo) do
    with {:ok, albergues} <- listar() do
      case Enum.find(albergues, &(&1.codigo == codigo)) do
        nil -> {:error, "Albergue no encontrado"}
        albergue -> {:ok, albergue}
      end
    end
  end

  def crear(%Epicenter.Albergue{} = albergue) do
    with {:ok, albergues} <- listar() do
      if Enum.any?(albergues, &(&1.codigo == albergue.codigo)) do
        {:error, "El albergue ya existe"}
      else
        Epicenter.Persistencia.guardar_albergues([albergue | albergues])
        {:ok, albergue}
      end
    end
  end

  def crear(_), do: {:error, "El albergue no es válido"}

  def actualizar(codigo, %Epicenter.Albergue{codigo: codigo} = albergue) do
    with {:ok, albergues} <- listar() do
      if Enum.any?(albergues, &(&1.codigo == codigo)) do
        Epicenter.Persistencia.guardar_albergues(
          Enum.map(albergues, fn existente ->
            if existente.codigo == codigo, do: albergue, else: existente
          end)
        )

        {:ok, albergue}
      else
        {:error, "Albergue no encontrado"}
      end
    end
  end

  def actualizar(_codigo, _albergue), do: {:error, "El albergue no es válido"}

  def eliminar(codigo) do
    with {:ok, albergues} <- listar() do
      case Enum.find(albergues, &(&1.codigo == codigo)) do
        nil ->
          {:error, "Albergue no encontrado"}

        albergue ->
          Epicenter.Persistencia.guardar_albergues(Enum.reject(albergues, &(&1.codigo == codigo)))
          {:ok, albergue}
      end
    end
  end

  defp buscar_albergue(albergues, codigo) do
    case Enum.find(albergues, &(&1.codigo == codigo)) do
      nil -> {:error, "Albergue no encontrado"}
      albergue -> {:ok, albergue}
    end
  end
end
