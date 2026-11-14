defmodule Epicenter.GestorRecursoPersistenciaTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorRecurso
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

  test "el CRUD de recursos guarda cada cambio en su documento" do
    assert {:ok, recurso} = GestorRecurso.registro_recurso("Agua", "hidratación", 15, "litros")
    assert {:ok, ^recurso} = GestorRecurso.obtener(recurso.codigo)

    actualizado = %{recurso | cantidad_disponible: 25}
    assert {:ok, ^actualizado} = GestorRecurso.actualizar(recurso.codigo, actualizado)
    assert {:ok, [^actualizado]} = Persistencia.cargar_recurso()

    assert {:ok, ^actualizado} = GestorRecurso.eliminar(recurso.codigo)
    assert {:ok, []} == GestorRecurso.listar()
  end

  test "completa los datos de un recurso buscando por su código" do
    assert {:ok, recurso} = GestorRecurso.registro_recurso("Agua", "bebida")
    assert recurso.nombre == "Agua"
    assert recurso.categoria == "bebida"

    assert {:ok, recurso_completo} =
             GestorRecurso.completar_informacion(recurso.codigo, 30, "litros")

    assert recurso_completo.codigo == recurso.codigo
    assert recurso_completo.nombre == "Agua"
    assert recurso_completo.categoria == "bebida"
    assert recurso_completo.cantidad_disponible == 30
    assert recurso_completo.unidad_medida == "litros"
    assert {:ok, [^recurso_completo]} = GestorRecurso.listar()
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

  test "completa los campos opcionales del historial buscando por id" do
    assert {:ok, historial} =
             Epicenter.GestorHistorial.registro("inv-1", "Ana", "nec-1", "destino-1")

    fecha = DateTime.utc_now()

    assert {:ok, historial_completo} =
             Epicenter.GestorHistorial.completar_informacion(
               historial.id,
               :salida,
               5,
               fecha
             )

    assert historial_completo.id == historial.id
    assert historial_completo.id_invetario == "inv-1"
    assert historial_completo.id_necesidad == "nec-1"
    assert historial_completo.tipo == :salida
    assert historial_completo.cantidad == 5
    assert historial_completo.fecha == fecha
    assert {:ok, [^historial_completo]} = Epicenter.GestorHistorial.listar()
  end

  test "completa el albergue por su código y conserva sus datos iniciales" do
    assert {:ok, albergue} = Epicenter.GestorAlbergue.registro("Refugio", "zona-1", 10)

    assert {:ok, albergue_completo} =
             Epicenter.GestorAlbergue.completar_informacion(
               albergue.codigo,
               4,
               ["agua"],
               ["medicinas"]
             )

    assert albergue_completo.codigo == albergue.codigo
    assert albergue_completo.nombre == "Refugio"
    assert albergue_completo.ocupantes == 4
    assert albergue_completo.recursos == ["agua"]
    assert albergue_completo.necesidades == ["medicinas"]
    assert {:ok, [^albergue_completo]} = Epicenter.GestorAlbergue.listar()
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

  test "completa una necesidad buscando por su identificador" do
    assert {:ok, necesidad} = Epicenter.GestorNecesidad.registro("zona-1", "Ana")

    assert {:ok, necesidad_completa} =
             Epicenter.GestorNecesidad.completar_informacion(
               necesidad.id,
               :agua,
               "Agua potable",
               20,
               :alta,
               :pendiente,
               "centro-1"
             )

    assert necesidad_completa.id == necesidad.id
    assert necesidad_completa.codigo_zona == "zona-1"
    assert necesidad_completa.reportador_por == "Ana"
    assert necesidad_completa.descripicion == "Agua potable"
    assert necesidad_completa.cantidad == 20
    assert {:ok, [^necesidad_completa]} = Epicenter.GestorNecesidad.listar()
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
