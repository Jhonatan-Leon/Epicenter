defmodule Epicenter.GenserverNecesidad do
  use GenServer

  @gestor Epicenter.GestorNecesidad
  @funciones [
    listar: 0,
    registrar: 6,
    registrar: 7,
    consultar: 0,
    consultar: 1,
    pendientes: 0,
    cambiar_estado: 2,
    asignar_recurso: 3,
    ordenar_por_prioridad: 1
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])

  def registrar(zona, reportado_por, tipo, descripcion, cantidad, prioridad),
    do: solicitar(:registrar, [zona, reportado_por, tipo, descripcion, cantidad, prioridad])

  def registrar(zona, reportado_por, tipo, descripcion, cantidad, prioridad, destino),
    do:
      solicitar(:registrar, [zona, reportado_por, tipo, descripcion, cantidad, prioridad, destino])

  def consultar, do: solicitar(:consultar, [])
  def consultar(filtros), do: solicitar(:consultar, [filtros])
  def pendientes, do: solicitar(:pendientes, [])
  def cambiar_estado(id, estado), do: solicitar(:cambiar_estado, [id, estado])

  def asignar_recurso(id, codigo_recurso, cantidad),
    do: solicitar(:asignar_recurso, [id, codigo_recurso, cantidad])

  def ordenar_por_prioridad(necesidades), do: solicitar(:ordenar_por_prioridad, [necesidades])

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
