defmodule Epicenter.GenserverPersona do
  use GenServer

  @gestor Epicenter.GestorPersona
  @funciones [
    listar: 0,
    registro: 5,
    registro: 8,
    completar_informacion: 4,
    obtener: 1,
    crear: 1,
    actualizar: 2,
    eliminar: 1,
    reportar_persona: 5,
    reportar_persona: 6,
    obtener_por_documento: 1,
    buscar: 0,
    buscar: 1,
    cambiar_estado: 2,
    cambiar_estado: 3,
    historial: 1
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])

  def registro(documento, tipo_documento, nombre, zona, albergue),
    do: solicitar(:registro, [documento, tipo_documento, nombre, zona, albergue])

  def registro(documento, tipo_documento, nombre, edad, zona, estado, albergue, historial),
    do:
      solicitar(:registro, [
        documento,
        tipo_documento,
        nombre,
        edad,
        zona,
        estado,
        albergue,
        historial
      ])

  def completar_informacion(id, edad, estado, historial),
    do: solicitar(:completar_informacion, [id, edad, estado, historial])

  def obtener(id), do: solicitar(:obtener, [id])
  def crear(persona), do: solicitar(:crear, [persona])
  def actualizar(id, persona), do: solicitar(:actualizar, [id, persona])
  def eliminar(id), do: solicitar(:eliminar, [id])

  def reportar_persona(documento, nombre, edad, zona, estado),
    do: solicitar(:reportar_persona, [documento, nombre, edad, zona, estado])

  def reportar_persona(documento, nombre, edad, zona, estado, por),
    do: solicitar(:reportar_persona, [documento, nombre, edad, zona, estado, por])

  def obtener_por_documento(documento), do: solicitar(:obtener_por_documento, [documento])
  def buscar, do: solicitar(:buscar, [])
  def buscar(filtros), do: solicitar(:buscar, [filtros])
  def cambiar_estado(documento, estado), do: solicitar(:cambiar_estado, [documento, estado])

  def cambiar_estado(documento, estado, por),
    do: solicitar(:cambiar_estado, [documento, estado, por])

  def historial(documento), do: solicitar(:historial, [documento])

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
