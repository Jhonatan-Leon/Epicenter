<<<<<<< HEAD
defmodule Epicenter.GestorRecurso do
=======
defmodule Recurso do
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
  @moduledoc """
    administración de recursos disponibles, cantidad disponible, ubicación y unidad de medida
    implementación de lógica pura

    ## funcionalidad
    - Registro de recursos
    - consulta de disponibilidad por recurso y zona
    - registro de entrada de inventario y salidas
    - Transferencia de recursos entre centros de apoyo

  """

<<<<<<< HEAD
  alias Epicenter.{Recurso, GestorHistorial, GestorNecesidad, Persistencia}

  def listar, do: Persistencia.cargar_recurso()

  def obtener(codigo) do
    with {:ok, recursos} <- listar(), do: buscar_recurso(recursos, codigo)
  end

  # datos: %{nombre, categoria, unidad_medida, cantidad, minimo, ubicacion, codigo_zona}
  def registrar(datos, usuario) do
    with {:ok, categoria} <- convertir_categoria(datos.categoria),
         {:ok, cantidad} <- convertir_a_entero(datos.cantidad),
         {:ok, minimo} <- convertir_a_entero(datos.minimo),
         {:ok, recursos} <- listar(),
         {:ok, recurso} <-
           Recurso.nuevo(
             %{
               datos
               | categoria: categoria,
                 cantidad: cantidad,
                 minimo: minimo
             }
             |> Map.put(:codigo, generar_codigo(recursos))
           ) do
      Persistencia.guardar_recursos([recurso | recursos])

      GestorHistorial.registrar(
        :entrada,
        recurso.codigo,
        cantidad,
        "Registro en #{recurso.ubicacion}",
        usuario
      )

      {:ok, recurso}
    end
  end

  def registrar_entrada(codigo, cantidad, usuario) do
    with {:ok, cantidad} <- convertir_a_entero(cantidad),
         {:ok, recursos} <- listar(),
         {:ok, recurso} <- buscar_recurso(recursos, codigo),
         {:ok, recurso} <- Recurso.agregar(recurso, cantidad) do
      Persistencia.guardar_recursos(reemplazar(recursos, recurso))
      GestorHistorial.registrar(:entrada, codigo, cantidad, "Entrada de inventario", usuario)
      {:ok, recurso}
    end
  end

  def registrar_salida(codigo, cantidad, motivo, usuario) do
    with {:ok, cantidad} <- convertir_a_entero(cantidad),
         {:ok, recursos} <- listar(),
         {:ok, recurso} <- buscar_recurso(recursos, codigo),
         {:ok, recurso} <- retirar_o_rechazar(recurso, cantidad, motivo, usuario) do
      Persistencia.guardar_recursos(reemplazar(recursos, recurso))
      GestorHistorial.registrar(:salida, codigo, cantidad, motivo, usuario)
      {:ok, recurso}
    end
  end

  # Descuenta el recurso y lo anota en la necesidad. Solo guarda si las dos cosas salen bien
  def asignar_a_necesidad(codigo, id_necesidad, cantidad, usuario) do
    with {:ok, cantidad} <- convertir_a_entero(cantidad),
         {:ok, recursos} <- listar(),
         {:ok, recurso} <- buscar_recurso(recursos, codigo),
         {:ok, recurso} <-
           retirar_o_rechazar(recurso, cantidad, "#{id_necesidad} pidió #{cantidad}", usuario),
         {:ok, _necesidad} <- GestorNecesidad.asignar_recurso(id_necesidad, codigo, cantidad) do
      Persistencia.guardar_recursos(reemplazar(recursos, recurso))

      GestorHistorial.registrar(
        :asignacion,
        codigo,
        cantidad,
        "Asignado a #{id_necesidad}",
        usuario
      )

      {:ok, recurso}
    end
  end

  # Pasa unidades de una ubicación a otra
  def transferir(codigo, cantidad, destino, usuario) do
    with {:ok, cantidad} <- convertir_a_entero(cantidad),
         {:ok, recursos} <- listar(),
         {:ok, origen} <- buscar_recurso(recursos, codigo),
         :ok <- verificar_destino(origen, destino),
         {:ok, origen} <-
           retirar_o_rechazar(origen, cantidad, "Transferencia a #{destino}", usuario) do
      recursos
      |> reemplazar(origen)
      |> llevar_a_destino(origen, cantidad, destino)
      |> Persistencia.guardar_recursos()

      GestorHistorial.registrar(
        :transferencia,
        codigo,
        cantidad,
        "#{origen.ubicacion} a #{destino}",
        usuario
      )

      {:ok, origen}
    end
  end

  def de_zona(codigo_zona) do
    with {:ok, recursos} <- listar() do
      {:ok, Enum.filter(recursos, fn recurso -> recurso.codigo_zona == codigo_zona end)}
    end
  end

  def criticos do
    with {:ok, recursos} <- listar() do
      {:ok, Enum.filter(recursos, fn recurso -> Recurso.critico?(recurso) end)}
    end
  end

  # Si no alcanza, deja el rechazo en el historial y devuelve el error
  defp retirar_o_rechazar(recurso, cantidad, detalle, usuario) do
    case Recurso.retirar(recurso, cantidad) do
      {:error, :sin_existencias} ->
        detalle_rechazo = "#{detalle}; quedaban #{recurso.cantidad_disponible}"
        GestorHistorial.registrar(:rechazo, recurso.codigo, cantidad, detalle_rechazo, usuario)
        {:error, :sin_existencias}

      resultado ->
        resultado
    end
  end

  # Si el destino ya tiene ese recurso se le suma, si no, se crea alla
  defp llevar_a_destino(recursos, origen, cantidad, destino) do
    existente =
      Enum.find(recursos, fn recurso ->
        recurso.nombre == origen.nombre and recurso.ubicacion == destino
      end)

    case existente do
      nil ->
        {:ok, nuevo} =
          Recurso.nuevo(%{
            codigo: generar_codigo(recursos),
            nombre: origen.nombre,
            categoria: origen.categoria,
            unidad_medida: origen.unidad_medida,
            cantidad: cantidad,
            minimo: origen.minimo,
            ubicacion: destino,
            codigo_zona: origen.codigo_zona
          })

        [nuevo | recursos]

      recurso_destino ->
        {:ok, recurso_destino} = Recurso.agregar(recurso_destino, cantidad)
        reemplazar(recursos, recurso_destino)
    end
  end

  defp verificar_destino(%Recurso{ubicacion: destino}, destino), do: {:error, :mismo_destino}
  defp verificar_destino(_origen, _destino), do: :ok

  defp buscar_recurso(recursos, codigo) do
    case Enum.find(recursos, fn recurso -> recurso.codigo == codigo end) do
      nil -> {:error, :recurso_no_encontrado}
      recurso -> {:ok, recurso}
    end
  end

  defp reemplazar(recursos, recurso_cambiado) do
    Enum.map(recursos, fn recurso ->
      if recurso.codigo == recurso_cambiado.codigo, do: recurso_cambiado, else: recurso
    end)
  end

  defp generar_codigo(recursos) do
    numero = Integer.to_string(length(recursos) + 1)
    "R" <> String.pad_leading(numero, 3, "0")
  end

  defp convertir_categoria(categoria) do
    case Enum.find(Recurso.categorias(), fn permitida ->
           to_string(permitida) == to_string(categoria)
         end) do
      nil -> {:error, :categoria_invalida}
      permitida -> {:ok, permitida}
    end
  end

  defp convertir_a_entero(valor) when is_integer(valor), do: {:ok, valor}

  defp convertir_a_entero(valor) do
    case Integer.parse(to_string(valor)) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :cantidad_invalida}
    end
  end
=======
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
>>>>>>> 0cd590291dc76d769310dda61e654940ee4b42d8
end
