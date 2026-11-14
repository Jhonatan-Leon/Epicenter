defmodule Epicenter.GenserverZonas do
  use GenServer

  @gestor Epicenter.GestorZonas
  @funciones [
    registrar: 3,
    obtener: 2,
    cambiar_nivel: 3,
    eliminar: 2,
    listar: 1,
    registrar_sector: 5,
    registrar_punto: 4,
    estadisticas: 2
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def registrar(zonas, nombre, nivel), do: solicitar(:registrar, [zonas, nombre, nivel])
  def obtener(zonas, codigo), do: solicitar(:obtener, [zonas, codigo])
  def cambiar_nivel(zonas, codigo, nivel), do: solicitar(:cambiar_nivel, [zonas, codigo, nivel])
  def eliminar(zonas, codigo), do: solicitar(:eliminar, [zonas, codigo])
  def listar(zonas), do: solicitar(:listar, [zonas])

  def registrar_sector(zonas, codigo_zona, nombre, nivel, afectadas),
    do: solicitar(:registrar_sector, [zonas, codigo_zona, nombre, nivel, afectadas])

  def registrar_punto(zonas, codigo_zona, codigo_sector, nombre),
    do: solicitar(:registrar_punto, [zonas, codigo_zona, codigo_sector, nombre])

  def estadisticas(zonas, codigo_zona), do: solicitar(:estadisticas, [zonas, codigo_zona])

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
