defmodule Epicenter.Aplicacion do
  use Application

  @moduledoc """
  Supervisa los procesos principales de Epicenter.
  """

  @impl true
  def start(_type, _args) do
    children = [
      Epicenter.Genserver
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
