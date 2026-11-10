defmodule Epicenter.Aplicacion do
  use Application

  @impl true
  def start(_tipo, _argumentos) do
    hijos = [
      Epicenter.Genserver,
      Epicenter.GenserverAlbergue,
      Epicenter.GenserverCentroApoyo,
      Epicenter.GenserverHistorial,
      Epicenter.GenserverInventario,
      Epicenter.GenserverMascota,
      Epicenter.GenserverMensaje,
      Epicenter.GenserverNecesidad,
      Epicenter.GenserverPersona,
      Epicenter.GenserverRecurso,
      Epicenter.GenserverZona,
      Epicenter.GenserverZonas
    ]

    Supervisor.start_link(hijos, strategy: :one_for_one, name: Epicenter.Supervisor)
  end
end
