defmodule Epicenter.GestorZona do
  def listar(zonas) when is_list(zonas), do: {:ok, zonas}
  def listar(_zonas), do: {:error, "Las zonas deben ser una lista"}

  def obtener(zonas, codigo) when is_list(zonas) do
    case Enum.find(zonas, &(&1.codigo == codigo)) do
      nil -> {:error, "Zona no encontrada"}
      zona -> {:ok, zona}
    end
  end

  def obtener(_zonas, _codigo), do: {:error, "Las zonas deben ser una lista"}

  def crear(zonas, %Epicenter.Zona{} = zona) when is_list(zonas) do
    if Enum.any?(zonas, &(&1.codigo == zona.codigo)) do
      {:error, "La zona ya existe"}
    else
      {:ok, zona, [zona | zonas]}
    end
  end

  def crear(_zonas, _zona), do: {:error, "La zona o la lista no son válidas"}

  def actualizar(zonas, codigo, %Epicenter.Zona{codigo: codigo} = zona) when is_list(zonas) do
    if Enum.any?(zonas, &(&1.codigo == codigo)) do
      {:ok,
       Enum.map(zonas, fn existente ->
         if existente.codigo == codigo, do: zona, else: existente
       end)}
    else
      {:error, "Zona no encontrada"}
    end
  end

  def actualizar(_zonas, _codigo, _zona), do: {:error, "La zona o la lista no son válidas"}

  def eliminar(zonas, codigo) when is_list(zonas) do
    case Enum.find(zonas, &(&1.codigo == codigo)) do
      nil -> {:error, "Zona no encontrada"}
      zona -> {:ok, zona, Enum.reject(zonas, &(&1.codigo == codigo))}
    end
  end

  def eliminar(_zonas, _codigo), do: {:error, "Las zonas deben ser una lista"}
end
