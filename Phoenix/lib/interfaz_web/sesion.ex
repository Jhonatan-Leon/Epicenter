defmodule InterfazWeb.Sesion do
  @moduledoc """
  Sesión de la interfaz: navegación visible por rol y protección de las vistas.

  Solo decide qué se muestra en pantalla. La restricción real de operaciones
  por rol corresponde a la lógica del sistema.
  """
  use InterfazWeb, :verified_routes
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 3]

  @todos [:ciudadano, :voluntario, :coordinador, :administrador]
  @gestion [:voluntario, :coordinador, :administrador]

  @navegacion [
    %{clave: :resumen, texto: "Resumen", icono: "hero-squares-2x2", ruta: "/", roles: @todos},
    %{clave: :zonas, texto: "Zonas", icono: "hero-map", ruta: "/zonas", roles: @todos},
    %{
      clave: :necesidades,
      texto: "Necesidades",
      icono: "hero-lifebuoy",
      ruta: "/necesidades",
      roles: @todos
    },
    %{
      clave: :recursos,
      texto: "Recursos",
      icono: "hero-cube",
      ruta: "/recursos",
      roles: @gestion
    },
    %{
      clave: :personas,
      texto: "Personas y mensajes",
      icono: "hero-user-group",
      ruta: "/personas",
      roles: @todos
    },
    %{clave: :mascotas, texto: "Mascotas", icono: "hero-heart", ruta: "/mascotas", roles: @todos},
    %{
      clave: :albergues,
      texto: "Albergues",
      icono: "hero-home-modern",
      ruta: "/albergues",
      roles: @todos
    },
    %{
      clave: :actividad,
      texto: "Usuarios y actividad",
      icono: "hero-clipboard-document-list",
      ruta: "/actividad",
      roles: [:coordinador, :administrador]
    }
  ]

  def navegacion(rol), do: Enum.filter(@navegacion, &(rol in &1.roles))

  @doc "¿El rol puede gestionar (crear, asignar, transferir)?"
  def gestiona?(%{rol: rol}), do: rol in @gestion
  def gestiona?(_), do: false

  def coordina?(%{rol: rol}), do: rol in [:coordinador, :administrador]
  def coordina?(_), do: false

  def on_mount({:pagina, clave}, _params, session, socket) do
    case session["usuario"] do
      nil ->
        {:halt, redirect(socket, to: ~p"/conectar")}

      usuario ->
        usuario = %{usuario | rol: String.to_existing_atom(to_string(usuario.rol))}

        if Enum.any?(navegacion(usuario.rol), &(&1.clave == clave)) do
          {:cont, socket |> assign(:usuario, usuario) |> assign(:activo, clave)}
        else
          {:halt,
           socket
           |> put_flash(:error, "Tu rol no tiene acceso a esa sección.")
           |> redirect(to: ~p"/")}
        end
    end
  end
end
