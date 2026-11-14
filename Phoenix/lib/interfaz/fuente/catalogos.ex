defmodule Interfaz.Fuente.Catalogos do
  @moduledoc """
  Valores permitidos para los `<select>` de la interfaz. Cuando la lógica
  ya define la lista, se toma de ahí para que las dos partes no se separen.
  """

  def roles, do: [:ciudadano, :voluntario, :coordinador, :administrador]
  def niveles, do: [:critico, :alto, :medio, :bajo]

  def prioridades, do: Epicenter.Necesidad.prioridades()
  def tipos_necesidad, do: Epicenter.Necesidad.tipos()
  def estados_necesidad, do: Epicenter.Necesidad.estados()

  def categorias_recurso, do: Epicenter.Recurso.categorias()

  def estados_persona,
    do: [:sin_informacion, :reportada, :localizada, :trasladada, :en_albergue, :reunificada]

  def estados_mascota, do: [:activa, :posible_coincidencia, :resuelta]
  def especies, do: [:perro, :gato, :ave, :otra]
  def tamanos, do: [:pequeno, :mediano, :grande]
end
