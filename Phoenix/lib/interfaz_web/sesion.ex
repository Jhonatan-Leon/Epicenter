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

  def administra?(%{rol: :administrador}), do: true
  def administra?(_), do: false

  def on_mount({:pagina, clave}, _params, session, socket) do
    case session["usuario"] do
      %{usuario: nombre_usuario} when is_binary(nombre_usuario) ->
        case Epicenter.GestorUsuario.obtener(nombre_usuario) do
          {:ok, usuario_backend} ->
            zonas = Interfaz.Fuente.zonas()
            zonas_por_codigo = Map.new(zonas, &{&1.codigo, &1.nombre})
            usuario = usuario_sesion(usuario_backend, zonas)

            if Enum.any?(navegacion(usuario.rol), &(&1.clave == clave)) do
              {:cont,
               socket
               |> assign(:usuario, usuario)
               |> assign(:activo, clave)
               |> assign(:zonas_catalogo, zonas)
               |> assign(:zonas_por_codigo, zonas_por_codigo)
               |> assign(:opciones_zonas, Enum.map(zonas, &{&1.nombre, &1.codigo}))}
            else
              {:halt,
               socket
               |> put_flash(:error, "Tu rol no tiene acceso a esa sección.")
               |> redirect(to: ~p"/")}
            end

          {:error, _razon} ->
            {:halt, redirect(socket, to: ~p"/conectar")}
        end

      _sin_usuario ->
        {:halt, redirect(socket, to: ~p"/conectar")}
    end
  end

  defp usuario_sesion(usuario_backend, zonas) do
    zona =
      Enum.find(zonas, fn zona ->
        usuario_backend.zona_principal in [zona.codigo, zona.nombre]
      end)

    %{
      usuario: usuario_backend.nombre_usuario,
      nombre: usuario_backend.nombre_completo || usuario_backend.nombre_usuario,
      rol: rol_interfaz(usuario_backend.rol),
      zona: if(zona, do: zona.codigo)
    }
  end

  defp rol_interfaz(:coordinar), do: :coordinador
  defp rol_interfaz(rol) when rol in [:ciudadano, :voluntario, :administrador], do: rol
  defp rol_interfaz(_rol), do: :ciudadano
end
