defmodule InterfazWeb.Router do
  use InterfazWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InterfazWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", InterfazWeb do
    pipe_through :browser

    # connect / disconnect
    get "/conectar", SesionController, :new
    post "/conectar", SesionController, :create
    post "/registrar", SesionController, :registrar
    delete "/desconectar", SesionController, :delete

    live "/", ResumenLive, :index
    live "/zonas", ZonasLive, :index
    live "/necesidades", NecesidadesLive, :index
    live "/recursos", RecursosLive, :index
    live "/personas", PersonasLive, :index
    live "/mascotas", MascotasLive, :index
    live "/albergues", AlberguesLive, :index
    live "/actividad", ActividadLive, :index
  end
end
