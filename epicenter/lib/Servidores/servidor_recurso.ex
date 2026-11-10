defmodule Epicenter.GenserverRecurso do
  use GenServer

  @gestor Epicenter.GestorRecurso
  @funciones [
    listar: 0,
    obtener: 1,
    registrar: 2,
    registrar_entrada: 3,
    registrar_salida: 4,
    asignar_a_necesidad: 4,
    transferir: 4,
    de_zona: 1,
    criticos: 0
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])
  def obtener(codigo), do: solicitar(:obtener, [codigo])
  def registrar(datos, usuario), do: solicitar(:registrar, [datos, usuario])

  def registrar_entrada(codigo, cantidad, usuario),
    do: solicitar(:registrar_entrada, [codigo, cantidad, usuario])

  def registrar_salida(codigo, cantidad, motivo, usuario),
    do: solicitar(:registrar_salida, [codigo, cantidad, motivo, usuario])

  def asignar_a_necesidad(codigo, id_necesidad, cantidad, usuario),
    do: solicitar(:asignar_a_necesidad, [codigo, id_necesidad, cantidad, usuario])

  def transferir(codigo, cantidad, destino, usuario),
    do: solicitar(:transferir, [codigo, cantidad, destino, usuario])

  def de_zona(codigo_zona), do: solicitar(:de_zona, [codigo_zona])
  def criticos, do: solicitar(:criticos, [])

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
