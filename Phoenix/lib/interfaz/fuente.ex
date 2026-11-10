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
  Comando `connect usuario contraseña tipo zona`.

  Llama a `Epicenter.GestorUsuario.login/3`: si el usuario no existe lo
  registra, y si existe valida la contraseña. Convierte el `%Epicenter.Usuario{}`
  al mapa que usa la interfaz para la sesión.
  """
  def conectar(usuario, contrasena, rol_elegido, zona_elegida) do
    if String.contains?(usuario, " ") do
      {:error, "El usuario no puede tener espacios."}
    else
      case Epicenter.GestorUsuario.login(usuario, contrasena, []) do
        {:ok, u} ->
          {:ok,
           %{
             usuario: u.nombre_usuario,
             nombre: u.nombre_completo || u.nombre_usuario,
             rol: rol_interfaz(u.rol, rol_elegido),
             zona: u.zona_principal || zona_elegida
           }}

        {:error, motivo} ->
          {:error, motivo}
      end
    end
  end

  # La lógica usa :coordinar; la interfaz usa :coordinador.
  defp rol_interfaz(:coordinar, _elegido), do: :coordinador
  defp rol_interfaz(rol, _elegido) when rol in [:ciudadano, :voluntario, :administrador], do: rol
  defp rol_interfaz(_rol, elegido), do: elegido

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

  def zonas do
    [
      %{
        codigo: "centro",
        nombre: "Centro",
        nivel: :critico,
        afectadas: 1200,
        sectores: [
          %{
            codigo: "S01",
            nombre: "Sector 3",
            nivel: :alto,
            afectadas: 640,
            puntos: [
              %{codigo: "P01", nombre: "Punto de atención sector 3"},
              %{codigo: "P02", nombre: "Parque Sucre"}
            ]
          },
          %{
            codigo: "S02",
            nombre: "Plaza de Bolívar",
            nivel: :medio,
            afectadas: 560,
            puntos: [%{codigo: "P03", nombre: "Carpa Cruz Roja"}]
          }
        ]
      },
      %{
        codigo: "zona_norte",
        nombre: "Norte",
        nivel: :alto,
        afectadas: 820,
        sectores: [
          %{
            codigo: "S03",
            nombre: "La Castellana",
            nivel: :alto,
            afectadas: 600,
            puntos: [%{codigo: "P04", nombre: "Albergue Norte"}]
          },
          %{codigo: "S04", nombre: "Laureles", nivel: :bajo, afectadas: 220, puntos: []}
        ]
      },
      %{
        codigo: "zona_sur",
        nombre: "Sur",
        nivel: :medio,
        afectadas: 450,
        sectores: [
          %{
            codigo: "S05",
            nombre: "La Patria",
            nivel: :medio,
            afectadas: 450,
            puntos: [%{codigo: "P05", nombre: "Coliseo del Sur"}]
          }
        ]
      },
      %{codigo: "occidente", nombre: "Occidente", nivel: :bajo, afectadas: 120, sectores: []}
    ]
  end

  def necesidades do
    [
      %{
        id: "N001",
        tipo: :agua,
        cantidad: 30,
        prioridad: :critica,
        zona: "centro",
        estado: :asignada,
        descripcion: "Punto de atención sector 3",
        responsable: "laura"
      },
      %{
        id: "N002",
        tipo: :agua,
        cantidad: 25,
        prioridad: :alta,
        zona: "centro",
        estado: :pendiente,
        descripcion: "Familias del sector 3 sin acueducto",
        responsable: "carlos"
      },
      %{
        id: "N003",
        tipo: :medicamentos,
        cantidad: 40,
        prioridad: :critica,
        zona: "zona_norte",
        estado: :pendiente,
        descripcion: "Insulina y antihipertensivos",
        responsable: "carlos"
      },
      %{
        id: "N004",
        tipo: :alimentos,
        cantidad: 120,
        prioridad: :media,
        zona: "zona_sur",
        estado: :en_atencion,
        descripcion: "Raciones Coliseo del Sur",
        responsable: "laura"
      },
      %{
        id: "N005",
        tipo: :refugio,
        cantidad: 12,
        prioridad: :alta,
        zona: "zona_norte",
        estado: :pendiente,
        descripcion: "Familia extensa sin vivienda",
        responsable: "andres"
      },
      %{
        id: "N006",
        tipo: :rescate,
        cantidad: 1,
        prioridad: :critica,
        zona: "centro",
        estado: :en_atencion,
        descripcion: "Edificio colapsado calle 20",
        responsable: "laura"
      },
      %{
        id: "N007",
        tipo: :transporte,
        cantidad: 3,
        prioridad: :baja,
        zona: "occidente",
        estado: :atendida,
        descripcion: "Traslado de adultos mayores",
        responsable: "carlos"
      },
      %{
        id: "N008",
        tipo: :primeros_auxilios,
        cantidad: 15,
        prioridad: :media,
        zona: "zona_sur",
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
        zona: "centro"
      },
      %{
        codigo: "R002",
        nombre: "Raciones",
        categoria: :alimentos,
        cantidad: 340,
        minimo: 100,
        unidad: "raciones",
        ubicacion: "centro_acopio_1",
        zona: "centro"
      },
      %{
        codigo: "R003",
        nombre: "Kits de medicamentos",
        categoria: :medicamentos,
        cantidad: 18,
        minimo: 30,
        unidad: "kits",
        ubicacion: "albergue_norte",
        zona: "zona_norte"
      },
      %{
        codigo: "R004",
        nombre: "Frazadas",
        categoria: :refugio,
        cantidad: 210,
        minimo: 80,
        unidad: "unidades",
        ubicacion: "albergue_2",
        zona: "zona_sur"
      },
      %{
        codigo: "R005",
        nombre: "Botiquines",
        categoria: :primeros_auxilios,
        cantidad: 6,
        minimo: 20,
        unidad: "botiquines",
        ubicacion: "centro_acopio_2",
        zona: "zona_sur"
      },
      %{
        codigo: "R006",
        nombre: "Agua potable",
        categoria: :agua,
        cantidad: 400,
        minimo: 40,
        unidad: "litros",
        ubicacion: "centro_acopio_2",
        zona: "zona_sur"
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
        zona: "zona_norte",
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
        zona: "centro",
        estado: :sin_informacion,
        albergue: nil,
        historial: [%{fecha: "09/11 06:40", estado: :sin_informacion, por: "laura"}]
      },
      %{
        id: "PE03",
        documento: "1097001456",
        nombre: "Jorge Ramírez",
        edad: 45,
        zona: "centro",
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
        zona: "zona_sur",
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
        zona: "occidente",
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
        zona: "zona_norte",
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
        zona: "zona_norte",
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
        zona: "centro",
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
        zona: "zona_sur",
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
        zona: "zona_sur",
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
        zona: "zona_norte",
        capacidad: 150,
        ocupacion: 128
      },
      %{
        codigo: "A02",
        nombre: "Coliseo del Sur",
        zona: "zona_sur",
        capacidad: 300,
        ocupacion: 141
      },
      %{codigo: "A03", nombre: "Escuela Centro", zona: "centro", capacidad: 80, ocupacion: 79},
      %{codigo: "A04", nombre: "Polideportivo", zona: "occidente", capacidad: 120, ocupacion: 22}
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
    zona = Enum.find(zonas(), &(&1.codigo == codigo))

    %{
      sectores: length(zona.sectores),
      puntos: zona.sectores |> Enum.map(&length(&1.puntos)) |> Enum.sum(),
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
        zona: "centro",
        conectado: true
      },
      %{
        usuario: "carlos",
        nombre: "Carlos Mejía",
        rol: :voluntario,
        zona: "zona_norte",
        conectado: true
      },
      %{
        usuario: "andres",
        nombre: "Andrés Gómez",
        rol: :ciudadano,
        zona: "zona_norte",
        conectado: false
      },
      %{
        usuario: "admin",
        nombre: "Administración",
        rol: :administrador,
        zona: "centro",
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
