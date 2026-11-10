defmodule Epicenter.GestorRecursoPersistenciaTest do
  use ExUnit.Case, async: false

  alias Epicenter.Persistencia

  setup do
    rutas = [
      Path.expand("../lib/Datos/Recurso.json", __DIR__),
      Path.expand("../lib/Datos/Mensaje.json", __DIR__),
      Path.expand("../lib/Datos/Inventario.json", __DIR__),
      Path.expand("../lib/Datos/Albergue.json", __DIR__),
      Path.expand("../lib/Datos/CentroApoyo.json", __DIR__),
      Path.expand("../lib/Datos/Historial.json", __DIR__),
      Path.expand("../lib/Datos/Mascota.json", __DIR__),
      Path.expand("../lib/Datos/Necesidad.json", __DIR__),
      Path.expand("../lib/Datos/Persona.json", __DIR__)
    ]

    contenidos = Enum.map(rutas, &File.read!/1)
    Enum.each(rutas, &File.write!(&1, "[]"))

    on_exit(fn ->
      Enum.zip(rutas, contenidos)
      |> Enum.each(fn {ruta, contenido} -> File.write!(ruta, contenido) end)
    end)

    :ok
  end

  test "registra recursos y guarda las entradas en su documento" do
    datos = %{
      nombre: "Agua",
      categoria: "agua",
      unidad_medida: "litros",
      cantidad: 15,
      minimo: 5,
      ubicacion: "centro-1",
      codigo_zona: "zona-1"
    }

    assert {:ok, recurso} = Epicenter.GenserverRecurso.registrar(datos, "Ana")
    assert recurso.categoria == :agua
    assert {:ok, ^recurso} = Epicenter.GenserverRecurso.obtener(recurso.codigo)

    assert {:ok, recurso_actualizado} =
             Epicenter.GenserverRecurso.registrar_entrada(recurso.codigo, 10, "Ana")

    assert recurso_actualizado.cantidad_disponible == 25
    assert {:ok, [^recurso_actualizado]} = Persistencia.cargar_recurso()
  end

  test "crea inventarios a través del constructor de su estructura" do
    assert {:ok, inventario} =
             Epicenter.GestorInventario.registro("recurso-1", "centro-1", ["zona-1"], 10)

    assert inventario.codigo_recurso == "recurso-1"
    assert inventario.codigo_centro == "centro-1"
    assert {:ok, [^inventario]} = Epicenter.GestorInventario.listar()
  end

  test "completa un inventario por identificador sin cambiar sus referencias" do
    assert {:ok, inventario} = Epicenter.GestorInventario.registro("recurso-2", "centro-2")

    assert {:ok, inventario_completo} =
             Epicenter.GestorInventario.completar_informacion(
               inventario.id,
               ["zona-2"],
               18
             )

    assert inventario_completo.id == inventario.id
    assert inventario_completo.codigo_recurso == "recurso-2"
    assert inventario_completo.codigo_centro == "centro-2"
    assert inventario_completo.zonas == ["zona-2"]
    assert inventario_completo.cantidad_disponible == 18
    assert {:ok, [^inventario_completo]} = Epicenter.GestorInventario.listar()
  end

  test "la persistencia conserva estados atomicos y fechas" do
    mensaje = %Epicenter.Mensaje{
      codigo: "mensaje-1",
      remitente: "Ana",
      destinatario: "Luis",
      contenido: "Necesito ayuda",
      estado: :pendiente,
      fecha_envio: DateTime.utc_now()
    }

    assert [^mensaje] = Persistencia.guardar_mensajes([mensaje])
    assert {:ok, [^mensaje]} = Persistencia.cargar_mensajes()
  end

  test "completa el estado del mensaje que coincide con su código" do
    assert {:ok, mensaje} = Epicenter.GestorMensaje.registro("Ana", "Luis", "Necesito ayuda")
    assert mensaje.estado == :pendiente

    assert {:ok, mensaje_completado} =
             Epicenter.GestorMensaje.completar_informacion(mensaje.codigo, :leido)

    assert mensaje_completado.codigo == mensaje.codigo
    assert mensaje_completado.estado == :leido
    assert {:ok, [^mensaje_completado]} = Epicenter.GestorMensaje.listar()
  end

  test "registra un movimiento y lo consulta mediante el GenServer" do
    assert {:ok, historial} =
             Epicenter.GenserverHistorial.registrar(:salida, "R001", 5, "Entrega", "Ana")

    assert historial.tipo == :salida
    assert historial.codigo_recurso == "R001"
    assert historial.cantidad == 5
    assert historial.detalle == "Entrega"
    assert historial.usuario == "Ana"
    assert {:ok, [^historial]} = Epicenter.GenserverHistorial.listar()
  end

  test "consulta cupos del albergue mediante el GenServer" do
    codigo_zona = "A1F03C9E7B2D4410"
    assert {:ok, albergue} = Epicenter.GenserverAlbergue.registro("Refugio", codigo_zona, 10)

    assert {:ok, 10} = Epicenter.GenserverAlbergue.cupos(albergue.codigo)
  end

  test "completa la zona del centro de apoyo buscándolo por código" do
    assert {:ok, centro} = Epicenter.GestorCentroApoyo.registro("Puesto", "temporal")
    assert is_nil(centro.codigo_zona)

    assert {:ok, centro_completo} =
             Epicenter.GestorCentroApoyo.completar_informacion(centro.codigo, "zona-1")

    assert centro_completo.codigo == centro.codigo
    assert centro_completo.nombre == "Puesto"
    assert centro_completo.codigo_zona == "zona-1"
    assert {:ok, [^centro_completo]} = Epicenter.GestorCentroApoyo.listar()
  end

  test "registra y consulta una necesidad con los campos de su struct" do
    codigo_zona = "A1F03C9E7B2D4410"

    assert {:ok, necesidad} =
             Epicenter.GenserverNecesidad.registrar(
               codigo_zona,
               "Ana",
               :agua,
               "Agua potable",
               20,
               :alta,
               "centro-1"
             )

    assert necesidad.codigo_zona == codigo_zona
    assert necesidad.reportado_por == "Ana"
    assert necesidad.descripcion == "Agua potable"
    assert necesidad.cantidad == 20
    assert {:ok, [^necesidad]} = Epicenter.GenserverNecesidad.listar()
  end

  test "completa una persona buscando por su identificador" do
    assert {:ok, persona} =
             Epicenter.GestorPersona.registro("123", :cedula, "Ana", "zona-1", "albergue-1")

    assert {:ok, persona_completa} =
             Epicenter.GestorPersona.completar_informacion(
               persona.id,
               30,
               :estable,
               ["registro-1"]
             )

    assert persona_completa.id == persona.id
    assert persona_completa.documento == "123"
    assert persona_completa.codigo_zona == "zona-1"
    assert persona_completa.codigo_albergue == "albergue-1"
    assert persona_completa.edad == 30
    assert persona_completa.historial == ["registro-1"]
    assert {:ok, [^persona_completa]} = Epicenter.GestorPersona.listar()
  end

  test "el CRUD de mascotas usa los campos y las transiciones de su estructura" do
    datos = %{
      tipo: :perdida,
      especie: "Perro",
      nombre: "Luna",
      caracteristicas: "Mancha blanca",
      color: "Marrón",
      tamano: "mediana",
      zona: "zona-1",
      contacto: "555-0100"
    }

    assert {:ok, mascota} = Epicenter.GestorMascota.registro("mascota-1", datos)
    assert mascota.id == "mascota-1"
    assert mascota.especie == "perro"
    assert mascota.zona == "zona-1"
    assert {:ok, ^mascota} = Epicenter.GestorMascota.obtener(mascota.id)

    assert {:ok, mascota_actualizada} =
             Epicenter.GestorMascota.cambiar_estado(mascota.id, :posible_coincidencia)

    assert mascota_actualizada.estado == :posible_coincidencia
    assert {:ok, [^mascota_actualizada]} = Epicenter.GestorMascota.listar()

    assert {:ok, ^mascota_actualizada} = Epicenter.GestorMascota.eliminar(mascota.id)
    assert {:ok, []} = Epicenter.GestorMascota.listar()
  end
end
