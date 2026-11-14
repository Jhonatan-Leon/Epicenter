defmodule Epicenter.Aplicacion do
  use Application

  @moduledoc """
  Supervisa los procesos principales del dominio Epicenter.
  """

  @impl true
  def start(_tipo, _argumentos) do
    hijos = [
      {Epicenter.Genserver, []},
      {Epicenter.GenserverPersona, []},
      {Epicenter.GenserverZona, []},
      {Epicenter.GenserverNecesidad, []},
      {Epicenter.GenserverAlbergue, []},
      {Epicenter.GenserverCentroApoyo, []},
      {Epicenter.GenserverHistorial, []},
      {Epicenter.GenserverInventario, []},
      {Epicenter.GenserverMascota, []},
      {Epicenter.GenserverMensaje, []},
      {Epicenter.GenserverRecurso, []},
      {Epicenter.GenserverZonas, []}
    ]

    # Estrategia one_for_one: si un proceso hijo falla, solo se reinicia ese hijo.
    Supervisor.start_link(hijos, strategy: :one_for_one, name: Epicenter.Supervisor)
  end
end
