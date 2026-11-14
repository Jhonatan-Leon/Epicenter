defmodule Epicenter.GenserverZona do
  use GenServer

  @gestor Epicenter.GestorZona
  @funciones [listar: 1, obtener: 2, crear: 2, actualizar: 3, eliminar: 2]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar(zonas), do: solicitar(:listar, [zonas])
  def obtener(zonas, codigo), do: solicitar(:obtener, [zonas, codigo])
  def crear(zonas, zona), do: solicitar(:crear, [zonas, zona])
  def actualizar(zonas, codigo, zona), do: solicitar(:actualizar, [zonas, codigo, zona])
  def eliminar(zonas, codigo), do: solicitar(:eliminar, [zonas, codigo])

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
