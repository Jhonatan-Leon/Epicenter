defmodule Interfaz.Fuente.Comun do
  @moduledoc """
  Piezas que comparten todos los módulos de `Interfaz.Fuente.*`:
  limpiar lo que escribe el usuario, convertir números, dar formato a fechas
  y traducir los errores de la lógica a mensajes para la pantalla.
  """

  @doc "Quita espacios al inicio y al final; `nil` queda como texto vacío."
  def limpiar(texto), do: texto |> to_string() |> String.trim()

  @doc "Texto obligatorio: `{:ok, texto}` o `{:error, mensaje_si_vacio}`."
  def texto(valor, mensaje_si_vacio) do
    case limpiar(valor) do
      "" -> {:error, mensaje_si_vacio}
      texto -> {:ok, texto}
    end
  end

  @doc "Entero mayor o igual a `minimo`, escrito en un formulario."
  def entero(valor, minimo, mensaje_si_invalido) do
    case Integer.parse(limpiar(valor)) do
      {numero, ""} when numero >= minimo -> {:ok, numero}
      _otro -> {:error, mensaje_si_invalido}
    end
  end

  @doc """
  Busca `valor` (texto del formulario) dentro de los átomos permitidos.
  Así nunca se crea un átomo nuevo con lo que escribe el usuario.
  """
  def atomo(valor, permitidos, mensaje_si_invalido) do
    case Enum.find(permitidos, &(to_string(&1) == limpiar(valor))) do
      nil -> {:error, mensaje_si_invalido}
      atomo -> {:ok, atomo}
    end
  end

  @doc "Lista de la lógica pasada a mapas de pantalla; si la lógica falla, lista vacía."
  def lista({:ok, elementos}, a_mapa), do: Enum.map(elementos, a_mapa)
  def lista({:error, _motivo}, _a_mapa), do: []

  @doc """
  Respuesta para la pantalla: `{:ok, mensaje}` con el texto que arma
  `mensaje_ok` o `{:error, mensaje}` con el error traducido.
  """
  def responder({:ok, valor}, mensaje_ok), do: {:ok, mensaje_ok.(valor)}
  def responder({:error, motivo}, _mensaje_ok), do: {:error, traducir(motivo)}

  @doc """
  Ejecuta `funcion` solo si `Epicenter.Autorizacion` deja al `usuario` hacer
  `permiso` en `codigo_zona`. El rol se lee de la lógica, no de la pantalla.
  Si se niega, devuelve `{:error, mensaje}` ya traducido.
  """
  def con_permiso(usuario, permiso, codigo_zona, funcion) do
    case Epicenter.Autorizacion.ejecutar(usuario, permiso, codigo_zona, funcion) do
      {:error, motivo} when not is_binary(motivo) -> {:error, traducir(motivo)}
      resultado -> resultado
    end
  end

  @doc "Las fechas llegan en UTC; se muestran en hora de Colombia (UTC-5)."
  def fecha_corta(%DateTime{} = fecha),
    do: fecha |> DateTime.add(-5, :hour) |> Calendar.strftime("%d/%m %H:%M")

  def fecha_corta(nil), do: ""
  def fecha_corta(fecha), do: to_string(fecha)

  @errores %{
    # Permisos (Epicenter.Autorizacion)
    permiso_denegado: "Tu rol no permite esta acción.",
    usuario_no_autenticado: "Tu sesión no es válida. Vuelve a conectarte.",
    fuera_de_zona: "Solo puedes operar en tu zona asignada.",
    zona_requerida: "Elige una zona para esta acción.",
    zona_no_asignada: "Tu cuenta no tiene una zona asignada.",
    zona_no_encontrada: "La zona no existe.",
    # Zonas
    nombre_duplicado: "Ya existe una zona con ese nombre.",
    sector_duplicado: "Esa zona ya tiene un sector con ese nombre.",
    punto_duplicado: "Ese sector ya tiene un punto con ese nombre.",
    no_encontrada: "La zona no existe.",
    sector_no_encontrado: "El sector no existe.",
    nombre_vacio: "El nombre no puede estar vacío.",
    nivel_invalido: "Nivel de afectación no válido.",
    afectadas_invalidas: "Número de personas afectadas no válido.",
    zona_no_existe: "La zona no existe.",
    zona_vacia: "Elige una zona.",
    # Necesidades
    tipo_invalido: "Tipo no válido.",
    prioridad_invalida: "Prioridad no válida.",
    ya_cerrada: "La necesidad ya está atendida o cancelada.",
    supera_lo_requerido: "Esa cantidad supera lo que le falta a la necesidad.",
    necesidad_no_encontrada: "La necesidad no existe.",
    # Recursos
    categoria_invalida: "Elige una categoría válida.",
    cantidad_invalida: "La cantidad debe ser un número entero mayor que 0.",
    sin_existencias: "No hay suficientes unidades en inventario.",
    mismo_destino: "El destino debe ser distinto de la ubicación actual.",
    recurso_no_encontrado: "El recurso no existe.",
    categoria_incompatible: "Ese recurso no es de la misma categoría que la necesidad.",
    tipo_movimiento_invalido: "Tipo de movimiento no válido.",
    zona_destino_requerida: "Elige la zona del destino.",
    # Generales
    datos_invalidos: "Los datos no son válidos.",
    filtro_invalido: "Filtro no válido.",
    filtros_invalidos: "Filtros no válidos.",
    operacion_no_soportada: "Operación no disponible.",
    # Personas y mensajes
    documento_vacio: "Escribe el documento o una referencia.",
    documento_duplicado: "Ya hay una persona reportada con ese documento.",
    edad_invalida: "La edad debe estar entre 0 y 120.",
    estado_invalido: "Estado no válido.",
    transicion_invalida: "Ese cambio de estado no está permitido.",
    ya_reunificada: "La persona ya fue reunificada; su estado no cambia.",
    remitente_vacio: "Falta quién envía el mensaje.",
    destinatario_vacio: "Falta la persona a quien va el mensaje.",
    contenido_vacio: "Escribe el mensaje.",
    # Mascotas
    especie_vacia: "Elige la especie.",
    color_vacio: "Escribe el color.",
    tamano_invalido: "Tamaño no válido.",
    contacto_vacio: "Escribe un contacto.",
    ya_resuelta: "Ese reporte ya estaba resuelto.",
    tipos_incompatibles: "Se debe confirmar una perdida con una encontrada.",
    # Albergues
    sin_cupo: "El albergue está lleno: no hay cupos disponibles.",
    ya_esta_en_el_albergue: "Esa persona ya está en el albergue.",
    no_esta_en_el_albergue: "Esa persona no está en el albergue.",
    capacidad_invalida: "La capacidad debe ser mayor que 0."
  }

  @doc "Mensaje en español para un error de la lógica."
  def traducir(motivo) when is_atom(motivo),
    do: Map.get(@errores, motivo, "No se pudo completar: #{motivo}.")

  # La lógica a veces responde con texto ("Persona no encontrada"): se muestra tal cual.
  def traducir(motivo) when is_binary(motivo), do: motivo

  # Error de Persistencia al leer un JSON: se nombra el archivo, sin volcar su contenido.
  def traducir(%{archivo: archivo, etapa: etapa}),
    do:
      "No se pudo leer #{Path.basename(to_string(archivo))} (#{etapa}). Revisa que el archivo sea un JSON válido."

  def traducir(motivo), do: "No se pudo completar: #{inspect(motivo)}"
end
