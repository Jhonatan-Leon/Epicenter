defmodule Epicenter.GenserverMensaje do
  use GenServer

  @gestor Epicenter.GestorMensaje
  @funciones [
    listar: 0,
    registro: 3,
    registro: 5,
    completar_informacion: 2,
    obtener: 1,
    crear: 1,
    actualizar: 2,
    eliminar: 1,
    enviar: 3,
    listar_por_persona: 1,
    marcar: 2
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])

  def registro(remitente, destinatario, contenido),
    do: solicitar(:registro, [remitente, destinatario, contenido])

  def registro(codigo, remitente, destinatario, contenido, fecha_envio),
    do: solicitar(:registro, [codigo, remitente, destinatario, contenido, fecha_envio])

  def completar_informacion(codigo, estado),
    do: solicitar(:completar_informacion, [codigo, estado])

  def obtener(codigo), do: solicitar(:obtener, [codigo])
  def crear(mensaje), do: solicitar(:crear, [mensaje])
  def actualizar(codigo, mensaje), do: solicitar(:actualizar, [codigo, mensaje])
  def eliminar(codigo), do: solicitar(:eliminar, [codigo])

  def enviar(remitente, documento_destinatario, contenido),
    do: solicitar(:enviar, [remitente, documento_destinatario, contenido])

  def listar_por_persona(documento), do: solicitar(:listar_por_persona, [documento])
  def marcar(codigo, estado), do: solicitar(:marcar, [codigo, estado])

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
