defmodule InterfazWeb.SesionController do
  use InterfazWeb, :controller

  alias Interfaz.Fuente

  def new(conn, _params) do
    if get_session(conn, :usuario) do
      redirect(conn, to: ~p"/")
    else
      form = Phoenix.Component.to_form(%{"rol" => "ciudadano", "zona" => "centro"}, as: :acceso)
      render(conn, :new, form: form, page_title: "Conectar")
    end
  end

  def create(conn, %{"acceso" => %{"usuario" => usuario, "contrasena" => contrasena} = p})
      when usuario != "" and contrasena != "" do
    rol = Enum.find(Fuente.roles(), :ciudadano, &(to_string(&1) == p["rol"]))

    case Fuente.conectar(String.trim(usuario), contrasena, rol, p["zona"]) do
      {:ok, sesion} ->
        conn
        |> configure_session(renew: true)
        |> put_session(:usuario, sesion)
        |> put_flash(:info, "Bienvenido, #{sesion.nombre}.")
        |> redirect(to: ~p"/")

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

  def delete(conn, _params) do
    if usuario = get_session(conn, :usuario), do: Fuente.desconectar(usuario)

    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/conectar")
  end
end
