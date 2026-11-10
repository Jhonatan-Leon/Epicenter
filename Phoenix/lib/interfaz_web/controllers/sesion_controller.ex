defmodule InterfazWeb.SesionController do
  use InterfazWeb, :controller

  alias Interfaz.Fuente

  def new(conn, _params) do
    if get_session(conn, :usuario) do
      redirect(conn, to: ~p"/")
    else
      mostrar_conexion(conn)
    end
  end

  # Paso 1: usuario y contraseña. Las validaciones están en Interfaz.Fuente.
  def create(conn, %{"acceso" => %{"usuario" => usuario, "contrasena" => contrasena}}) do
    case Fuente.conectar(usuario, contrasena) do
      {:ok, sesion} ->
        entrar(conn, sesion, "Bienvenido, #{sesion.nombre}.")

      :nuevo ->
        datos = %{
          "usuario" => String.trim(usuario),
          "contrasena" => contrasena,
          "rol" => "ciudadano",
          "zona" => "centro"
        }

        mostrar_registro(conn, datos)

      {:error, motivo} ->
        conn
        |> put_flash(:error, to_string(motivo))
        |> redirect(to: ~p"/conectar")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Escribe tu usuario y tu contraseña.")
    |> redirect(to: ~p"/conectar")
  end

  # Paso 2: solo para usuarios nuevos, eligen tipo de usuario y zona.
  def registrar(conn, %{"registro" => datos}) do
    case Fuente.registrar(datos["usuario"], datos["contrasena"], datos["rol"], datos["zona"]) do
      {:ok, sesion} ->
        entrar(conn, sesion, "Cuenta creada. Bienvenido, #{sesion.nombre}.")

      {:error, motivo} ->
        conn
        |> put_flash(:error, to_string(motivo))
        |> mostrar_registro(datos)
    end
  end

  def registrar(conn, _params), do: redirect(conn, to: ~p"/conectar")

  def delete(conn, _params) do
    if usuario = get_session(conn, :usuario), do: Fuente.desconectar(usuario)

    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/conectar")
  end

  defp entrar(conn, sesion, mensaje) do
    conn
    |> configure_session(renew: true)
    |> put_session(:usuario, sesion)
    |> put_flash(:info, mensaje)
    |> redirect(to: ~p"/")
  end

  defp mostrar_conexion(conn) do
    form = Phoenix.Component.to_form(%{}, as: :acceso)
    render(conn, :new, form: form, nuevo: false, page_title: "Conectar")
  end

  defp mostrar_registro(conn, datos) do
    form = Phoenix.Component.to_form(datos, as: :registro)
    render(conn, :new, form: form, nuevo: true, page_title: "Completa tu registro")
  end
end
