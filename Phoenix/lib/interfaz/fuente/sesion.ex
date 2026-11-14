defmodule Interfaz.Fuente.Sesion do
  @moduledoc """
  Conexión y registro de usuarios, siempre a través de `Epicenter.Genserver`
  (lo arranca el supervisor de la lógica). Varias conexiones al mismo tiempo
  pasan por ese único proceso, una después de otra.
  """

  import Interfaz.Fuente.Comun, only: [limpiar: 1]

  alias Interfaz.Fuente.Zonas

  @usuario_min 3
  @usuario_max 20
  @contrasena_min 4
  @nombre_min 3
  @nombre_max 60

  @doc """
  Comando `connect`. Si el usuario existe valida la contraseña y devuelve
  `{:ok, sesion}`; si no existe devuelve `:nuevo` para pedir el resto de datos.
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
  Registra un usuario nuevo en dos pasos por el GenServer: `crear/2` hace el
  usuario básico y `actualizar/2` le pone rol, nombre completo y zona.
  La zona se guarda por nombre ("Sur"); la sesión usa su código.
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

  @doc "Comando `disconnect`."
  def desconectar(_usuario), do: :ok

  defp usuario_existe?(usuario),
    do: match?({:ok, _usuario}, Epicenter.Genserver.obtener(usuario))

  defp sesion(u, rol, zona) do
    %{
      usuario: u.nombre_usuario,
      nombre: u.nombre_completo || u.nombre_usuario,
      rol: rol,
      zona: zona
    }
  end

  # La lógica usa :coordinar; la interfaz usa :coordinador.
  defp rol_interfaz(:coordinar), do: :coordinador
  defp rol_interfaz(rol) when rol in [:ciudadano, :voluntario, :administrador], do: rol
  defp rol_interfaz(_rol), do: :ciudadano

  # ---------------------------------------------------------------------------
  # Validaciones de la pantalla de conexión: cada una devuelve :ok o {:error, mensaje}.
  # ---------------------------------------------------------------------------

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

  defp validar_contrasena_nueva(contrasena) do
    with :ok <- validar_contrasena(contrasena) do
      if String.length(contrasena) < @contrasena_min,
        do: {:error, "La contraseña debe tener al menos #{@contrasena_min} caracteres."},
        else: :ok
    end
  end

  defp validar_rol_registro(rol) do
    case Enum.find(roles_registro(), &(to_string(&1) == to_string(rol))) do
      nil -> {:error, "Al registrarte solo puedes ser ciudadano o voluntario."}
      rol -> {:ok, rol}
    end
  end

  defp validar_nombre_completo(""), do: {:error, "Escribe tu nombre completo."}

  defp validar_nombre_completo(nombre) do
    if String.length(nombre) < @nombre_min or String.length(nombre) > @nombre_max,
      do:
        {:error,
         "El nombre completo debe tener entre #{@nombre_min} y #{@nombre_max} caracteres."},
      else: :ok
  end

  defp validar_usuario_libre(usuario) do
    if usuario_existe?(usuario),
      do: {:error, "Ese usuario ya existe. Conéctate con tu contraseña."},
      else: :ok
  end

  # La zona principal se guarda por nombre; también se acepta un código.
  # Si no coincide con ninguna zona, se usa la primera.
  defp codigo_zona(valor) do
    zonas = Zonas.zonas()

    case Enum.find(zonas, &(&1.nombre == valor or &1.codigo == valor)) do
      nil -> if zonas == [], do: nil, else: hd(zonas).codigo
      zona -> zona.codigo
    end
  end

  defp buscar_zona_por_nombre(nombre) do
    case Enum.find(Zonas.zonas(), &(&1.nombre == nombre)) do
      nil -> {:error, "Zona no válida."}
      zona -> {:ok, zona}
    end
  end
end
