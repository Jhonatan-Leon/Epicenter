defmodule Epicenter.GenserverActividad do
  use GenServer

  alias Epicenter.GestorActividad

  def start_link(_opciones), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  # cast: quien registra no espera a que se escriba la línea
  def registrar(usuario, accion, resultado, detalle \\ ""),
    do: GenServer.cast(__MODULE__, {:registrar, usuario, accion, resultado, detalle})

  def listar, do: GenServer.call(__MODULE__, :listar)
  def de_usuario(usuario), do: GenServer.call(__MODULE__, {:de_usuario, usuario})
  def conectados, do: GenServer.call(__MODULE__, :conectados)

  @impl true
  def init(nil), do: {:ok, nil}

  @impl true
  def handle_cast({:registrar, usuario, accion, resultado, detalle}, estado) do
    GestorActividad.registrar(usuario, accion, resultado, detalle)
    {:noreply, estado}
  end

  @impl true
  def handle_call(:listar, _de, estado), do: {:reply, GestorActividad.listar(), estado}
  def handle_call({:de_usuario, usuario}, _de, estado), do: {:reply, GestorActividad.de_usuario(usuario), estado}
  def handle_call(:conectados, _de, estado), do: {:reply, GestorActividad.conectados(), estado}
end
