defmodule Epicenter.GestorAlbergue do
  def listar, do: Epicenter.Persistencia.cargar_albergues()

  def registro(nombre, codigo_zona, capacidad) do
<<<<<<< HEAD
    with :ok <- zona_existe(codigo_zona),
         {:ok, albergues} <- listar(),
         {:ok, albergue} <-
           Epicenter.Albergue.nuevo(generar_codigo(albergues), nombre, codigo_zona, capacidad) do
      Epicenter.Persistencia.guardar_albergues([albergue | albergues])
=======
    with {:ok, albergue} <- Epicenter.Albergue.nuevo(nombre, codigo_zona, capacidad),
         {:ok, albergue} <- crear(albergue) do
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
      {:ok, albergue}
    end
  end

<<<<<<< HEAD
  # Registrar el ingreso de las personas al albergue
  def registrar_ingreso(codigo, documento, por \\ "sistema") do
    with {:ok, albergues} <- listar(),
         {:ok, albergue} <- buscar_albergue(albergues, codigo),
         {:ok, _persona} <- Epicenter.GestorPersona.obtener_por_documento(documento),
         {:ok, albergue} <- Epicenter.Albergue.registrar_ingreso(albergue, documento) do
      guardar_cambio(albergues, albergue)
      Epicenter.GestorPersona.cambiar_estado(documento, :en_albergue, por)
      {:ok, albergue}
    end
  end

  # la salida
  def registrar_salida(codigo, documento) do
    with {:ok, albergues} <- listar(),
         {:ok, albergue} <- buscar_albergue(albergues, codigo),
         {:ok, albergue} <- Epicenter.Albergue.registrar_salida(albergue, documento) do
      guardar_cambio(albergues, albergue)
      {:ok, albergue}
    end
  end

  def cupos(codigo) do
    with {:ok, albergue} <- obtener(codigo), do: {:ok, Epicenter.Albergue.cupos(albergue)}
  end

=======
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
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
<<<<<<< HEAD

  def reporte_ocupacion do
    with {:ok, albergues} <- listar() do
      {:ok, Enum.sort_by(albergues, &Epicenter.Albergue.porcentaje/1, :desc)}
    end
  end

  # Recursiva
  def cupos_por_zona(albergues, zona), do: sumar_cupos(albergues, zona)
  defp sumar_cupos([], _zona), do: 0

  defp sumar_cupos([%{codigo_zona: zona} = a | resto], zona),
    do: Epicenter.Albergue.cupos(a) + sumar_cupos(resto, zona)

  defp sumar_cupos([_otro | resto], zona), do: sumar_cupos(resto, zona)

  defp zona_existe(codigo) do
    if Map.has_key?(Epicenter.Persistencia.carga_zonas(), codigo),
      do: :ok,
      else: {:error, :zona_no_existe}
  end

  defp guardar_cambio(albergues, albergue) do
    Epicenter.Persistencia.guardar_albergues(
      Enum.map(albergues, fn a -> if a.codigo == albergue.codigo, do: albergue, else: a end)
    )
  end

  defp generar_codigo(albergues) do
    codigo = Utilidad.generar_codigo_unico()
    if Enum.any?(albergues, &(&1.codigo == codigo)), do: generar_codigo(albergues), else: codigo
  end
=======
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
end
