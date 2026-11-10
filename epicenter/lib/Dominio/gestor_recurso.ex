defmodule Recurso do
  @moduledoc """
    administración de recursos disponibles, cantidad disponible, ubicación y unidad de medida
    implementación de lógica pura

    ## funcionalidad
    - Registro de recursos
    - consulta de disponibilidad por recurso y zona
    - registro de entrada de inventario y salidas
    - Transferencia de recursos entre centros de apoyo

  """

  def registro_recurso(nombre, categoria, cantidad, unidad) do
    case Epicenter.Recurso.nuevo(nombre, categoria, cantidad, unidad) do
      {:ok, recurso} ->
        crear(recurso)

      {:error, _razon} ->
        {:error, "Recurso no registrado"}
    end
  end

  def registro_recurso(nombre, categoria) do
    with {:ok, recurso} <- Epicenter.Recurso.nuevo(nombre, categoria),
         {:ok, recurso} <- crear(recurso) do
      {:ok, recurso}
    end
  end

  def completar_informacion(codigo, cantidad, unidad) do
    with {:ok, recursos} <- listar(),
         {:ok, recurso} <- buscar_recurso(recursos, codigo),
         {:ok, recurso_actualizado} <-
           Epicenter.Recurso.completar_recurso(recurso, cantidad, unidad) do
      recursos_actualizados =
        Enum.map(recursos, fn existente ->
          if existente.codigo == codigo, do: recurso_actualizado, else: existente
        end)

      Epicenter.Persistencia.guardar_recursos(recursos_actualizados)
      {:ok, recurso_actualizado}
    end
  end

  def consultar_disponibilidad(codigo_zona, codigo_recurso, codigos_zona, inventarios)
      when is_list(codigos_zona) and is_list(inventarios) do
    if codigo_zona in codigos_zona do
      cantidad =
        inventarios
        |> Enum.filter(fn
          %Epicenter.Invetnario{} = inventario ->
            inventario.codigo_recurso == codigo_recurso and
              codigo_zona in List.wrap(inventario.zonas)

          _ ->
            false
        end)
        |> Enum.reduce(0, fn inventario, total ->
          total + inventario.cantidad_disponible
        end)

      {:ok, cantidad}
    else
      {:error, "La zona no existe"}
    end
  end

  def consultar_disponibilidad(_codigo_zona, _codigo_recurso, _codigos_zona, _inventarios),
    do: {:error, "Las listas de zonas o inventarios no son válidas"}

  def listar, do: Epicenter.Persistencia.cargar_recurso()

  def obtener(codigo) do
    with {:ok, recursos} <- listar() do
      case Enum.find(recursos, &(&1.codigo == codigo)) do
        nil -> {:error, "Recurso no encontrado"}
        recurso -> {:ok, recurso}
      end
    end
  end

  def crear(%Epicenter.Recurso{} = recurso) do
    with {:ok, recursos} <- listar() do
      if Enum.any?(recursos, &(&1.codigo == recurso.codigo)) do
        {:error, "El recurso ya existe"}
      else
        Epicenter.Persistencia.guardar_recursos([recurso | recursos])
        {:ok, recurso}
      end
    end
  end

  def crear(_), do: {:error, "El recurso no es válido"}

  def actualizar(codigo, %Epicenter.Recurso{codigo: codigo} = recurso) do
    with {:ok, recursos} <- listar() do
      if Enum.any?(recursos, &(&1.codigo == codigo)) do
        Epicenter.Persistencia.guardar_recursos(
          Enum.map(recursos, fn existente ->
            if existente.codigo == codigo, do: recurso, else: existente
          end)
        )

        {:ok, recurso}
      else
        {:error, "Recurso no encontrado"}
      end
    end
  end

  def actualizar(_codigo, _recurso), do: {:error, "El recurso no es válido"}

  def eliminar(codigo) do
    with {:ok, recursos} <- listar() do
      case Enum.find(recursos, &(&1.codigo == codigo)) do
        nil ->
          {:error, "Recurso no encontrado"}

        recurso ->
          Epicenter.Persistencia.guardar_recursos(Enum.reject(recursos, &(&1.codigo == codigo)))
          {:ok, recurso}
      end
    end
  end

  defp buscar_recurso(recursos, codigo) do
    case Enum.find(recursos, &(&1.codigo == codigo)) do
      nil -> {:error, "Recurso no encontrado"}
      recurso -> {:ok, recurso}
    end
  end
end

defmodule Epicenter.GestorRecurso do
  defdelegate listar(), to: Recurso
  defdelegate obtener(codigo), to: Recurso
  defdelegate registro_recurso(nombre, categoria, cantidad, unidad), to: Recurso
  defdelegate registro_recurso(nombre, categoria), to: Recurso
  defdelegate completar_informacion(codigo, cantidad, unidad), to: Recurso
  defdelegate crear(recurso), to: Recurso
  defdelegate actualizar(codigo, recurso), to: Recurso
  defdelegate eliminar(codigo), to: Recurso

  defdelegate consultar_disponibilidad(codigo_zona, codigo_recurso, codigos_zona, inventarios),
    to: Recurso
end
