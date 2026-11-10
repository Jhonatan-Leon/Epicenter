defmodule Epicenter.GenserverAlbergue do
  use GenServer

  @gestor Epicenter.GestorAlbergue
  @funciones [
    listar: 0,
    registro: 3,
    registrar_ingreso: 2,
    registrar_ingreso: 3,
    registrar_salida: 2,
    cupos: 1,
    completar_informacion: 4,
    obtener: 1,
    crear: 1,
    actualizar: 2,
    eliminar: 1,
    reporte_ocupacion: 0,
    cupos_por_zona: 2
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])

  def registro(nombre, codigo_zona, capacidad),
    do: solicitar(:registro, [nombre, codigo_zona, capacidad])

  def registrar_ingreso(codigo, documento), do: solicitar(:registrar_ingreso, [codigo, documento])

  def registrar_ingreso(codigo, documento, por),
    do: solicitar(:registrar_ingreso, [codigo, documento, por])

  def registrar_salida(codigo, documento), do: solicitar(:registrar_salida, [codigo, documento])
  def cupos(codigo), do: solicitar(:cupos, [codigo])

  def completar_informacion(codigo, ocupantes, recursos, necesidades),
    do: solicitar(:completar_informacion, [codigo, ocupantes, recursos, necesidades])

  def obtener(codigo), do: solicitar(:obtener, [codigo])
  def crear(albergue), do: solicitar(:crear, [albergue])
  def actualizar(codigo, albergue), do: solicitar(:actualizar, [codigo, albergue])
  def eliminar(codigo), do: solicitar(:eliminar, [codigo])
  def reporte_ocupacion, do: solicitar(:reporte_ocupacion, [])
  def cupos_por_zona(albergues, zona), do: solicitar(:cupos_por_zona, [albergues, zona])

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
