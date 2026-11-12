defmodule InterfazWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use InterfazWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Estructura principal: barra lateral con la navegación permitida para el rol,
  barra superior con el usuario conectado y el área de contenido.
  """
  attr :flash, :map, required: true
  attr :usuario, :map, required: true
  attr :activo, :atom, default: nil
  slot :inner_block, required: true

  def app(assigns) do
    assigns = assign(assigns, :menu, InterfazWeb.Sesion.navegacion(assigns.usuario.rol))

    ~H"""
    <div class="sx-app drawer lg:drawer-open" data-escena="sala">
      <input id="menu-lateral" type="checkbox" class="drawer-toggle" />
      <div class="drawer-content flex min-h-screen flex-col">
        <header class="sx-barra sticky top-0 z-20 flex items-center gap-3 px-4 py-2.5 sm:px-6">
          <label
            for="menu-lateral"
            class="btn btn-ghost btn-square btn-sm lg:hidden"
            aria-label="Abrir menú"
          >
            <.icon name="hero-bars-3" class="size-5" />
          </label>

          <div class="flex items-center gap-2.5 lg:hidden">
            <.marca />
          </div>

          <div
            id="sx-pulso"
            phx-update="ignore"
            class="sx-pulso hidden items-center gap-3 md:flex"
            title="Pulso de la interfaz: reacciona a tu actividad"
          >
            <span class="sx-etiqueta flex items-center gap-2">
              <span class="sx-punto"></span> En vivo
            </span>
            <canvas id="sx-sismografo" aria-hidden="true"></canvas>
            <span id="sx-reloj" class="sx-reloj">--:--:--</span>
          </div>

          <div class="ml-auto flex items-center gap-3">
            <.boton_movimiento />
            <.theme_toggle />
            <div class="hidden text-right sm:block">
              <p class="text-sm font-semibold leading-tight">{@usuario.nombre}</p>

              <p class="sx-etiqueta mt-0.5">
                {InterfazWeb.UI.t(@usuario.rol)} · {InterfazWeb.UI.zona(@usuario.zona)}
              </p>
            </div>

            <div class="sx-marca-icono sx-marca-quieta">
              <span class="text-sm font-bold uppercase">{String.first(@usuario.nombre)}</span>
            </div>

            <.link
              href={~p"/desconectar"}
              method="delete"
              class="btn btn-ghost btn-sm"
              title="Desconectar"
            >
              <.icon name="hero-arrow-right-start-on-rectangle" class="size-5" />
              <span class="hidden md:inline">Salir</span>
            </.link>
          </div>
        </header>

        <main class="flex-1 px-4 py-8 sm:px-6 lg:px-10">
          <div class="sx-contenido mx-auto max-w-7xl">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <div class="drawer-side z-30">
        <label for="menu-lateral" class="drawer-overlay" aria-label="Cerrar menú"></label>
        <aside class="sx-lateral flex min-h-full w-64 flex-col">
          <div class="flex items-center gap-2.5 px-5 py-5">
            <.marca />
          </div>

          <p class="sx-etiqueta px-5 pb-2 pt-3">Coordinación</p>

          <nav class="flex-1 px-3" aria-label="Secciones">
            <ul class="sx-escalonar space-y-1">
              <li :for={{item, i} <- Enum.with_index(@menu, 1)}>
                <.link
                  navigate={item.ruta}
                  class={["sx-nav-item", item.clave == @activo && "sx-nav-activo"]}
                  aria-current={item.clave == @activo && "page"}
                >
                  <span class="sx-nav-num">{String.pad_leading(Integer.to_string(i), 2, "0")}</span>
                  <.icon name={item.icono} class="size-5 transition-colors" />
                  <span class="flex-1">{item.texto}</span>
                </.link>
              </li>
            </ul>
          </nav>

          <div class="sx-card m-3 p-3 text-xs">
            <p class="sx-etiqueta flex items-center gap-2">
              <span class="sx-punto"></span> Sesión activa
            </p>

            <p class="mt-1.5 font-medium">{@usuario.usuario} · {InterfazWeb.UI.t(@usuario.rol)}</p>
          </div>
        </aside>
      </div>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  @doc "Logotipo y nombre del sistema."
  def marca(assigns) do
    ~H"""
    <span class="sx-marca-icono">
      <svg
        viewBox="0 0 24 24"
        class="size-5"
        fill="none"
        stroke="currentColor"
        stroke-width="2.2"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <path d="M2 12h4l2-5 3 10 3-14 2 9h6" />
      </svg>
    </span>
    <span class="sx-marca-texto">Epicenter</span>
    """
  end

  @doc """
  Activa o reduce las animaciones de la interfaz. La preferencia se guarda en
  el navegador (ver `assets/js/sismo.js`).
  """
  def boton_movimiento(assigns) do
    ~H"""
    <button
      type="button"
      class="sx-movimiento btn btn-ghost btn-square btn-sm"
      data-sx-movimiento
      title="Activar o reducir animaciones"
      aria-label="Activar o reducir animaciones"
    >
      <.icon name="hero-sparkles" class="size-5" />
    </button>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        autocerrar={false}
        title="Sin conexión"
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Intentando reconectar
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        autocerrar={false}
        title="Algo salió mal"
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Intentando reconectar
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="Tema del sistema"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Tema claro"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Tema oscuro"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
