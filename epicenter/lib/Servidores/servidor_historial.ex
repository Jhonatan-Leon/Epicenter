defmodule Epicenter.GenserverHistorial do
  use GenServer

  @gestor Epicenter.GestorHistorial
  @funciones [listar: 0, registrar: 5, de_recurso: 1]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])

  def registrar(tipo, codigo_recurso, cantidad, detalle, usuario),
    do: solicitar(:registrar, [tipo, codigo_recurso, cantidad, detalle, usuario])

  def de_recurso(codigo_recurso), do: solicitar(:de_recurso, [codigo_recurso])

  @impl true
  def init(_opts), do: {:ok, nil}

  @impl true
  def handle_call({:ejecutar, funcion, argumentos}, _from, estado)
      when {funcion, length(argumentos)} in @funciones do
    {:reply, apply(@gestor, funcion, argumentos), estado}
  end

  def handle_call(_solicitud, _from, estado),
    do: {:reply, {:error, :operacion_no_soportada}, estado}

  defp solicitar(funcion, argumentos),
    do: GenServer.call(__MODULE__, {:ejecutar, funcion, argumentos})
end
