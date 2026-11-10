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

  # ---------------------------------------------------------------------------
  # Sesión
  # ---------------------------------------------------------------------------

  @doc """
  Comando `connect usuario contraseña`.

  Si el usuario ya existe, valida la contraseña con `Epicenter.GestorUsuario.login/3`
  y devuelve `{:ok, sesion}`. Si no existe devuelve `:nuevo`, para que la pantalla
  pida el tipo de usuario y la zona antes de registrarlo con `registrar/4`.
  """
  def conectar(usuario, contrasena) do
    usuario = limpiar(usuario)

    with :ok <- validar_usuario(usuario),
         :ok <- validar_contrasena(contrasena) do
      if usuario_existe?(usuario) do
        case Epicenter.GestorUsuario.login(usuario, contrasena, []) do
          {:ok, u} -> {:ok, sesion(u, rol_interfaz(u.rol), u.zona_principal || "A1F03C9E7B2D4410")}
          {:error, motivo} -> {:error, motivo}
        end
      else
        :nuevo
      end
    end
  end

  @doc """
  Registra a un usuario nuevo con el tipo de usuario y la zona que eligió.

  Un usuario nuevo solo puede ser ciudadano o voluntario. Hoy la lógica
  (`GestorUsuario.registro/3`) guarda a todos como ciudadano y no guarda la zona,
  así que el rol y la zona elegidos solo se usan en esta sesión. Cuando la lógica
  los reciba, basta con pasárselos aquí.
  """
  def registrar(usuario, contrasena, rol, zona) do
    usuario = limpiar(usuario)

    with :ok <- validar_usuario(usuario),
         :ok <- validar_contrasena_nueva(contrasena),
         {:ok, rol} <- validar_rol_registro(rol),
         :ok <- validar_zona(zona),
         :ok <- validar_usuario_libre(usuario) do
      case Epicenter.GestorUsuario.login(usuario, contrasena, []) do
        {:ok, u} -> {:ok, sesion(u, rol, zona)}
        {:error, motivo} -> {:error, motivo}
      end
    end
  end

  @doc "Tipos de usuario que puede elegir alguien que se registra."
  def roles_registro, do: [:ciudadano, :voluntario]

  defp usuario_existe?(usuario) do
    Enum.any?(Epicenter.Persistencia.carga_usuarios(), &(&1.nombre_usuario == usuario))
  end

  defp sesion(u, rol, zona) do
    %{usuario: u.nombre_usuario, nombre: u.nombre_completo || u.nombre_usuario, rol: rol, zona: zona}
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

  defp validar_zona(zona) do
    if Enum.any?(zonas(), &(&1.codigo == zona)),
      do: :ok,
      else: {:error, "Zona no válida."}
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
  def ejecutar(accion, argumentos) when is_list(argumentos) do
    if Enum.any?(argumentos, &(&1 in [nil, ""])) do
      {:error, "Completa todos los campos."}
    else
      {:ok, comando(accion, argumentos)}
    end
  end

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
  def registrar_zona(nombre, nivel) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre de la zona."),
         {:ok, nivel} <- nivel(nivel) do
      Epicenter.Persistencia.carga_zonas()
      |> Epicenter.GestorZonas.registrar(nombre, nivel)
      |> guardar_zonas("Zona #{nombre} registrada.")
    end
  end

  @doc "Comando `register_sector`: el sector queda dentro de la zona elegida."
  def registrar_sector(codigo_zona, nombre, nivel, afectadas) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del sector."),
         {:ok, nivel} <- nivel(nivel),
         {:ok, afectadas} <- entero(afectadas) do
      Epicenter.Persistencia.carga_zonas()
      |> Epicenter.GestorZonas.registrar_sector(codigo_zona, nombre, nivel, afectadas)
      |> guardar_zonas("Sector #{nombre} registrado.")
    end
  end

  @doc "Comando `register_point`: el punto queda dentro del sector elegido."
  def registrar_punto(codigo_zona, codigo_sector, nombre) do
    with {:ok, nombre} <- texto(nombre, "Escribe el nombre del punto de atención.") do
      Epicenter.Persistencia.carga_zonas()
      |> Epicenter.GestorZonas.registrar_punto(codigo_zona, codigo_sector, nombre)
      |> guardar_zonas("Punto de atención #{nombre} registrado.")
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

  def recursos do
    [
      %{
        codigo: "R001",
        nombre: "Agua potable",
        categoria: :agua,
        cantidad: 20,
        minimo: 40,
        unidad: "litros",
        ubicacion: "centro_acopio_1",
        zona: "A1F03C9E7B2D4410"
      },
      %{
        codigo: "R002",
        nombre: "Raciones",
        categoria: :alimentos,
        cantidad: 340,
        minimo: 100,
        unidad: "raciones",
        ubicacion: "centro_acopio_1",
        zona: "A1F03C9E7B2D4410"
      },
      %{
        codigo: "R003",
        nombre: "Kits de medicamentos",
        categoria: :medicamentos,
        cantidad: 18,
        minimo: 30,
        unidad: "kits",
        ubicacion: "albergue_norte",
        zona: "B7D24E901FA3C665"
      },
      %{
        codigo: "R004",
        nombre: "Frazadas",
        categoria: :refugio,
        cantidad: 210,
        minimo: 80,
        unidad: "unidades",
        ubicacion: "albergue_2",
        zona: "C58E13A6B0F94D72"
      },
      %{
        codigo: "R005",
        nombre: "Botiquines",
        categoria: :primeros_auxilios,
        cantidad: 6,
        minimo: 20,
        unidad: "botiquines",
        ubicacion: "centro_acopio_2",
        zona: "C58E13A6B0F94D72"
      },
      %{
        codigo: "R006",
        nombre: "Agua potable",
        categoria: :agua,
        cantidad: 400,
        minimo: 40,
        unidad: "litros",
        ubicacion: "centro_acopio_2",
        zona: "C58E13A6B0F94D72"
      }
    ]
  end

  def movimientos do
    [
      %{
        id: "MV006",
        fecha: "09/11 10:42",
        tipo: :rechazo,
        recurso: "R001",
        cantidad: 25,
        detalle: "N002 pidió 25 L; quedaban 20 L",
        usuario: "carlos"
      },
      %{
        id: "MV005",
        fecha: "09/11 10:42",
        tipo: :asignacion,
        recurso: "R001",
        cantidad: 30,
        detalle: "Asignado a N001",
        usuario: "laura"
      },
      %{
        id: "MV004",
        fecha: "09/11 10:30",
        tipo: :entrada,
        recurso: "R001",
        cantidad: 50,
        detalle: "Donación Empresas Públicas",
        usuario: "laura"
      },
      %{
        id: "MV003",
        fecha: "09/11 09:15",
        tipo: :transferencia,
        recurso: "R004",
        cantidad: 30,
        detalle: "centro_acopio_1 → albergue_2",
        usuario: "laura"
      },
      %{
        id: "MV002",
        fecha: "09/11 08:50",
        tipo: :salida,
        recurso: "R002",
        cantidad: 60,
        detalle: "Entrega Coliseo del Sur",
        usuario: "carlos"
      },
      %{
        id: "MV001",
        fecha: "09/11 08:00",
        tipo: :entrada,
        recurso: "R002",
        cantidad: 400,
        detalle: "Llegada Defensa Civil",
        usuario: "admin"
      }
    ]
  end

  def personas do
    [
      %{
        id: "PE01",
        documento: "1094887123",
        nombre: "Andrés Gómez",
        edad: 34,
        zona: "B7D24E901FA3C665",
        estado: :en_albergue,
        albergue: "A01",
        historial: [
          %{fecha: "09/11 07:10", estado: :reportada, por: "carmen"},
          %{fecha: "09/11 09:30", estado: :localizada, por: "carlos"},
          %{fecha: "09/11 10:05", estado: :en_albergue, por: "andres"}
        ]
      },
      %{
        id: "PE02",
        documento: "41923554",
        nombre: "María López",
        edad: 67,
        zona: "A1F03C9E7B2D4410",
        estado: :sin_informacion,
        albergue: nil,
        historial: [%{fecha: "09/11 06:40", estado: :sin_informacion, por: "laura"}]
      },
      %{
        id: "PE03",
        documento: "1097001456",
        nombre: "Jorge Ramírez",
        edad: 45,
        zona: "A1F03C9E7B2D4410",
        estado: :trasladada,
        albergue: nil,
        historial: [
          %{fecha: "09/11 06:55", estado: :reportada, por: "laura"},
          %{fecha: "09/11 08:20", estado: :trasladada, por: "carlos"}
        ]
      },
      %{
        id: "PE04",
        documento: "TI-1098223",
        nombre: "Sofía Castaño",
        edad: 8,
        zona: "C58E13A6B0F94D72",
        estado: :reunificada,
        albergue: "A02",
        historial: [
          %{fecha: "09/11 07:00", estado: :reportada, por: "carlos"},
          %{fecha: "09/11 08:10", estado: :en_albergue, por: "carlos"},
          %{fecha: "09/11 09:45", estado: :reunificada, por: "laura"}
        ]
      },
      %{
        id: "PE05",
        documento: "18512990",
        nombre: "Luis Pérez",
        edad: 52,
        zona: "D06A7F2C9E31B845",
        estado: :reportada,
        albergue: nil,
        historial: [%{fecha: "09/11 10:15", estado: :reportada, por: "andres"}]
      }
    ]
  end

  def mensajes do
    [
      %{
        id: "MS01",
        fecha: "09/11 09:50",
        remitente: "Carmen Gómez (hermana)",
        destinatario: "1094887123",
        contenido: "Te estamos buscando, estamos en el albergue sur.",
        estado: :entregado
      },
      %{
        id: "MS02",
        fecha: "09/11 10:10",
        remitente: "Andrés Gómez",
        destinatario: "1094887123",
        contenido: "Estoy bien, estoy en el albergue norte.",
        estado: :pendiente
      },
      %{
        id: "MS03",
        fecha: "09/11 10:20",
        remitente: "Familia López",
        destinatario: "41923554",
        contenido: "Mamá, si ves esto llama al 300 555 0101.",
        estado: :pendiente
      }
    ]
  end

  def mascotas do
    [
      %{
        id: "M001",
        reporte: :perdida,
        especie: :perro,
        nombre: "Luna",
        color: "negra",
        tamano: :mediano,
        zona: "B7D24E901FA3C665",
        contacto: "300 123 4567",
        caracteristicas: "Collar rojo, oreja izquierda caída",
        estado: :posible_coincidencia
      },
      %{
        id: "M002",
        reporte: :encontrada,
        especie: :perro,
        nombre: nil,
        color: "negra",
        tamano: :mediano,
        zona: "B7D24E901FA3C665",
        contacto: "Carlos (voluntario)",
        caracteristicas: "Collar rojo, muy dócil",
        estado: :posible_coincidencia
      },
      %{
        id: "M003",
        reporte: :perdida,
        especie: :gato,
        nombre: "Michi",
        color: "gris",
        tamano: :pequeno,
        zona: "A1F03C9E7B2D4410",
        contacto: "311 222 3344",
        caracteristicas: "Ojos verdes",
        estado: :activa
      },
      %{
        id: "M004",
        reporte: :encontrada,
        especie: :gato,
        nombre: nil,
        color: "blanco",
        tamano: :pequeno,
        zona: "C58E13A6B0F94D72",
        contacto: "Coliseo del Sur",
        caracteristicas: "Mancha gris en la cola",
        estado: :activa
      },
      %{
        id: "M005",
        reporte: :perdida,
        especie: :perro,
        nombre: "Rocky",
        color: "café",
        tamano: :grande,
        zona: "C58E13A6B0F94D72",
        contacto: "320 987 6543",
        caracteristicas: "Labrador",
        estado: :resuelta
      }
    ]
  end

  def coincidencias do
    [
      %{
        perdida: "M001",
        encontrada: "M002",
        puntaje: 92,
        criterios: [especie: true, color: true, tamano: true, zona: true, caracteristicas: true]
      },
      %{
        perdida: "M003",
        encontrada: "M004",
        puntaje: 45,
        criterios: [
          especie: true,
          color: false,
          tamano: true,
          zona: false,
          caracteristicas: false
        ]
      }
    ]
  end

  def albergues do
    [
      %{
        codigo: "A01",
        nombre: "Albergue Norte",
        zona: "B7D24E901FA3C665",
        capacidad: 150,
        ocupacion: 128
      },
      %{
        codigo: "A02",
        nombre: "Coliseo del Sur",
        zona: "C58E13A6B0F94D72",
        capacidad: 300,
        ocupacion: 141
      },
      %{codigo: "A03", nombre: "Escuela Centro", zona: "A1F03C9E7B2D4410", capacidad: 80, ocupacion: 79},
      %{codigo: "A04", nombre: "Polideportivo", zona: "D06A7F2C9E31B845", capacidad: 120, ocupacion: 22}
    ]
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

  @doc "Estadísticas acumuladas de una zona y sus sectores."
  def estadisticas_zona(codigo) do
    {:ok, zona} =
      Epicenter.GestorZonas.estadisticas(Epicenter.Persistencia.carga_zonas(), codigo)

    %{
      sectores: zona.sectores,
      puntos: zona.puntos,
      necesidades: Enum.count(necesidades_pendientes(), &(&1.zona == codigo)),
      cupos:
        albergues()
        |> Enum.filter(&(&1.zona == codigo))
        |> Enum.map(&(&1.capacidad - &1.ocupacion))
        |> Enum.sum()
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
