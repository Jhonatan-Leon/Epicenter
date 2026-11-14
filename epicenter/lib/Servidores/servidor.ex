defmodule Epicenter.Genserver do
  use GenServer

  @doc """
  Inicia el servidor de usuarios.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def listar, do: GenServer.call(__MODULE__, :listar)

  def login(nombre_usuario, contrasena),
    do: GenServer.call(__MODULE__, {:login, nombre_usuario, contrasena})

  def obtener(nombre_usuario),
    do: GenServer.call(__MODULE__, {:obtener, nombre_usuario})

  def crear(nombre_usuario, contrasena),
    do: GenServer.call(__MODULE__, {:crear, nombre_usuario, contrasena})

  def actualizar(nombre_usuario, usuario),
    do: GenServer.call(__MODULE__, {:actualizar, nombre_usuario, usuario})

  def eliminar(nombre_usuario),
    do: GenServer.call(__MODULE__, {:eliminar, nombre_usuario})

  @impl true
  def init(_opts), do: {:ok, nil}

  @impl true
  def handle_call(:listar, _from, state) do
    {:reply, Epicenter.GestorUsuario.listar(), state}
  end

  def handle_call({:login, nombre_usuario, contrasena}, _from, state) do
    resultado = Epicenter.GestorUsuario.login(nombre_usuario, contrasena, [])
    {:reply, resultado, state}
  end

  def handle_call({:obtener, nombre_usuario}, _from, state) do
    {:reply, Epicenter.GestorUsuario.obtener(nombre_usuario), state}
  end

  def handle_call({:crear, nombre_usuario, contrasena}, _from, state) do
    {:reply, Epicenter.GestorUsuario.registro([], nombre_usuario, contrasena), state}
  end

  def handle_call({:actualizar, nombre_usuario, usuario}, _from, state) do
    {:reply, Epicenter.GestorUsuario.actualizar(nombre_usuario, usuario), state}
  end

  def handle_call({:eliminar, nombre_usuario}, _from, state) do
    {:reply, Epicenter.GestorUsuario.eliminar(nombre_usuario), state}
  end
end
