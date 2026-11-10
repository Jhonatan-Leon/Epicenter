defmodule Epicenter.GenserverInventario do
  use GenServer

  @gestor Epicenter.GestorInventario
  @funciones [
    listar: 0,
    registro: 2,
    registro: 4,
    completar_informacion: 3,
    obtener: 1,
    crear: 1,
    actualizar: 2,
    eliminar: 1
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])

  def registro(codigo_recurso, codigo_centro),
    do: solicitar(:registro, [codigo_recurso, codigo_centro])

  def registro(codigo_recurso, codigo_centro, zonas, cantidad_disponible),
    do: solicitar(:registro, [codigo_recurso, codigo_centro, zonas, cantidad_disponible])

  def completar_informacion(id, zonas, cantidad_disponible),
    do: solicitar(:completar_informacion, [id, zonas, cantidad_disponible])

  def obtener(id), do: solicitar(:obtener, [id])
  def crear(inventario), do: solicitar(:crear, [inventario])
  def actualizar(id, inventario), do: solicitar(:actualizar, [id, inventario])
  def eliminar(id), do: solicitar(:eliminar, [id])

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
