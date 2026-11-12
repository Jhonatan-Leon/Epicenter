defmodule Epicenter.GestorCentroApoyo do
  def listar, do: Epicenter.Persistencia.cargar_centros_apoyo()

  def registro(nombre, tipo) do
    with {:ok, centro} <- Epicenter.CentroApoyo.nuevo(nombre, tipo),
         {:ok, centro} <- crear(centro) do
      {:ok, centro}
    end
  end

  def registro(nombre, tipo, codigo_zona) do
    with {:ok, centro} <- Epicenter.CentroApoyo.nuevo(nombre, tipo, codigo_zona),
         {:ok, centro} <- crear(centro) do
      {:ok, centro}
    end
  end

  def completar_informacion(codigo, codigo_zona) do
    with {:ok, centros} <- listar(),
         {:ok, centro} <- buscar_centro(centros, codigo),
         {:ok, centro_actualizado} <-
           Epicenter.CentroApoyo.completar_centro_apoyo(centro, codigo_zona) do
      centros_actualizados =
        Enum.map(centros, fn existente ->
          if existente.codigo == codigo, do: centro_actualizado, else: existente
        end)

      Epicenter.Persistencia.guardar_centros_apoyo(centros_actualizados)
      {:ok, centro_actualizado}
    end
  end

  def obtener(codigo) do
    with {:ok, centros} <- listar() do
      case Enum.find(centros, &(&1.codigo == codigo)) do
        nil -> {:error, "Centro de apoyo no encontrado"}
        centro -> {:ok, centro}
      end
    end
  end

  def crear(%Epicenter.CentroApoyo{} = centro) do
    with {:ok, centros} <- listar() do
      if Enum.any?(centros, &(&1.codigo == centro.codigo)) do
        {:error, "El centro de apoyo ya existe"}
      else
        Epicenter.Persistencia.guardar_centros_apoyo([centro | centros])
        {:ok, centro}
      end
    end
  end

  def crear(_), do: {:error, "El centro de apoyo no es válido"}

  def actualizar(codigo, %Epicenter.CentroApoyo{codigo: codigo} = centro) do
    with {:ok, centros} <- listar() do
      if Enum.any?(centros, &(&1.codigo == codigo)) do
        Epicenter.Persistencia.guardar_centros_apoyo(
          Enum.map(centros, fn existente ->
            if existente.codigo == codigo, do: centro, else: existente
          end)
        )

        {:ok, centro}
      else
        {:error, "Centro de apoyo no encontrado"}
      end
    end
  end

  def actualizar(_codigo, _centro), do: {:error, "El centro de apoyo no es válido"}

  def eliminar(codigo) do
    with {:ok, centros} <- listar() do
      case Enum.find(centros, &(&1.codigo == codigo)) do
        nil ->
          {:error, "Centro de apoyo no encontrado"}

        centro ->
          Epicenter.Persistencia.guardar_centros_apoyo(
            Enum.reject(centros, &(&1.codigo == codigo))
          )

          {:ok, centro}
      end
    end
  end

  defp buscar_centro(centros, codigo) do
    case Enum.find(centros, &(&1.codigo == codigo)) do
      nil -> {:error, "Centro de apoyo no encontrado"}
      centro -> {:ok, centro}
    end
  end
end
