defmodule Interfaz.Fuente.Actividad do
  @moduledoc """
  Usuarios conectados y registro de actividad.

  DATOS DE MUESTRA: la lógica todavía no guarda quién está conectado ni un
  registro de operaciones. Cuando exista, se reemplazan estas dos funciones.
  """

  def usuarios do
    [
      %{
        usuario: "laura",
        nombre: "Laura Restrepo",
        rol: :coordinador,
        zona: "A1F03C9E7B2D4410",
        conectado: true
      },
      %{
        usuario: "carlos",
        nombre: "Carlos Mejía",
        rol: :voluntario,
        zona: "B7D24E901FA3C665",
        conectado: true
      },
      %{
        usuario: "andres",
        nombre: "Andrés Gómez",
        rol: :ciudadano,
        zona: "B7D24E901FA3C665",
        conectado: false
      },
      %{
        usuario: "admin",
        nombre: "Administración",
        rol: :administrador,
        zona: "A1F03C9E7B2D4410",
        conectado: true
      }
    ]
  end

  def actividad do
    [
      %{
        fecha: "09/11 10:42",
        usuario: "carlos",
        accion: "assign_resource N002 agua 25",
        resultado: :error,
        detalle: "Inventario insuficiente (20 L)"
      },
      %{
        fecha: "09/11 10:42",
        usuario: "laura",
        accion: "assign_resource N001 agua 30",
        resultado: :ok,
        detalle: "R001 queda en 20 L"
      },
      %{
        fecha: "09/11 10:30",
        usuario: "laura",
        accion: "register_resource R001 agua 50 litros centro_acopio_1",
        resultado: :ok,
        detalle: nil
      },
      %{
        fecha: "09/11 10:20",
        usuario: "carlos",
        accion: "report_pet found perro desconocido negra mediana zona_norte",
        resultado: :ok,
        detalle: "Posible coincidencia con M001"
      },
      %{
        fecha: "09/11 10:10",
        usuario: "andres",
        accion: ~s(send_family_message 1094887123 "Estoy bien..."),
        resultado: :ok,
        detalle: nil
      },
      %{
        fecha: "09/11 10:05",
        usuario: "andres",
        accion: "register_entry A01 1094887123",
        resultado: :ok,
        detalle: nil
      },
      %{
        fecha: "09/11 09:58",
        usuario: "andres",
        accion: "register_resource R009 agua 10 litros casa",
        resultado: :error,
        detalle: "Rol ciudadano sin permiso"
      },
      %{
        fecha: "09/11 09:40",
        usuario: "laura",
        accion: ~s(register_need agua 30 critica centro "Punto de atención sector 3"),
        resultado: :ok,
        detalle: "N001"
      },
      %{
        fecha: "09/11 09:39",
        usuario: "laura",
        accion: "connect laura **** coordinador centro",
        resultado: :ok,
        detalle: nil
      }
    ]
  end
end
