defmodule InterfazWeb.Formato do
  @moduledoc """
  Textos para la pantalla: etiquetas en español de los átomos del dominio,
  opciones de `<select>` y nombre de una zona. No dibuja nada.
  """

  @etiquetas %{
    critico: "Crítico",
    critica: "Crítica",
    alto: "Alto",
    alta: "Alta",
    medio: "Medio",
    media: "Media",
    bajo: "Bajo",
    baja: "Baja",
    pendiente: "Pendiente",
    asignada: "Asignada",
    en_atencion: "En atención",
    atendida: "Atendida",
    cancelada: "Cancelada",
    sin_informacion: "Sin información",
    reportada: "Reportada",
    localizada: "Localizada",
    trasladada: "Trasladada",
    en_albergue: "En albergue",
    reunificada: "Reunificada",
    activa: "Activa",
    posible_coincidencia: "Posible coincidencia",
    resuelta: "Resuelta",
    perdida: "Perdida",
    encontrada: "Encontrada",
    entregado: "Entregado",
    agua: "Agua",
    alimentos: "Alimentos",
    medicamentos: "Medicamentos",
    primeros_auxilios: "Primeros auxilios",
    refugio: "Refugio",
    transporte: "Transporte",
    rescate: "Rescate",
    otra: "Otra",
    ciudadano: "Ciudadano",
    voluntario: "Voluntario",
    coordinador: "Coordinador",
    administrador: "Administrador",
    entrada: "Entrada",
    salida: "Salida",
    asignacion: "Asignación",
    transferencia: "Transferencia",
    rechazo: "Rechazada",
    perro: "Perro",
    gato: "Gato",
    ave: "Ave",
    pequeno: "Pequeño",
    mediano: "Mediano",
    grande: "Grande",
    ok: "Correcto",
    error: "Rechazado",
    especie: "Especie",
    color: "Color",
    tamano: "Tamaño",
    zona: "Zona",
    caracteristicas: "Características"
  }

  @doc "Texto legible para un átomo del dominio."
  def t(nil), do: "—"
  def t(valor) when is_atom(valor), do: Map.get(@etiquetas, valor, Phoenix.Naming.humanize(valor))
  def t(valor), do: to_string(valor)

  @doc "Opciones `{etiqueta, valor}` para un `<select>`."
  def opciones(valores), do: Enum.map(valores, &{t(&1), &1})

  @orden_niveles [:critico, :alto, :medio, :bajo]

  @doc """
  Nivel más grave entre varios elementos con `:nivel`. Solo lo usa el fondo
  animado para ajustar su intensidad (`data-sx-nivel`); no afecta a los datos.
  """
  def nivel_mas_alto(elementos) do
    presentes = Enum.map(elementos, & &1.nivel)
    Enum.find(@orden_niveles, &(&1 in presentes))
  end

  @doc "Nombre legible de una zona a partir de su código."
  def zona(codigo, zonas), do: Map.get(zonas, codigo, codigo)
end
