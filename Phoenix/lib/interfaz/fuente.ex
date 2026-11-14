defmodule Interfaz.Fuente do
  @moduledoc """
  Punto único de contacto entre la interfaz gráfica y la lógica del sistema.

  La interfaz NO implementa reglas de negocio. Mientras la lógica del proyecto
  `epicenter/` se termina, este módulo entrega datos de muestra (basados en el
  flujo de ejemplo del enunciado) para que todas las pantallas se puedan ver.

  Para integrar: reemplazar el cuerpo de cada función por la llamada al
  GenServer o módulo de dominio correspondiente, conservando la forma de los
  mapas que se devuelven (o adaptándolos aquí mismo). Las vistas no tienen que
  cambiar.
  """

  alias Epicenter.Autorizacion

  # ---------------------------------------------------------------------------
  # Sesión
  # ---------------------------------------------------------------------------

  @doc """
  Comando `connect usuario contraseña`.

  Los usuarios se manejan a través del proceso `Epicenter.Genserver` (lo arranca
  el supervisor `Epicenter.Aplicacion` al iniciar la lógica). Así varias
  conexiones al mismo tiempo pasan por un solo proceso, una después de otra.

  Si el usuario ya existe, valida la contraseña con `Epicenter.Genserver.login/2`
  y devuelve `{:ok, sesion}`. Si no existe devuelve `:nuevo`, para que la pantalla
  pida nombre completo, tipo de usuario y zona antes de registrarlo con `registrar/5`.
  """
  def conectar(usuario, contrasena) do
    usuario = limpiar(usuario)

    with :ok <- validar_usuario(usuario),
         :ok <- validar_contrasena(contrasena) do
      if usuario_existe?(usuario) do
        case Epicenter.Genserver.login(usuario, contrasena) do
          {:ok, u} -> {:ok, sesion(u, rol_interfaz(u.rol), codigo_zona(u.zona_principal))}
          {:error, motivo} -> {:error, motivo}
        end
      else
        :nuevo
      end
    end
  end

  @doc """
  Registra a un usuario nuevo con su nombre completo, tipo de usuario y zona principal.

  Un usuario nuevo solo puede ser ciudadano o voluntario. La lógica todavía no
  tiene un registro que reciba todos los datos (`Genserver.crear/2` crea a todos
  como ciudadano, sin nombre ni zona), así que se hace en dos pasos, ambos por
  el GenServer de usuarios:

    1. `Epicenter.Genserver.crear/2` crea el usuario básico.
    2. `Epicenter.Genserver.actualizar/2` lo guarda completo con rol, nombre y zona.

  Cuando la lógica tenga un registro completo, se reemplazan los dos pasos por esa llamada.

  La zona llega por su nombre ("Sur") y así se guarda en `zona_principal`. La sesión
  usa el código de la zona, porque los demás formularios eligen zonas por código.
  """
  def registrar(usuario, contrasena, nombre_completo, rol, nombre_zona) do
    usuario = limpiar(usuario)
    nombre_completo = limpiar(nombre_completo)

    with :ok <- validar_usuario(usuario),
         :ok <- validar_contrasena_nueva(contrasena),
         :ok <- validar_nombre_completo(nombre_completo),
         {:ok, rol} <- validar_rol_registro(rol),
         {:ok, zona} <- buscar_zona_por_nombre(nombre_zona),
         :ok <- validar_usuario_libre(usuario),
         {:ok, basico} <- Epicenter.Genserver.crear(usuario, contrasena),
         completo = %{
           basico
           | rol: rol,
             nombre_completo: nombre_completo,
             zona_principal: zona.nombre
         },
         {:ok, u} <- Epicenter.Genserver.actualizar(usuario, completo) do
      {:ok, sesion(u, rol, zona.codigo)}
    end
  end

  @doc "Tipos de usuario que puede elegir alguien que se registra."
  def roles_registro, do: [:ciudadano, :voluntario]

  # Se pregunta al GenServer de usuarios; si no lo encuentra, el usuario es nuevo.
  defp usuario_existe?(usuario) do
    match?({:ok, _usuario}, Epicenter.Genserver.obtener(usuario))
  end

  defp sesion(u, rol, zona) do
    %{
      usuario: u.nombre_usuario,
      nombre: u.nombre_completo || u.nombre_usuario,
      rol: rol,
      zona: zona
    }
  end

  defp limpiar(texto), do: texto |> to_string() |> String.trim()

  # ---------------------------------------------------------------------------
  # Validaciones de lo que el usuario escribe en la pantalla de conexión.
  # Se revisan antes de llamar a la lógica; cada una devuelve :ok o {:error, mensaje}.
  # ---------------------------------------------------------------------------

  @usuario_min 3
  @usuario_max 20
  @contrasena_min 4

  defp validar_usuario(""), do: {:error, "Escribe tu usuario."}

  defp validar_usuario(usuario) do
    cond do
      String.contains?(usuario, " ") ->
        {:error, "El usuario no puede tener espacios."}

      String.length(usuario) < @usuario_min or String.length(usuario) > @usuario_max ->
        {:error, "El usuario debe tener entre #{@usuario_min} y #{@usuario_max} caracteres."}

      true ->
        :ok
    end
  end

  # Para entrar solo se pide que no esté vacía (los usuarios viejos pueden tener claves cortas).
  defp validar_contrasena(contrasena) when contrasena in [nil, ""],
    do: {:error, "Escribe tu contraseña."}

  defp validar_contrasena(_contrasena), do: :ok

  # Para registrarse se exige el mínimo.
  defp validar_contrasena_nueva(contrasena) do
    with :ok <- validar_contrasena(contrasena) do
      if String.length(contrasena) < @contrasena_min,
        do: {:error, "La contraseña debe tener al menos #{@contrasena_min} caracteres."},
        else: :ok
    end
  end

  # Acepta el rol como texto del formulario ("voluntario") o como átomo.
  defp validar_rol_registro(rol) do
    case Enum.find(roles_registro(), &(to_string(&1) == to_string(rol))) do
      nil -> {:error, "Al registrarte solo puedes ser ciudadano o voluntario."}
      rol -> {:ok, rol}
    end
  end

  @nombre_min 3
  @nombre_max 60

  defp validar_nombre_completo(""), do: {:error, "Escribe tu nombre completo."}

  defp validar_nombre_completo(nombre) do
    if String.length(nombre) < @nombre_min or String.length(nombre) > @nombre_max,
      do:
        {:error,
         "El nombre completo debe tener entre #{@nombre_min} y #{@nombre_max} caracteres."},
      else: :ok
  end

  # El usuario guarda su zona principal por nombre ("Centro"); la sesión usa el código.
  # También acepta un código, por si algún usuario quedó guardado así.
  # Si no coincide con ninguna zona, se usa la primera.
  defp codigo_zona(valor) do
    zonas = zonas()

    case Enum.find(zonas, &(&1.nombre == valor or &1.codigo == valor)) do
      nil -> if zonas == [], do: nil, else: hd(zonas).codigo
      zona -> zona.codigo
    end
  end

  defp buscar_zona_por_nombre(nombre) do
    case Enum.find(zonas(), &(&1.nombre == nombre)) do
      nil -> {:error, "Zona no válida."}
      zona -> {:ok, zona}
    end
  end

  defp validar_usuario_libre(usuario) do
    if usuario_existe?(usuario),
      do: {:error, "Ese usuario ya existe. Conéctate con tu contraseña."},
      else: :ok
  end

  # La lógica usa :coordinar; la interfaz usa :coordinador.
  defp rol_interfaz(:coordinar), do: :coordinador
  defp rol_interfaz(rol) when rol in [:ciudadano, :voluntario, :administrador], do: rol
  defp rol_interfaz(_rol), do: :ciudadano

  @doc "Comando `disconnect`."
  def desconectar(_usuario), do: :ok

  @doc """
  Envía una acción a la lógica del sistema.

  Hoy solo devuelve el comando equivalente del enunciado para mostrarlo en la
  interfaz. Integración: despachar `accion` al módulo de dominio que corresponda
  y devolver `{:ok, mensaje}` o `{:error, motivo}`.
  """
  def ejecutar(accion, argumentos, usuario) when is_list(argumentos) do
    with {:ok, permiso, zona} <- permiso_accion(accion, argumentos),
         false <- Enum.any?(argumentos, &(&1 in [nil, ""])) do
      Autorizacion.ejecutar(usuario, permiso, zona, fn _usuario ->
        {:ok, comando(accion, argumentos)}
      end)
    else
      true -> {:error, "Completa todos los campos."}
      {:error, _motivo} = error -> error
    end
  end

  def ejecutar(_accion, _argumentos, _usuario), do: {:error, :accion_no_autorizada}

  defp permiso_accion("register_need", argumentos) do
    prioridad = Enum.at(argumentos, 2)

    permiso =
      if to_string(prioridad) == "critica",
        do: :registrar_necesidad_critica,
        else: :registrar_necesidad

    {:ok, permiso, Enum.at(argumentos, 3)}
  end

  defp permiso_accion("assign_resource", argumentos),
    do: {:ok, :asignar_recurso, zona_necesidad(Enum.at(argumentos, 0))}

  defp permiso_accion("update_need", argumentos),
    do: {:ok, :cambiar_estado_necesidad, zona_necesidad(Enum.at(argumentos, 0))}

  defp permiso_accion("register_resource", argumentos),
    do: {:ok, :gestionar_recursos, Enum.at(argumentos, 6)}

  defp permiso_accion("register_entry", argumentos),
    do: {:ok, :registrar_ingreso_albergue, zona_albergue(Enum.at(argumentos, 0))}

  defp permiso_accion("register_exit", argumentos),
    do: {:ok, :registrar_salida_albergue, zona_albergue(Enum.at(argumentos, 0))}

  defp permiso_accion("transfer_resource", argumentos),
    do: {:ok, :transferir_recursos, zona_recurso(Enum.at(argumentos, 0))}

  defp permiso_accion("register_shelter", _argumentos),
    do: {:ok, :registrar_albergue, nil}

  defp permiso_accion(_accion, _argumentos), do: {:error, :accion_no_autorizada}

  defp zona_necesidad(id), do: Enum.find_value(necesidades(), &if(&1.id == id, do: &1.zona))

  defp zona_recurso(codigo),
    do: Enum.find_value(recursos(), &if(&1.codigo == codigo, do: &1.zona))

  defp zona_albergue(codigo),
    do: Enum.find_value(albergues(), &if(&1.codigo == codigo, do: &1.zona))

  defp comando(accion, argumentos) do
    valores =
      Enum.map(argumentos, fn v ->
        v = to_string(v)
        if String.contains?(v, " "), do: ~s("#{v}"), else: v
      end)

    Enum.join([accion | valores], " ")
  end

  # ---------------------------------------------------------------------------
  # Catálogos (valores permitidos según el enunciado)
  # ---------------------------------------------------------------------------

  def roles, do: [:ciudadano, :voluntario, :coordinador, :administrador]
  def niveles, do: [:critico, :alto, :medio, :bajo]
  def prioridades, do: [:critica, :alta, :media, :baja]

  def tipos_necesidad,
    do: [
      :agua,
      :alimentos,
      :medicamentos,
      :primeros_auxilios,
      :refugio,
      :transporte,
      :rescate,
      :otra
    ]

  def estados_necesidad, do: [:pendiente, :asignada, :en_atencion, :atendida, :cancelada]

  def estados_persona,
    do: [:sin_informacion, :reportada, :localizada, :trasladada, :en_albergue, :reunificada]

  def estados_mascota, do: [:activa, :posible_coincidencia, :resuelta]
  def especies, do: [:perro, :gato, :ave, :otra]
  def tamanos, do: [:pequeno, :mediano, :grande]

  # ---------------------------------------------------------------------------
  # Datos de muestra
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Zonas (conectado a la lógica: Epicenter.GestorZonas + Epicenter.Persistencia)
  #
  # Cada operación sigue el mismo patrón:
  #   1. cargar las zonas del JSON
  #   2. pedirle el cambio al GestorZonas (lógica pura)
  #   3. guardar el resultado en el JSON
  # ---------------------------------------------------------------------------

  @doc """
  Zonas leídas de `Zonas.json`, ordenadas por nombre.

  La interfaz muestra las personas afectadas de cada zona, pero el struct
  `Epicenter.Zona` no guarda ese dato: se calcula con `Zona.total_afectadas/1`.
  Por eso cada zona se pasa a un mapa y se le agrega `:afectadas`.
  """
  def zonas do
    Epicenter.Persistencia.carga_zonas()
    |> Epicenter.GestorZonas.listar()
    |> Enum.map(fn zona ->
      zona
      |> Map.from_struct()
      |> Map.put(:afectadas, Epicenter.Zona.total_afectadas(zona))
    end)
    |> Enum.sort_by(& &1.nombre)
  end

  @doc "Comando `register_zone`: el código lo genera la lógica."
  def registrar_zona(nombre, nivel, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre de la zona."),
         {:ok, nivel} <- nivel(nivel) do
      Autorizacion.ejecutar(usuario, :administrar_configuracion, nil, fn _usuario ->
        Epicenter.Persistencia.carga_zonas()
        |> Epicenter.GestorZonas.registrar(nombre, nivel)
        |> guardar_zonas("Zona #{nombre} registrada.")
      end)
    end
  end

  @doc "Comando `register_sector`: el sector queda dentro de la zona elegida."
  def registrar_sector(codigo_zona, nombre, nivel, afectadas, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del sector."),
         {:ok, nivel} <- nivel(nivel),
         {:ok, afectadas} <- entero(afectadas) do
      Autorizacion.ejecutar(usuario, :registrar_sector, codigo_zona, fn _usuario ->
        Epicenter.Persistencia.carga_zonas()
        |> Epicenter.GestorZonas.registrar_sector(codigo_zona, nombre, nivel, afectadas)
        |> guardar_zonas("Sector #{nombre} registrado.")
      end)
    end
  end

  @doc "Comando `register_point`: el punto queda dentro del sector elegido."
  def registrar_punto(codigo_zona, codigo_sector, nombre, usuario) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del punto de atención.") do
      Autorizacion.ejecutar(usuario, :registrar_punto_atencion, codigo_zona, fn _usuario ->
        Epicenter.Persistencia.carga_zonas()
        |> Epicenter.GestorZonas.registrar_punto(codigo_zona, codigo_sector, nombre)
        |> guardar_zonas("Punto de atención #{nombre} registrado.")
      end)
    end
  end

  # Si la lógica respondió {:ok, zonas}, se guardan; si no, se traduce el error.
  defp guardar_zonas({:ok, zonas}, mensaje) do
    Epicenter.Persistencia.guardar_zonas(zonas)
    {:ok, mensaje}
  end

  defp guardar_zonas({:error, motivo}, _mensaje), do: {:error, mensaje_error(motivo)}

  # Los formularios envían texto; la lógica espera átomos y enteros.
  defp texto(valor, mensaje_vacio) do
    case limpiar(valor) do
      "" -> {:error, mensaje_vacio}
      valor -> {:ok, valor}
    end
  end

  # Se compara contra la lista de niveles para no crear átomos con lo que escriba el usuario.
  defp nivel(valor) do
    case Enum.find(niveles(), &(to_string(&1) == valor)) do
      nil -> {:error, "Nivel de afectación no válido."}
      nivel -> {:ok, nivel}
    end
  end

  defp entero(valor) do
    case Integer.parse(to_string(valor)) do
      {numero, ""} when numero >= 0 -> {:ok, numero}
      _ -> {:error, "Las personas afectadas deben ser un número entero mayor o igual a 0."}
    end
  end

  defp mensaje_error(:nombre_duplicado), do: "Ya existe una zona con ese nombre."
  defp mensaje_error(:sector_duplicado), do: "Esa zona ya tiene un sector con ese nombre."
  defp mensaje_error(:punto_duplicado), do: "Ese sector ya tiene un punto con ese nombre."
  defp mensaje_error(:no_encontrada), do: "La zona no existe."
  defp mensaje_error(:sector_no_encontrado), do: "El sector no existe."
  defp mensaje_error(:nombre_vacio), do: "El nombre no puede estar vacío."
  defp mensaje_error(:nivel_invalido), do: "Nivel de afectación no válido."
  defp mensaje_error(:afectadas_invalidas), do: "Número de personas afectadas no válido."
  # Personas y mensajes
  defp mensaje_error(:documento_vacio), do: "Escribe el documento o una referencia."
  defp mensaje_error(:documento_duplicado), do: "Ya hay una persona reportada con ese documento."
  defp mensaje_error(:edad_invalida), do: "La edad debe estar entre 0 y 120."
  defp mensaje_error(:zona_vacia), do: "Elige una zona."
  defp mensaje_error(:estado_invalido), do: "Estado no válido."
  defp mensaje_error(:transicion_invalida), do: "Ese cambio de estado no está permitido."
  defp mensaje_error(:ya_reunificada), do: "La persona ya fue reunificada; su estado no cambia."
  defp mensaje_error(:remitente_vacio), do: "Falta quién envía el mensaje."
  defp mensaje_error(:destinatario_vacio), do: "Falta la persona a quien va el mensaje."
  defp mensaje_error(:contenido_vacio), do: "Escribe el mensaje."
  # Mascotas
  defp mensaje_error(:tipo_invalido), do: "Elige si la mascota está perdida o fue encontrada."
  defp mensaje_error(:especie_vacia), do: "Elige la especie."
  defp mensaje_error(:color_vacio), do: "Escribe el color."
  defp mensaje_error(:tamano_invalido), do: "Tamaño no válido."
  defp mensaje_error(:contacto_vacio), do: "Escribe un contacto."
  defp mensaje_error(:ya_resuelta), do: "Ese reporte ya estaba resuelto."
  # Albergues
  defp mensaje_error(:sin_cupo), do: "El albergue está lleno: no hay cupos disponibles."
  defp mensaje_error(:ya_esta_en_el_albergue), do: "Esa persona ya está en el albergue."
  defp mensaje_error(:no_esta_en_el_albergue), do: "Esa persona no está en el albergue."
  defp mensaje_error(:capacidad_invalida), do: "La capacidad debe ser mayor que 0."
  defp mensaje_error(:zona_no_existe), do: "La zona no existe."

  defp mensaje_error(:tipos_incompatibles),
    do: "Se debe confirmar una perdida con una encontrada."

  defp mensaje_error(:categoria_invalida), do: "Elige una categoría válida."
  defp mensaje_error(:cantidad_invalida), do: "La cantidad debe ser un número entero mayor que 0."
  defp mensaje_error(:sin_existencias), do: "No hay suficientes unidades en inventario."
  defp mensaje_error(:mismo_destino), do: "El destino debe ser distinto de la ubicación actual."
  defp mensaje_error(:recurso_no_encontrado), do: "El recurso no existe."
  # La lógica a veces responde con texto ("Persona no encontrada"): se muestra tal cual.
  defp mensaje_error(motivo) when is_binary(motivo), do: motivo
  defp mensaje_error(motivo), do: "No se pudo completar: #{inspect(motivo)}"

  def necesidades do
    [
      %{
        id: "N001",
        tipo: :agua,
        cantidad: 30,
        prioridad: :critica,
        zona: "A1F03C9E7B2D4410",
        estado: :asignada,
        descripcion: "Punto de atención sector 3",
        responsable: "laura"
      },
      %{
        id: "N002",
        tipo: :agua,
        cantidad: 25,
        prioridad: :alta,
        zona: "A1F03C9E7B2D4410",
        estado: :pendiente,
        descripcion: "Familias del sector 3 sin acueducto",
        responsable: "carlos"
      },
      %{
        id: "N003",
        tipo: :medicamentos,
        cantidad: 40,
        prioridad: :critica,
        zona: "B7D24E901FA3C665",
        estado: :pendiente,
        descripcion: "Insulina y antihipertensivos",
        responsable: "carlos"
      },
      %{
        id: "N004",
        tipo: :alimentos,
        cantidad: 120,
        prioridad: :media,
        zona: "C58E13A6B0F94D72",
        estado: :en_atencion,
        descripcion: "Raciones Coliseo del Sur",
        responsable: "laura"
      },
      %{
        id: "N005",
        tipo: :refugio,
        cantidad: 12,
        prioridad: :alta,
        zona: "B7D24E901FA3C665",
        estado: :pendiente,
        descripcion: "Familia extensa sin vivienda",
        responsable: "andres"
      },
      %{
        id: "N006",
        tipo: :rescate,
        cantidad: 1,
        prioridad: :critica,
        zona: "A1F03C9E7B2D4410",
        estado: :en_atencion,
        descripcion: "Edificio colapsado calle 20",
        responsable: "laura"
      },
      %{
        id: "N007",
        tipo: :transporte,
        cantidad: 3,
        prioridad: :baja,
        zona: "D06A7F2C9E31B845",
        estado: :atendida,
        descripcion: "Traslado de adultos mayores",
        responsable: "carlos"
      },
      %{
        id: "N008",
        tipo: :primeros_auxilios,
        cantidad: 15,
        prioridad: :media,
        zona: "C58E13A6B0F94D72",
        estado: :cancelada,
        descripcion: "Duplicada con N004",
        responsable: "admin"
      }
    ]
  end

  # ---------------------------------------------------------------------------
  # Recursos (conectado a Epicenter.GestorRecurso y Epicenter.GestorHistorial)
  # ---------------------------------------------------------------------------

  @doc "Recursos guardados en Recurso.json, ordenados por código."
  def recursos do
    case Epicenter.GestorRecurso.listar() do
      {:ok, recursos} -> recursos |> Enum.map(&recurso_a_mapa/1) |> Enum.sort_by(& &1.codigo)
      {:error, _motivo} -> []
    end
  end

  def categorias_recurso, do: Epicenter.Recurso.categorias()

  @doc "Historial de movimientos (Historial.json), del más reciente al más antiguo."
  def movimientos do
    case Epicenter.GestorHistorial.listar() do
      {:ok, movimientos} -> Enum.map(movimientos, &movimiento_a_mapa/1)
      {:error, _motivo} -> []
    end
  end

  def registrar_recurso(datos, por) do
    with {:ok, nombre} <- texto(datos["nombre"], "Escribe el nombre del recurso."),
         {:ok, unidad} <- texto(datos["unidad"], "Escribe la unidad de medida."),
         {:ok, ubicacion} <- texto(datos["ubicacion"], "Escribe la ubicación."),
         {:ok, zona} <- texto(datos["zona"], "Elige una zona."),
         {:ok, recurso} <-
           Epicenter.GestorRecurso.registrar(
             %{
               nombre: nombre,
               categoria: datos["categoria"],
               unidad_medida: unidad,
               cantidad: datos["cantidad"],
               minimo: datos["minimo"],
               ubicacion: ubicacion,
               codigo_zona: zona
             },
             por
           ) do
      {:ok, "Recurso #{recurso.codigo} · #{recurso.nombre} registrado."}
    else
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  def registrar_entrada_recurso(codigo, cantidad, por) do
    case Epicenter.GestorRecurso.registrar_entrada(codigo, cantidad, por) do
      {:ok, recurso} ->
        {:ok,
         "Entrada registrada: #{recurso.nombre} queda en #{recurso.cantidad_disponible} #{recurso.unidad_medida}."}

      {:error, motivo} ->
        {:error, mensaje_error(motivo)}
    end
  end

  def registrar_salida_recurso(codigo, cantidad, motivo, por) do
    with {:ok, motivo} <- texto(motivo, "Escribe el motivo de la salida."),
         {:ok, recurso} <- Epicenter.GestorRecurso.registrar_salida(codigo, cantidad, motivo, por) do
      {:ok,
       "Salida registrada: #{recurso.nombre} queda en #{recurso.cantidad_disponible} #{recurso.unidad_medida}."}
    else
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  def transferir_recurso(codigo, cantidad, destino, zona_destino, por) do
    with {:ok, destino} <- texto(destino, "Escribe el destino."),
         {:ok, zona_destino} <- texto(zona_destino, "Elige la zona del destino."),
         {:ok, recurso} <-
           Epicenter.GestorRecurso.transferir(codigo, cantidad, destino, zona_destino, por) do
      {:ok,
       "Transferencia hecha a #{destino}. En #{recurso.ubicacion} quedan #{recurso.cantidad_disponible} #{recurso.unidad_medida}."}
    else
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  defp recurso_a_mapa(recurso) do
    %{
      codigo: recurso.codigo,
      nombre: recurso.nombre,
      categoria: recurso.categoria,
      cantidad: recurso.cantidad_disponible,
      minimo: recurso.minimo,
      unidad: recurso.unidad_medida,
      ubicacion: recurso.ubicacion,
      zona: recurso.codigo_zona
    }
  end

  defp movimiento_a_mapa(movimiento) do
    %{
      id: movimiento.id,
      fecha: fecha_corta(movimiento.fecha),
      tipo: movimiento.tipo,
      recurso: movimiento.codigo_recurso,
      cantidad: movimiento.cantidad,
      detalle: movimiento.detalle,
      usuario: movimiento.usuario
    }
  end

  # ---------------------------------------------------------------------------
  # Personas y mensajes familiares (conectado a Epicenter.GestorPersona y
  # Epicenter.GestorMensaje). Los structs se pasan a mapas con la forma que
  # usan las vistas.
  # ---------------------------------------------------------------------------

  @doc "Todas las personas reportadas."
  def personas, do: buscar_personas(%{})

  @doc """
  Comando `find_person`: busca por texto (nombre o documento), zona y estado.
  Los campos vacíos se ignoran.
  """
  def buscar_personas(filtros) do
    filtros = %{
      texto: Map.get(filtros, "texto", ""),
      zona: Map.get(filtros, "zona", ""),
      estado: Map.get(filtros, "estado", "")
    }

    case Epicenter.GestorPersona.buscar(filtros) do
      {:ok, personas} -> Enum.map(personas, &persona_a_mapa/1)
      {:error, _motivo} -> []
    end
  end

  @doc "Comando `report_person`. `por` es el usuario que hace el reporte."
  def reportar_persona(documento, nombre, edad, zona, estado, por) do
    Autorizacion.ejecutar(por, :registrar_persona, zona, fn usuario ->
      case Epicenter.GestorPersona.reportar_persona(
             documento,
             nombre,
             edad,
             zona,
             estado,
             usuario.nombre_usuario
           ) do
        {:ok, persona} -> {:ok, "Persona #{persona.nombre} reportada."}
        {:error, motivo} -> {:error, mensaje_error(motivo)}
      end
    end)
  end

  @doc "Comando `update_person`: el cambio queda en el historial."
  def cambiar_estado_persona(documento, estado, por) do
    with {:ok, persona} <- Epicenter.GestorPersona.obtener_por_documento(documento) do
      Autorizacion.ejecutar(por, :actualizar_persona, persona.codigo_zona, fn usuario ->
        case Epicenter.GestorPersona.cambiar_estado(
               documento,
               estado,
               usuario.nombre_usuario
             ) do
          {:ok, persona_actualizada} ->
            {:ok, "Estado de #{persona_actualizada.nombre} actualizado."}

          {:error, motivo} ->
            {:error, mensaje_error(motivo)}
        end
      end)
    end
  end

  @doc "Comando `list_family_messages`: mensajes para una persona, del más reciente al más antiguo."
  def mensajes_de(documento) do
    case Epicenter.GestorMensaje.listar_por_persona(documento) do
      {:ok, mensajes} ->
        mensajes
        |> Enum.sort_by(& &1.fecha_envio, {:desc, DateTime})
        |> Enum.map(&mensaje_a_mapa/1)

      {:error, _motivo} ->
        []
    end
  end

  @doc "Todos los mensajes familiares (para el resumen)."
  def mensajes do
    case Epicenter.GestorMensaje.listar() do
      {:ok, mensajes} -> Enum.map(mensajes, &mensaje_a_mapa/1)
      {:error, _motivo} -> []
    end
  end

  @doc "Comando `send_family_message`."
  def enviar_mensaje(usuario, documento, contenido) do
    Autorizacion.ejecutar(usuario, :enviar_mensaje, nil, fn actor ->
      remitente = actor.nombre_completo || actor.nombre_usuario

      case Epicenter.GestorMensaje.enviar(remitente, documento, contenido) do
        {:ok, _mensaje} -> {:ok, "Mensaje enviado."}
        {:error, motivo} -> {:error, mensaje_error(motivo)}
      end
    end)
  end

  @doc "Comando `mark_message`: `:entregado` o `:pendiente`."
  def marcar_mensaje(codigo, estado, usuario) do
    Autorizacion.ejecutar(usuario, :marcar_mensaje, nil, fn _actor ->
      case Epicenter.GestorMensaje.marcar(codigo, estado) do
        {:ok, mensaje} -> {:ok, "Mensaje marcado como #{InterfazWeb.UI.t(mensaje.estado)}."}
        {:error, motivo} -> {:error, mensaje_error(motivo)}
      end
    end)
  end

  defp persona_a_mapa(persona) do
    %{
      id: persona.id,
      documento: persona.documento,
      nombre: persona.nombre,
      edad: persona.edad,
      zona: persona.codigo_zona,
      estado: persona.estado,
      albergue: persona.codigo_albergue,
      historial:
        Enum.map(persona.historial || [], fn h ->
          %{fecha: fecha_corta(h.fecha), estado: h.estado, por: h.por}
        end)
    }
  end

  defp mensaje_a_mapa(mensaje) do
    %{
      id: mensaje.codigo,
      fecha: fecha_corta(mensaje.fecha_envio),
      remitente: mensaje.remitente,
      destinatario: mensaje.destinatario,
      contenido: mensaje.contenido,
      estado: mensaje.estado
    }
  end

  # Las fechas llegan como DateTime (UTC). Se muestran en hora de Colombia (UTC-5).
  defp fecha_corta(%DateTime{} = fecha),
    do: fecha |> DateTime.add(-5, :hour) |> Calendar.strftime("%d/%m %H:%M")

  defp fecha_corta(fecha), do: to_string(fecha)

  # ---------------------------------------------------------------------------
  # Mascotas (conectado a Epicenter.GestorMascota)
  # ---------------------------------------------------------------------------

  @doc "Todos los reportes de mascotas."
  def mascotas, do: consultar_mascotas(%{})

  @doc """
  Comando `list_pets`: filtra por especie, zona y estado. Los campos vacíos se
  ignoran (la lógica no los acepta vacíos, por eso se quitan aquí).
  """
  def consultar_mascotas(filtros) do
    filtros =
      for {clave, campo} <- [{"especie", :especie}, {"zona", :zona}, {"estado", :estado}],
          valor = Map.get(filtros, clave, ""),
          valor not in [nil, ""],
          do: {campo, valor}

    case Epicenter.GestorMascota.consultar(filtros) do
      {:ok, mascotas} -> Enum.map(mascotas, &mascota_a_mapa/1)
      {:error, _motivo} -> []
    end
  end

  @doc "Comando `report_pet`."
  def reportar_mascota(p, usuario) do
    datos = %{
      tipo: p["reporte"],
      especie: p["especie"],
      nombre: p["nombre"],
      color: p["color"],
      tamano: p["tamano"],
      zona: p["zona"],
      contacto: p["contacto"],
      caracteristicas: p["caracteristicas"]
    }

    Autorizacion.ejecutar(usuario, :reportar_mascota, datos.zona, fn _actor ->
      case Epicenter.GestorMascota.registro(datos) do
        {:ok, mascota} -> {:ok, "Mascota #{InterfazWeb.UI.t(mascota.tipo)} reportada."}
        {:error, motivo} -> {:error, mensaje_error(motivo)}
      end
    end)
  end

  @doc """
  Coincidencias candidatas (puntaje de 40 o más) entre perdidas y encontradas
  no resueltas. Cada una trae qué criterios coincidieron.
  """
  def coincidencias do
    case Epicenter.GestorMascota.coincidencias_posibles() do
      {:ok, lista} -> Enum.map(lista, &coincidencia_a_mapa/1)
      {:error, _motivo} -> []
    end
  end

  @doc "Comando `match_pets`: marca como posible coincidencia las parejas de 70 o más."
  def buscar_coincidencias(usuario, codigo_zona) do
    Autorizacion.ejecutar(usuario, :validar_coincidencias_mascotas, codigo_zona, fn _actor ->
      case Epicenter.GestorMascota.marcar_coincidencias(codigo_zona) do
        {:ok, []} -> {:ok, "No hay parejas nuevas con 70 puntos o más para marcar."}
        {:ok, [_una]} -> {:ok, "Se marcó 1 posible coincidencia."}
        {:ok, parejas} -> {:ok, "Se marcaron #{length(parejas)} posibles coincidencias."}
        {:error, motivo} -> {:error, mensaje_error(motivo)}
      end
    end)
  end

  @doc "Comando `confirm_match`: cierra ambos reportes."
  def confirmar_coincidencia(id_perdida, id_encontrada, usuario, codigo_zona) do
    with {:ok, mascotas} <- Epicenter.GestorMascota.listar(),
         perdida when not is_nil(perdida) <- Enum.find(mascotas, &(&1.id == id_perdida)),
         encontrada when not is_nil(encontrada) <- Enum.find(mascotas, &(&1.id == id_encontrada)),
         true <- perdida.zona == codigo_zona and encontrada.zona == codigo_zona do
      Autorizacion.ejecutar(
        usuario,
        :validar_coincidencias_mascotas,
        codigo_zona,
        fn _actor ->
          case Epicenter.GestorMascota.confirmar_coincidencia(id_perdida, id_encontrada) do
            {:ok, _par} -> {:ok, "Coincidencia confirmada. Ambos reportes quedaron resueltos."}
            {:error, motivo} -> {:error, mensaje_error(motivo)}
          end
        end
      )
    else
      false -> {:error, "Las mascotas deben pertenecer a la zona autorizada."}
      nil -> {:error, "Mascota no encontrada."}
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  defp mascota_a_mapa(mascota) do
    %{
      id: mascota.id,
      reporte: mascota.tipo,
      especie: especie(mascota.especie),
      nombre: mascota.nombre,
      color: mascota.color,
      tamano: mascota.tamano,
      zona: mascota.zona,
      contacto: mascota.contacto,
      caracteristicas: mascota.caracteristicas,
      estado: mascota.estado,
      coincidencia_con: mascota.coincidencia_con
    }
  end

  # La lógica guarda la especie como texto ("perro"); la interfaz usa el átomo si es conocido.
  defp especie(texto), do: Enum.find(especies(), texto, &(to_string(&1) == texto))

  defp coincidencia_a_mapa(c) do
    %{
      perdida: c.perdida,
      encontrada: c.encontrada,
      puntaje: c.puntaje,
      criterios:
        for criterio <- [:especie, :color, :tamano, :zona, :caracteristicas] do
          {criterio, Map.get(c.desglose, criterio, 0) > 0}
        end
    }
  end

  # ---------------------------------------------------------------------------
  # Albergues (conectado a Epicenter.GestorAlbergue)
  # ---------------------------------------------------------------------------

  @doc "Albergues guardados en Albergue.json, ordenados por nombre."
  def albergues do
    case Epicenter.GestorAlbergue.listar() do
      {:ok, albergues} -> albergues |> Enum.map(&albergue_a_mapa/1) |> Enum.sort_by(& &1.nombre)
      {:error, _motivo} -> []
    end
  end

  @doc "Reporte de albergues con mayor nivel de ocupación (de mayor a menor)."
  def reporte_albergues do
    case Epicenter.GestorAlbergue.reporte_ocupacion() do
      {:ok, albergues} -> Enum.map(albergues, &albergue_a_mapa/1)
      {:error, _motivo} -> []
    end
  end

  @doc "Comando `register_shelter`: el código lo genera la lógica."
  def registrar_albergue(nombre, zona, capacidad) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del albergue."),
         {:ok, capacidad} <- capacidad(capacidad),
         {:ok, albergue} <- Epicenter.GestorAlbergue.registro(nombre, zona, capacidad) do
      {:ok, "Albergue #{albergue.nombre} registrado."}
    else
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  @doc "Comando `register_entry`: la persona queda en el albergue y su estado pasa a en albergue."
  def registrar_ingreso(codigo, documento, por) do
    case Epicenter.GestorAlbergue.registrar_ingreso(codigo, documento, por) do
      {:ok, albergue} -> {:ok, "Ingreso registrado en #{albergue.nombre}."}
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  @doc "Comando `register_exit`."
  def registrar_salida(codigo, documento) do
    case Epicenter.GestorAlbergue.registrar_salida(codigo, documento) do
      {:ok, albergue} -> {:ok, "Salida registrada de #{albergue.nombre}."}
      {:error, motivo} -> {:error, mensaje_error(motivo)}
    end
  end

  defp albergue_a_mapa(albergue) do
    %{
      codigo: albergue.codigo,
      nombre: albergue.nombre,
      zona: albergue.codigo_zona,
      capacidad: albergue.capacidad,
      ocupacion: Epicenter.Albergue.ocupacion(albergue),
      cupos: Epicenter.Albergue.cupos(albergue),
      ocupantes: albergue.ocupantes
    }
  end

  defp capacidad(valor) do
    case Integer.parse(to_string(valor)) do
      {numero, ""} when numero > 0 -> {:ok, numero}
      _ -> {:error, "La capacidad debe ser un número entero mayor que 0."}
    end
  end

  # ---------------------------------------------------------------------------
  # Consultas agregadas (equivalentes a summary, pending_needs, critical_resources)
  # Hoy se calculan sobre los datos de muestra; luego vendrán de la lógica.
  # ---------------------------------------------------------------------------

  @orden_prioridad %{critica: 0, alta: 1, media: 2, baja: 3}

  @doc "Comando `pending_needs`: necesidades abiertas, de mayor a menor prioridad."
  def necesidades_pendientes do
    necesidades()
    |> Enum.filter(&(&1.estado in [:pendiente, :asignada, :en_atencion]))
    |> Enum.sort_by(&@orden_prioridad[&1.prioridad])
  end

  @doc "Comando `critical_resources`: recursos por debajo de su mínimo."
  def recursos_criticos, do: Enum.filter(recursos(), &(&1.cantidad < &1.minimo))

  @doc "Comando `summary`."
  def resumen do
    personas = personas()
    mascotas = mascotas()
    albergues = albergues()

    %{
      necesidades_pendientes: length(necesidades_pendientes()),
      necesidades_criticas: Enum.count(necesidades_pendientes(), &(&1.prioridad == :critica)),
      recursos_criticos: length(recursos_criticos()),
      recursos_total: length(recursos()),
      personas_localizadas:
        Enum.count(
          personas,
          &(&1.estado in [:localizada, :en_albergue, :trasladada, :reunificada])
        ),
      personas_total: length(personas),
      mensajes_pendientes: Enum.count(mensajes(), &(&1.estado == :pendiente)),
      mensajes_total: length(mensajes()),
      mascotas_activas: Enum.count(mascotas, &(&1.estado != :resuelta)),
      mascotas_coincidencias: length(coincidencias()),
      ocupacion: Enum.sum_by(albergues, & &1.ocupacion),
      capacidad: Enum.sum_by(albergues, & &1.capacidad)
    }
  end

  # Cupos libres de los albergues de la zona (función recursiva de la lógica).
  defp cupos_de_zona(codigo) do
    case Epicenter.GestorAlbergue.listar() do
      {:ok, albergues} -> Epicenter.GestorAlbergue.cupos_por_zona(albergues, codigo)
      {:error, _motivo} -> 0
    end
  end

  @doc "Estadísticas acumuladas de una zona y sus sectores."
  def estadisticas_zona(codigo) do
    {:ok, zona} =
      Epicenter.GestorZonas.estadisticas(Epicenter.Persistencia.carga_zonas(), codigo)

    %{
      sectores: zona.sectores,
      puntos: zona.puntos,
      necesidades: Enum.count(necesidades_pendientes(), &(&1.zona == codigo)),
      cupos: cupos_de_zona(codigo)
    }
  end

  def usuarios do
    [
      %{
        usuario: "laura",
        nombre: "Laura Restrepo",
        rol: :coordinador,
        zona: "A1F03C9E7B2D4410",
        conectado: true
      },
      %{
        usuario: "carlos",
        nombre: "Carlos Mejía",
        rol: :voluntario,
        zona: "B7D24E901FA3C665",
        conectado: true
      },
      %{
        usuario: "andres",
        nombre: "Andrés Gómez",
        rol: :ciudadano,
        zona: "B7D24E901FA3C665",
        conectado: false
      },
      %{
        usuario: "admin",
        nombre: "Administración",
        rol: :administrador,
        zona: "A1F03C9E7B2D4410",
        conectado: true
      }
    ]
  end

  def actividad do
    [
      %{
        fecha: "09/11 10:42",
        usuario: "carlos",
        accion: "assign_resource N002 agua 25",
        resultado: :error,
        detalle: "Inventario insuficiente (20 L)"
      },
      %{
        fecha: "09/11 10:42",
        usuario: "laura",
        accion: "assign_resource N001 agua 30",
        resultado: :ok,
        detalle: "R001 queda en 20 L"
      },
      %{
        fecha: "09/11 10:30",
        usuario: "laura",
        accion: "register_resource R001 agua 50 litros centro_acopio_1",
        resultado: :ok,
        detalle: nil
      },
      %{
        fecha: "09/11 10:20",
        usuario: "carlos",
        accion: "report_pet found perro desconocido negra mediana zona_norte",
        resultado: :ok,
        detalle: "Posible coincidencia con M001"
      },
      %{
        fecha: "09/11 10:10",
        usuario: "andres",
        accion: ~s(send_family_message 1094887123 "Estoy bien..."),
        resultado: :ok,
        detalle: nil
      },
      %{
        fecha: "09/11 10:05",
        usuario: "andres",
        accion: "register_entry A01 1094887123",
        resultado: :ok,
        detalle: nil
      },
      %{
        fecha: "09/11 09:58",
        usuario: "andres",
        accion: "register_resource R009 agua 10 litros casa",
        resultado: :error,
        detalle: "Rol ciudadano sin permiso"
      },
      %{
        fecha: "09/11 09:40",
        usuario: "laura",
        accion: ~s(register_need agua 30 critica centro "Punto de atención sector 3"),
        resultado: :ok,
        detalle: "N001"
      },
      %{
        fecha: "09/11 09:39",
        usuario: "laura",
        accion: "connect laura **** coordinador centro",
        resultado: :ok,
        detalle: nil
      }
    ]
  end
end
