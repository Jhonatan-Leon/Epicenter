defmodule Epicenter.GenserverMascota do
  use GenServer

  @gestor Epicenter.GestorMascota
  @funciones [
    listar: 0,
    registro: 1,
    registro: 2,
    obtener: 1,
    crear: 1,
    actualizar: 2,
    cambiar_estado: 2,
    eliminar: 1,
    consultar: 0,
    consultar: 1,
    coincidencias_posibles: 0,
    marcar_coincidencias: 0,
    confirmar_coincidencia: 2,
    umbral_candidata: 0,
    umbral_marcar: 0,
    pesos: 0,
    desglose: 2,
    puntaje: 2,
    calcular_coincidencias: 1,
    calcular_coincidencias: 2,
    seleccionar_para_marcar: 1,
    seleccionar_para_marcar: 2
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def listar, do: solicitar(:listar, [])
  def registro(datos), do: solicitar(:registro, [datos])
  def registro(id, datos), do: solicitar(:registro, [id, datos])
  def obtener(id), do: solicitar(:obtener, [id])
  def crear(mascota), do: solicitar(:crear, [mascota])
  def actualizar(id, mascota), do: solicitar(:actualizar, [id, mascota])
  def cambiar_estado(id, estado), do: solicitar(:cambiar_estado, [id, estado])
  def eliminar(id), do: solicitar(:eliminar, [id])
  def consultar, do: solicitar(:consultar, [])
  def consultar(filtros), do: solicitar(:consultar, [filtros])
  def coincidencias_posibles, do: solicitar(:coincidencias_posibles, [])
  def marcar_coincidencias, do: solicitar(:marcar_coincidencias, [])

  def confirmar_coincidencia(id_perdida, id_encontrada),
    do: solicitar(:confirmar_coincidencia, [id_perdida, id_encontrada])

  def umbral_candidata, do: solicitar(:umbral_candidata, [])
  def umbral_marcar, do: solicitar(:umbral_marcar, [])
  def pesos, do: solicitar(:pesos, [])
  def desglose(mascota_a, mascota_b), do: solicitar(:desglose, [mascota_a, mascota_b])
  def puntaje(mascota_a, mascota_b), do: solicitar(:puntaje, [mascota_a, mascota_b])
  def calcular_coincidencias(mascotas), do: solicitar(:calcular_coincidencias, [mascotas])

  def calcular_coincidencias(mascotas, umbral),
    do: solicitar(:calcular_coincidencias, [mascotas, umbral])

  def seleccionar_para_marcar(coincidencias),
    do: solicitar(:seleccionar_para_marcar, [coincidencias])

  def seleccionar_para_marcar(coincidencias, umbral),
    do: solicitar(:seleccionar_para_marcar, [coincidencias, umbral])

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
