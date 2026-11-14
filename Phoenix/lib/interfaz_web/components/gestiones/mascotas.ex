defmodule InterfazWeb.Gestiones.Mascotas do
  @moduledoc "Componentes de la gestión de mascotas."
  use InterfazWeb, :html

  attr :mascota, :map, required: true
  attr :zonas_por_codigo, :map, required: true

  @doc "Ficha de un reporte de mascota, construida sobre la tarjeta base."
  def tarjeta_mascota(assigns) do
    ~H"""
    <.tarjeta id={"mascota-#{@mascota.id}"} alerta={@mascota.reporte == :perdida and @mascota.estado == :activa}>
      <:etiqueta>
        {@mascota.id} · {t(@mascota.especie)} · {zona(@mascota.zona, @zonas_por_codigo)}
      </:etiqueta>
      <:titulo>{@mascota.nombre || "Sin nombre"}</:titulo>
      <:insignias><.insignia valor={@mascota.estado} /></:insignias>

      <div class="flex flex-wrap gap-1.5 text-xs">
        <span class="badge badge-sm badge-outline">Color: {@mascota.color}</span>
        <span class="badge badge-sm badge-outline">Tamaño: {t(@mascota.tamano)}</span>
      </div>
      <p :if={@mascota.caracteristicas} class="mt-2 text-sm text-base-content/80">
        {@mascota.caracteristicas}
      </p>

      <:pie>
        <span><.icon name="hero-phone" class="size-3.5" /> {@mascota.contacto}</span>
      </:pie>
    </.tarjeta>
    """
  end
end
