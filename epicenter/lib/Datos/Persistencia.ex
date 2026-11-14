defmodule Epicenter.Persistencia do
  alias Epicenter.{Zona, Sector, PuntoAtencion}

  @moduledoc """
  Modulo para cargar y guardar las estructuras desde documentos JSON.
  Zona, PuntoAtencion y Sector no se persisten aquí.

  La carpeta de datos puede configurarse con `:ruta_datos` en la aplicación
  `:epicenter`; si no se configura, se usa esta carpeta.
  """

  def carga_usuarios do
    cargar_archivo(ruta_datos("Usuario.json"), Epicenter.Usuario)
  end

  def map_a_struct(usuario) do
    %Epicenter.Usuario{
      nombre_usuario: usuario["nombre_usuario"],
      contrasena: usuario["contrasena"],
      rol: rol_a_atomos(usuario["rol"]),
      nombre_completo: usuario["nombre_completo"],
      zona_principal: usuario["zona_principal"]
    }
  end

  def cargar_recurso do
    cargar_archivo(ruta_datos("Recurso.json"), Epicenter.Recurso)
  end

  def recurso_a_struct(recurso) do
    %Epicenter.Recurso{
      codigo: recurso["codigo"],
      nombre: recurso["nombre"],
      categoria: a_atomo_existente(recurso["categoria"]),
      unidad_medida: recurso["unidad_medida"],
      ubicacion: recurso["ubicacion"],
      codigo_zona: recurso["codigo_zona"],
      cantidad_disponible: Map.get(recurso, "cantidad_disponible", 0),
      minimo: Map.get(recurso, "minimo", 0)
    }
  end

  def guardar_recursos(recursos), do: guardar_documento(recursos, ruta_datos("Recurso.json"))

  def cargar_albergues, do: cargar_archivo(ruta_datos("Albergue.json"), Epicenter.Albergue)
  def guardar_albergues(albergues), do: guardar_documento(albergues, ruta_datos("Albergue.json"))

  def albergue_a_struct(albergue) do
    %Epicenter.Albergue{
      codigo: albergue["codigo"],
      nombre: albergue["nombre"],
      codigo_zona: albergue["codigo_zona"],
      capacidad: albergue["capacidad"],
      ocupantes: albergue["ocupantes"],
      recursos: albergue["recursos"],
      necesidades: albergue["necesidades"]
    }
  end

  def cargar_centros_apoyo,
    do: cargar_archivo(ruta_datos("CentroApoyo.json"), Epicenter.CentroApoyo)

  def guardar_centros_apoyo(centros),
    do: guardar_documento(centros, ruta_datos("CentroApoyo.json"))

  def centro_apoyo_a_struct(centro) do
    %Epicenter.CentroApoyo{
      codigo: centro["codigo"],
      nombre: centro["nombre"],
      tipo: centro["tipo"],
      codigo_zona: centro["codigo_zona"]
    }
  end

  def cargar_historiales,
    do: cargar_archivo(ruta_datos("Historial.json"), Epicenter.Historial)

  def guardar_historiales(historiales),
    do: guardar_documento(historiales, ruta_datos("Historial.json"))

  def historial_a_struct(historial) do
    %Epicenter.Historial{
      id: historial["id"],
      codigo_recurso: Map.get(historial, "codigo_recurso") || historial["id_invetario"],
      tipo: a_atomo_existente(historial["tipo"]),
      cantidad: historial["cantidad"],
      detalle: historial["detalle"] || historial["codigo_destino"],
      usuario: historial["usuario"],
      fecha: a_datetime(historial["fecha"])
    }
  end

  def cargar_inventarios,
    do: cargar_archivo(ruta_datos("Inventario.json"), Epicenter.Inventario)

  def guardar_inventarios(inventarios),
    do: guardar_documento(inventarios, ruta_datos("Inventario.json"))

  def inventario_a_struct(inventario) do
    %Epicenter.Inventario{
      id: inventario["id"],
      zonas: inventario["zonas"],
      codigo_recurso: inventario["codigo_recurso"],
      codigo_centro: inventario["codigo_centro"],
      cantidad_disponible: Map.get(inventario, "cantidad_disponible", 0)
    }
  end

  def cargar_mascotas, do: cargar_archivo(ruta_datos("Mascota.json"), Epicenter.Mascota)
  def guardar_mascotas(mascotas), do: guardar_documento(mascotas, ruta_datos("Mascota.json"))

  def mascota_a_struct(registro) do
    datos = %{
      tipo: a_atomo_existente(registro["tipo"]),
      especie: registro["especie"],
      nombre: registro["nombre"],
      caracteristicas: Map.get(registro, "caracteristicas", registro["carateristicas"]),
      color: registro["color"],
      tamano: a_atomo_existente(registro["tamano"]),
      zona: Map.get(registro, "zona", registro["codigo_zona"]),
      contacto: registro["contacto"]
    }

    case Epicenter.Mascota.nuevo(registro["id"], datos) do
      {:ok, mascota} ->
        estado = mascota_estado(registro["estado"])
        %{mascota | estado: estado, coincidencia_con: registro["coincidencia_con"]}

      {:error, razon} ->
        raise ArgumentError, "datos de mascota inválidos: #{inspect(razon)}"
    end
  end

  def cargar_mensajes, do: cargar_archivo(ruta_datos("Mensaje.json"), Epicenter.Mensaje)
  def guardar_mensajes(mensajes), do: guardar_documento(mensajes, ruta_datos("Mensaje.json"))

  def mensaje_a_struct(mensaje) do
    %Epicenter.Mensaje{
      codigo: mensaje["codigo"],
      remitente: mensaje["remitente"],
      destinatario: mensaje["destinatario"],
      contenido: mensaje["contenido"],
      estado: a_atomo_existente(mensaje["estado"]),
      fecha_envio: a_datetime(mensaje["fecha_envio"])
    }
  end

  def cargar_necesidades,
    do: cargar_archivo(ruta_datos("Necesidad.json"), Epicenter.Necesidad)

  def guardar_necesidades(necesidades),
    do: guardar_documento(necesidades, ruta_datos("Necesidad.json"))

  def necesidad_a_struct(necesidad) do
    %Epicenter.Necesidad{
      id: necesidad["id"],
      codigo_zona: necesidad["codigo_zona"],
      reportado_por: Map.get(necesidad, "reportado_por") || necesidad["reportador_por"],
      tipo: a_atomo_existente(necesidad["tipo"]),
      descripcion: Map.get(necesidad, "descripcion", necesidad["descripicion"]),
      cantidad: necesidad["cantidad"],
      prioridad: a_atomo_existente(necesidad["prioridad"]),
      estado: a_atomo_existente(necesidad["estado"]),
      destino: necesidad["destino"],
      asignaciones: Map.get(necesidad, "asignaciones", []) |> Enum.map(&asignacion_a_mapa/1)
    }
  end

  def cargar_personas, do: cargar_archivo(ruta_datos("Persona.json"), Epicenter.Persona)
  def guardar_personas(personas), do: guardar_documento(personas, ruta_datos("Persona.json"))

  def ruta_datos(archivo) when is_binary(archivo) do
    ruta = Application.get_env(:epicenter, :ruta_datos, __DIR__)
    Path.join(ruta, archivo)
  end

  def persona_a_struct(persona) do
    %Epicenter.Persona{
      id: persona["id"],
      documento: persona["documento"],
      tipo_documento: a_atomo_existente(persona["tipo_documento"]),
      nombre: persona["nombre"],
      edad: persona["edad"],
      codigo_zona: persona["codigo_zona"],
      estado: a_atomo_existente(persona["estado"]),
      codigo_albergue: persona["codigo_albergue"],
      historial: historial_a_lista(persona["historial"])
    }
  end

  def cargar_archivo(ruta, estructura) when is_binary(ruta) do
    case especificacion(estructura) do
      {:ok, convertir, campos_requeridos} ->
        case File.read(ruta) do
          {:ok, contenido} ->
            case Jason.decode(contenido) do
              {:ok, datos} -> validar_documento(ruta, datos, convertir, campos_requeridos)
              {:error, razon} -> {:error, error_carga(ruta, :decodificacion, razon)}
            end

          {:error, razon} ->
            {:error, error_carga(ruta, :lectura, razon)}
        end

      :error ->
        {:error, error_carga(ruta, :estructura, :no_soportada)}
    end
  end

  def cargar_archivo(ruta, _estructura) do
    {:error, error_carga(ruta, :validacion, :ruta_invalida)}
  end

  defp validar_documento(ruta, datos, convertir, campos_requeridos) when is_list(datos) do
    datos
    |> Enum.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {registro, indice}, {:ok, cargados} ->
      case validar_registro(ruta, registro, indice, convertir, campos_requeridos) do
        {:ok, estructura} -> {:cont, {:ok, [estructura | cargados]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, registros} -> {:ok, Enum.reverse(registros)}
      error -> error
    end
  end

  defp validar_documento(ruta, _datos, _convertir, _campos_requeridos) do
    {:error, error_carga(ruta, :validacion, :se_esperaba_una_lista)}
  end

  defp validar_registro(ruta, registro, indice, convertir, campos_requeridos)
       when is_map(registro) do
    campos_faltantes =
      Enum.filter(campos_requeridos, fn campo ->
        valor_campo(registro, campo) in [nil, ""]
      end)

    if campos_faltantes == [] do
      convertir_registro(ruta, registro, indice, convertir)
    else
      {:error, error_carga(ruta, :validacion, {:campos_requeridos, campos_faltantes}, indice)}
    end
  end

  defp validar_registro(ruta, _registro, indice, _convertir, _campos_requeridos) do
    {:error, error_carga(ruta, :validacion, :registro_no_es_objeto, indice)}
  end

  defp valor_campo(registro, :zona) do
    Map.get(registro, "zona") || Map.get(registro, "codigo_zona")
  end

  defp valor_campo(registro, :codigo_recurso) do
    Map.get(registro, "codigo_recurso") || Map.get(registro, "id_invetario")
  end

  defp valor_campo(registro, :reportado_por) do
    Map.get(registro, "reportado_por") || Map.get(registro, "reportador_por")
  end

  defp valor_campo(registro, campo), do: Map.get(registro, Atom.to_string(campo))

  defp convertir_registro(ruta, registro, indice, convertir) do
    {:ok, convertir.(registro)}
  rescue
    error ->
      {:error, error_carga(ruta, :conversion, Exception.message(error), indice)}
  catch
    tipo, razon ->
      {:error, error_carga(ruta, :conversion, {tipo, razon}, indice)}
  end

  defp especificacion(Epicenter.Usuario),
    do: {:ok, &map_a_struct/1, [:nombre_usuario, :contrasena]}

  defp especificacion(Epicenter.Recurso),
    do: {:ok, &recurso_a_struct/1, [:codigo, :nombre, :categoria]}

  defp especificacion(Epicenter.Albergue),
    do: {:ok, &albergue_a_struct/1, [:codigo, :nombre, :codigo_zona, :capacidad]}

  defp especificacion(Epicenter.CentroApoyo),
    do: {:ok, &centro_apoyo_a_struct/1, [:codigo, :nombre, :tipo]}

  defp especificacion(Epicenter.Historial),
    do: {:ok, &historial_a_struct/1, [:id, :tipo, :codigo_recurso, :cantidad]}

  defp especificacion(Epicenter.Inventario),
    do: {:ok, &inventario_a_struct/1, [:id, :codigo_recurso, :codigo_centro]}

  defp especificacion(Epicenter.Mascota),
    do: {:ok, &mascota_a_struct/1, [:id, :tipo, :especie, :color, :tamano, :zona, :contacto]}

  defp especificacion(Epicenter.Mensaje),
    do: {:ok, &mensaje_a_struct/1, [:codigo, :remitente, :destinatario, :contenido, :fecha_envio]}

  defp especificacion(Epicenter.Necesidad),
    do: {:ok, &necesidad_a_struct/1, [:id, :codigo_zona, :reportado_por]}

  defp especificacion(Epicenter.Persona),
    do: {:ok, &persona_a_struct/1, [:id, :documento, :nombre, :codigo_zona]}

  defp especificacion(_estructura), do: :error

  defp error_carga(ruta, etapa, razon, registro \\ nil) do
    detalle = %{
      archivo: if(is_binary(ruta), do: Path.expand(ruta), else: ruta),
      etapa: etapa,
      razon: razon
    }

    if is_nil(registro), do: detalle, else: Map.put(detalle, :registro, registro)
  end

  defp guardar_documento(registros, ruta) do
    datos =
      Enum.map(registros, fn registro ->
        if(is_struct(registro), do: Map.from_struct(registro), else: registro)
        |> Map.new(fn {campo, valor} -> {campo, serializar(valor)} end)
      end)

    {:ok, contenido} = Jason.encode(datos, pretty: true)
    File.write!(ruta, contenido)
    registros
  end

  defp serializar(%DateTime{} = fecha), do: DateTime.to_iso8601(fecha)
  defp serializar(%_{} = struct), do: struct |> Map.from_struct() |> serializar()
  defp serializar(valor) when is_list(valor), do: Enum.map(valor, &serializar/1)

  defp serializar(valor) when is_map(valor),
    do: Map.new(valor, fn {clave, dato} -> {clave, serializar(dato)} end)

  defp serializar(valor), do: valor

  defp rol_a_atomos(roles) when is_list(roles), do: Enum.map(roles, &rol_a_atomo/1)
  defp rol_a_atomos(rol), do: rol_a_atomo(rol)

  defp rol_a_atomo("ciudadano"), do: :ciudadano
  defp rol_a_atomo("voluntario"), do: :voluntario
  defp rol_a_atomo("coordinar"), do: :coordinar
  defp rol_a_atomo("administrador"), do: :administrador
  defp rol_a_atomo(rol) when rol in [:ciudadano, :voluntario, :coordinar, :administrador], do: rol
  defp rol_a_atomo(_rol), do: :ciudadano

  defp a_atomo_existente(valor) when is_binary(valor) do
    String.to_existing_atom(valor)
  rescue
    ArgumentError -> valor
  end

  defp a_atomo_existente(valor), do: valor

  defp asignacion_a_mapa(%{"recurso" => recurso, "cantidad" => cantidad}),
    do: %{recurso: recurso, cantidad: cantidad}

  defp asignacion_a_mapa(%{recurso: recurso, cantidad: cantidad}),
    do: %{recurso: recurso, cantidad: cantidad}

  defp asignacion_a_mapa(asignacion),
    do: raise(ArgumentError, "asignación de necesidad inválida: #{inspect(asignacion)}")

  # El historial de una persona se guarda como lista de mapas; al cargarlo se
  # recuperan los átomos y las fechas. Lo que no tenga esa forma se deja igual.
  defp historial_a_lista(entradas) when is_list(entradas),
    do: Enum.map(entradas, &entrada_historial_persona/1)

  defp historial_a_lista(otro), do: otro

  defp entrada_historial_persona(%{"estado" => estado} = entrada) do
    %{
      fecha: a_datetime(entrada["fecha"]),
      estado: a_atomo_existente(estado),
      por: entrada["por"]
    }
  end

  defp entrada_historial_persona(otra), do: otra

  defp mascota_estado(nil), do: :activa

  defp mascota_estado(estado) when estado in [:activa, :posible_coincidencia, :resuelta],
    do: estado

  defp mascota_estado(estado) when is_binary(estado) do
    case Enum.find(Epicenter.Mascota.estados(), &(Atom.to_string(&1) == estado)) do
      nil -> raise ArgumentError, "estado de mascota inválido: #{inspect(estado)}"
      atom -> atom
    end
  end

  defp mascota_estado(estado) do
    raise ArgumentError, "estado de mascota inválido: #{inspect(estado)}"
  end

  defp a_datetime(valor) when is_binary(valor) do
    case DateTime.from_iso8601(valor) do
      {:ok, fecha, _offset} ->
        fecha

      {:error, _razon} ->
        valor
    end
  end

  defp a_datetime(valor), do: valor

  def guardar_usuarios(usuarios) do
    list =
      Enum.map(usuarios, fn u ->
        Map.from_struct(u) |> Map.put(:contrasena, to_string(u.contrasena))
      end)

    {:ok, data} = Jason.encode(list, pretty: true)
    File.write!(ruta_datos("Usuario.json"), data)
    usuarios
  end

  def guardar_zonas(zonas) do
    lista = Enum.map(Map.values(zonas), fn zona -> zona_a_mapa(zona) end)
    {:ok, data} = Jason.encode(lista, pretty: true)
    File.write!(ruta_datos("Zonas.json"), data)
    zonas
  end

  defp zona_a_mapa(zona) do
    %{
      codigo: zona.codigo,
      nombre: zona.nombre,
      nivel: zona.nivel,
      sectores: Enum.map(zona.sectores, fn s -> sector_a_mapa(s) end)
    }
  end

  defp sector_a_mapa(sector) do
    %{
      codigo: sector.codigo,
      nombre: sector.nombre,
      nivel: sector.nivel,
      afectadas: sector.afectadas,
      puntos: Enum.map(sector.puntos, fn p -> punto_a_mapa(p) end)
    }
  end

  defp punto_a_mapa(punto), do: %{codigo: punto.codigo, nombre: punto.nombre}

  def carga_zonas do
    case File.read(ruta_datos("Zonas.json")) do
      {:ok, contenido} ->
        lista = JSON.decode!(contenido)
        Map.new(lista, fn mapa -> {mapa["codigo"], mapa_a_zona(mapa)} end)

      {:error, razon} ->
        IO.puts("Error al cargar zonas: #{razon}")
        %{}
    end
  end

  defp mapa_a_zona(mapa) do
    %Zona{
      codigo: mapa["codigo"],
      nombre: mapa["nombre"],
      nivel: nivel_a_atomo(mapa["nivel"]),
      sectores: Enum.map(mapa["sectores"], fn s -> mapa_a_sector(s) end)
    }
  end

  defp mapa_a_sector(mapa) do
    %Sector{
      codigo: mapa["codigo"],
      nombre: mapa["nombre"],
      nivel: nivel_a_atomo(mapa["nivel"]),
      afectadas: mapa["afectadas"],
      puntos: Enum.map(mapa["puntos"], fn p -> mapa_a_punto(p) end)
    }
  end

  defp mapa_a_punto(mapa), do: %PuntoAtencion{codigo: mapa["codigo"], nombre: mapa["nombre"]}

  defp nivel_a_atomo("critico"), do: :critico
  defp nivel_a_atomo("alto"), do: :alto
  defp nivel_a_atomo("medio"), do: :medio
  defp nivel_a_atomo("bajo"), do: :bajo
end
