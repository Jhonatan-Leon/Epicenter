defmodule Epicenter.GestorNecesidad do

  @orden_prioridad %{critica: 1, alta: 2, media: 3, baja: 4}

  def listar, do: Epicenter.Persistencia.cargar_necesidades()

   # Comando register_need, Los datos pueden llegar como texto ("agua", "30")
  def registrar(codigo_zona, reportado_por, tipo, descripcion, cantidad, prioridad, destino \\ nil) do
    with :ok <- verificar_zona(codigo_zona),
         {:ok, tipo} <- convertir_a_atomo(tipo, Epicenter.Necesidad.tipos(), :tipo_invalido),
         {:ok, prioridad} <- convertir_a_atomo(prioridad, Epicenter.Necesidad.prioridades(), :prioridad_invalida),
         {:ok, cantidad} <- convertir_a_entero(cantidad),
         {:ok, necesidades} <- listar(),
         id = generar_id(necesidades),
         {:ok, necesidad} <-
           Epicenter.Necesidad.nuevo(id, codigo_zona, reportado_por, tipo, descripcion, cantidad, prioridad, destino) do
      Epicenter.Persistencia.guardar_necesidades([necesidad | necesidades])
      {:ok, necesidad}
    end
  end

  # Comando list_needs con filtros opcionales: zona, tipo, prioridad y estado
  def consultar(filtros \\ %{}) do
    with {:ok, necesidades} <- listar() do
      encontradas = Enum.filter(necesidades, fn necesidad -> cumple_filtros?(necesidad, filtros) end)
      {:ok, ordenar_por_prioridad(encontradas)}
    end
  end

  # Comando pending_needs las que siguen abiertas, con orden de prioridad
  def pendientes do
    with {:ok, necesidades} <- listar() do
      abiertas = Enum.reject(necesidades, fn necesidad -> Epicenter.Necesidad.cerrada?(necesidad) end)
      {:ok, ordenar_por_prioridad(abiertas)}
    end
  end

  # Cambia el estado de una necesidad (pendiente, asignada, en_atencion, atendida, cancelada).
  def cambiar_estado(id, nuevo_estado) do
    with {:ok, nuevo_estado} <- convertir_a_atomo(nuevo_estado, Epicenter.Necesidad.estados(), :estado_invalido),
         {:ok, necesidades} <- listar(),
         {:ok, necesidad} <- buscar_necesidad(necesidades, id),
         {:ok, necesidad} <- Epicenter.Necesidad.cambiar_estado(necesidad, nuevo_estado) do
      guardar_cambio(necesidades, necesidad)
    end
  end

  # Comando assign_resource, Por ahora solo anota la asignación en la necesidad
  # Cuando exista la gestion de recursos, aqui se descuenta tambien el inventario
  def asignar_recurso(id, codigo_recurso, cantidad) do
    with {:ok, cantidad} <- convertir_a_entero(cantidad),
         {:ok, necesidades} <- listar(),
         {:ok, necesidad} <- buscar_necesidad(necesidades, id),
         {:ok, necesidad} <- Epicenter.Necesidad.asignar_recurso(necesidad, codigo_recurso, cantidad) do
      guardar_cambio(necesidades, necesidad)
    end
  end

  # Ordenar por prioridad (recursiva: ordenamiento por insercion)

  def ordenar_por_prioridad([]), do: []

  def ordenar_por_prioridad([necesidad | resto]) do
    resto_ordenado = ordenar_por_prioridad(resto)
    insertar_en_orden(necesidad, resto_ordenado)
  end

  # Pone una necesidad en su lugar dentro de una lista que ya esta ordenada
  defp insertar_en_orden(necesidad, []), do: [necesidad]

  defp insertar_en_orden(necesidad, [primera | resto]) do
    if mas_urgente_o_igual?(necesidad, primera) do
      [necesidad, primera | resto]
    else
      [primera | insertar_en_orden(necesidad, resto)]
    end
  end

  defp mas_urgente_o_igual?(necesidad, otra) do
    Map.get(@orden_prioridad, necesidad.prioridad) <= Map.get(@orden_prioridad, otra.prioridad)
  end

  #  Funciones de apoyo

  defp cumple_filtros?(necesidad, filtros) do
    coincide?(Map.get(filtros, :zona), necesidad.codigo_zona) and
      coincide?(Map.get(filtros, :tipo), necesidad.tipo) and
      coincide?(Map.get(filtros, :prioridad), necesidad.prioridad) and
      coincide?(Map.get(filtros, :estado), necesidad.estado)
  end

  # Si el filtro viene vacío, cualquier valor sirve.
  defp coincide?(filtro, _valor) when filtro in [nil, ""], do: true
  defp coincide?(filtro, valor), do: to_string(filtro) == to_string(valor)

  # Convierte texto a atomo solo si está en la lista permitida (no crea atomos nuevos)
  defp convertir_a_atomo(valor, permitidos, error) do
    case Enum.find(permitidos, fn permitido -> to_string(permitido) == to_string(valor) end) do
      nil -> {:error, error}
      atomo -> {:ok, atomo}
    end
  end

  defp convertir_a_entero(valor) when is_integer(valor), do: {:ok, valor}

  defp convertir_a_entero(valor) do
    case Integer.parse(to_string(valor)) do
      {numero, ""} -> {:ok, numero}
      _otro -> {:error, :cantidad_invalida}
    end
  end

  defp verificar_zona(codigo_zona) do
    zonas = Epicenter.Persistencia.carga_zonas()

    if Map.has_key?(zonas, codigo_zona),
      do: :ok,
      else: {:error, :zona_no_existe}
  end

  # Reemplaza la necesidad cambiada dentro de la lista y guarda el archivo
  defp guardar_cambio(necesidades, necesidad_cambiada) do
    necesidades_actualizadas =
      Enum.map(necesidades, fn necesidad ->
        if necesidad.id == necesidad_cambiada.id, do: necesidad_cambiada, else: necesidad
      end)

    Epicenter.Persistencia.guardar_necesidades(necesidades_actualizadas)
    {:ok, necesidad_cambiada}
  end

  # Si el id ya existe, pide otro
  defp generar_id(necesidades) do
    id = Utilidad.generar_codigo_unico()

    if Enum.any?(necesidades, fn necesidad -> necesidad.id == id end),
      do: generar_id(necesidades),
      else: id
  end

  
  defp buscar_necesidad(necesidades, id) do
    case Enum.find(necesidades, fn necesidad -> necesidad.id == id end) do
      nil -> {:error, "Necesidad no encontrada"}
      necesidad -> {:ok, necesidad}
    end
  end
end
