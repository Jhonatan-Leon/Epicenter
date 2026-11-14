defmodule Epicenter.Autorizacion do
  @moduledoc """
  Verifica permisos usando el rol y la zona guardados para el usuario.

  Los módulos de dominio contienen las operaciones; los puntos de entrada
  (servidores o adaptadores web) deben invocarlas mediante `ejecutar/4`.
  """

  alias Epicenter.{GestorUsuario, Persistencia}

  @roles [:ciudadano, :voluntario, :coordinar, :administrador]
  @todos @roles
  @operativos [:voluntario, :coordinar, :administrador]
  @coordinacion [:coordinar, :administrador]
  @administracion [:administrador]

  @permisos %{
    consultar_necesidades: @todos,
    registrar_necesidad: @todos,
    registrar_necesidad_critica: @coordinacion,
    actualizar_necesidad: @operativos,
    priorizar_necesidad: @coordinacion,
    cambiar_estado_necesidad: @coordinacion,
    asignar_recurso: @coordinacion,
    consultar_recursos: @operativos,
    gestionar_recursos: @operativos,
    transferir_recursos: @operativos,
    consultar_zonas: @todos,
    gestionar_zonas: @coordinacion,
    registrar_sector: @coordinacion,
    registrar_punto_atencion: @coordinacion,
    consultar_albergues: @todos,
    registrar_albergue: @administracion,
    registrar_ingreso_albergue: @operativos,
    registrar_salida_albergue: @operativos,
    consultar_estadisticas_albergues: @coordinacion,
    consultar_personas: @todos,
    registrar_persona: @todos,
    actualizar_persona: @operativos,
    consultar_mensajes: @todos,
    enviar_mensaje: @todos,
    marcar_mensaje: @todos,
    consultar_mascotas: @todos,
    reportar_mascota: @todos,
    actualizar_mascota: @operativos,
    validar_coincidencias_mascotas: @coordinacion,
    administrar_usuarios: @administracion,
    administrar_configuracion: @administracion,
    supervisar_emergencia: @coordinacion
  }

  @acciones_por_zona [
    :registrar_necesidad_critica,
    :priorizar_necesidad,
    :cambiar_estado_necesidad,
    :asignar_recurso,
    :gestionar_zonas,
    :registrar_sector,
    :registrar_punto_atencion,
    :gestionar_recursos,
    :transferir_recursos,
    :registrar_ingreso_albergue,
    :registrar_salida_albergue,
    :consultar_estadisticas_albergues,
    :actualizar_persona,
    :actualizar_mascota,
    :validar_coincidencias_mascotas,
    :supervisar_emergencia
  ]

  @doc "Lista los permisos definidos para un rol reconocido."
  def permisos(rol) do
    case normalizar_rol(rol) do
      {:ok, rol} ->
        @permisos
        |> Enum.filter(fn {_permiso, roles} -> rol in roles end)
        |> Enum.map(&elem(&1, 0))
        |> Enum.sort()

      :error ->
        []
    end
  end

  @doc "Indica si un rol puede realizar una acción, sin autenticar a un usuario."
  def puede?(rol, accion) do
    with {:ok, rol} <- normalizar_rol(rol),
         roles when is_list(roles) <- Map.get(@permisos, accion) do
      rol in roles
    else
      _ -> false
    end
  end

  @doc """
  Autoriza una acción consultando el rol persistido del usuario.

  Para acciones de coordinación se debe indicar la zona objetivo. Un
  coordinador solo puede operar en la zona asignada a su cuenta.
  """
  def autorizar(nombre_usuario, accion, codigo_zona \\ nil)

  def autorizar(nombre_usuario, accion, codigo_zona)
      when is_binary(nombre_usuario) and is_atom(accion) do
    case GestorUsuario.obtener(nombre_usuario) do
      {:ok, usuario} ->
        with true <- puede?(usuario.rol, accion),
             :ok <- verificar_zona(usuario, accion, codigo_zona) do
          {:ok, usuario}
        else
          false -> {:error, :permiso_denegado}
          {:error, razon} -> {:error, razon}
        end

      {:error, "Usuario no encontrado"} ->
        {:error, :usuario_no_autenticado}

      {:error, razon} ->
        {:error, {:no_se_pudo_verificar_usuario, razon}}
    end
  end

  def autorizar(_nombre_usuario, _accion, _codigo_zona),
    do: {:error, :usuario_no_autenticado}

  @doc """
  Ejecuta una operación solo después de verificar permisos y ámbito de zona.

  La función recibe el usuario recuperado del backend, no un rol provisto por
  el cliente.
  """
  def ejecutar(nombre_usuario, accion, codigo_zona, funcion)
      when is_function(funcion, 1) do
    with {:ok, usuario} <- autorizar(nombre_usuario, accion, codigo_zona) do
      funcion.(usuario)
    end
  end

  defp verificar_zona(usuario, accion, codigo_zona) do
    case normalizar_rol(usuario.rol) do
      {:ok, :administrador} ->
        :ok

      {:ok, :coordinar} when accion in @acciones_por_zona ->
        verificar_zona_asignada(usuario.zona_principal, codigo_zona)

      _ ->
        :ok
    end
  end

  defp verificar_zona_asignada(_zona_asignada, nil), do: {:error, :zona_requerida}
  defp verificar_zona_asignada(nil, _codigo_zona), do: {:error, :zona_no_asignada}

  defp verificar_zona_asignada(zona_asignada, codigo_zona) do
    zonas = Persistencia.carga_zonas()

    zona_asignada_codigo = normalizar_zona(zonas, zona_asignada)
    objetivo_codigo = normalizar_zona(zonas, codigo_zona)

    cond do
      is_nil(zona_asignada_codigo) -> {:error, :zona_no_asignada}
      is_nil(objetivo_codigo) -> {:error, :zona_no_encontrada}
      zona_asignada_codigo == objetivo_codigo -> :ok
      true -> {:error, :fuera_de_zona}
    end
  end

  defp normalizar_zona(zonas, valor) do
    Enum.find_value(zonas, fn {codigo, zona} ->
      if valor in [codigo, zona.codigo, zona.nombre], do: codigo
    end)
  end

  defp normalizar_rol(:coordinador), do: {:ok, :coordinar}
  defp normalizar_rol(rol) when rol in @roles, do: {:ok, rol}

  defp normalizar_rol(rol) when is_binary(rol) do
    case Enum.find(@roles, &(Atom.to_string(&1) == rol)) do
      :coordinar -> {:ok, :coordinar}
      nil -> if rol == "coordinador", do: {:ok, :coordinar}, else: :error
      rol -> {:ok, rol}
    end
  end

  defp normalizar_rol(_rol), do: :error
end
