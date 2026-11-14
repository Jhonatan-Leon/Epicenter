defmodule Epicenter.GenserverCentroApoyo do
  use GenServer

  @gestor Epicenter.GestorCentroApoyo
  @funciones [
    listar: 0,
    registro: 2,
    registro: 3,
    completar_informacion: 2,
    obtener: 1,
    crear: 1,
    actualizar: 2,
    eliminar: 1
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])
  def registro(nombre, tipo), do: solicitar(:registro, [nombre, tipo])
  def registro(nombre, tipo, codigo_zona), do: solicitar(:registro, [nombre, tipo, codigo_zona])

  def completar_informacion(codigo, codigo_zona),
    do: solicitar(:completar_informacion, [codigo, codigo_zona])

  def obtener(codigo), do: solicitar(:obtener, [codigo])
  def crear(centro), do: solicitar(:crear, [centro])
  def actualizar(codigo, centro), do: solicitar(:actualizar, [codigo, centro])
  def eliminar(codigo), do: solicitar(:eliminar, [codigo])

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
