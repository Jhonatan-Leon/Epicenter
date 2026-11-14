defmodule Interfaz.Fuente.Resumen do
  @moduledoc """
  Cifras que juntan varias gestiones (comando `summary` y estadísticas de zona).
  Cada lista se pide una sola vez y se reutiliza para todos los conteos.
  """

  alias Interfaz.Fuente.{Albergues, Mascotas, Mensajes, Necesidades, Personas, Recursos, Zonas}

  @estados_localizada [:localizada, :en_albergue, :trasladada, :reunificada]

  @doc "Comando `summary`."
  def resumen do
    pendientes = Necesidades.pendientes()
    recursos = Recursos.recursos()
    personas = Personas.personas()
    mensajes = Mensajes.mensajes()
    mascotas = Mascotas.mascotas()
    albergues = Albergues.albergues()

    %{
      necesidades_pendientes: length(pendientes),
      necesidades_criticas: Enum.count(pendientes, &(&1.prioridad == :critica)),
      recursos_criticos: Enum.count(recursos, & &1.critico),
      recursos_total: length(recursos),
      personas_localizadas: Enum.count(personas, &(&1.estado in @estados_localizada)),
      personas_total: length(personas),
      mensajes_pendientes: Enum.count(mensajes, &(&1.estado == :pendiente)),
      mensajes_total: length(mensajes),
      mascotas_activas: Enum.count(mascotas, &(&1.estado != :resuelta)),
      mascotas_coincidencias: length(Mascotas.coincidencias()),
      ocupacion: Enum.sum_by(albergues, & &1.ocupacion),
      capacidad: Enum.sum_by(albergues, & &1.capacidad)
    }
  end

  @doc "Estadísticas acumuladas de una zona: sectores, puntos, necesidades abiertas y cupos."
  def estadisticas_zona(codigo_zona) do
    estadisticas = Zonas.estadisticas(codigo_zona) || %{sectores: 0, puntos: 0}

    %{
      sectores: estadisticas.sectores,
      puntos: estadisticas.puntos,
      necesidades: Enum.count(Necesidades.pendientes(), &(&1.zona == codigo_zona)),
      cupos: Albergues.cupos_de_zona(codigo_zona)
    }
  end
end
