defmodule Epicenter.GestorRecursoPersistenciaTest do
  use ExUnit.Case, async: false

  alias Epicenter.GestorRecurso
  alias Epicenter.Persistencia

  setup do
    codigo_zona = Persistencia.carga_zonas() |> Map.keys() |> hd()

    rutas = [
      Persistencia.ruta_datos("Recurso.json"),
      Persistencia.ruta_datos("Mensaje.json"),
      Persistencia.ruta_datos("Inventario.json"),
      Persistencia.ruta_datos("Albergue.json"),
      Persistencia.ruta_datos("CentroApoyo.json"),
      Persistencia.ruta_datos("Historial.json"),
      Persistencia.ruta_datos("Mascota.json"),
      Persistencia.ruta_datos("Necesidad.json"),
      Persistencia.ruta_datos("Persona.json")
    ]

    contenidos = Enum.map(rutas, &File.read!/1)
    Enum.each(rutas, &File.write!(&1, "[]"))

    on_exit(fn ->
      Enum.zip(rutas, contenidos)
      |> Enum.each(fn {ruta, contenido} -> File.write!(ruta, contenido) end)
    end)

    {:ok, codigo_zona: codigo_zona}
  end

  test "registra recursos y persiste entradas y salidas de inventario", %{
    codigo_zona: zona
  } do
    assert {:ok, recurso} =
             GestorRecurso.registrar(
               %{
                 nombre: "Agua",
                 categoria: :agua,
                 unidad_medida: "litros",
                 cantidad: 15,
                 minimo: 3,
                 ubicacion: "Centro",
                 codigo_zona: zona
               },
               "Ana"
             )

    assert {:ok, ^recurso} = GestorRecurso.obtener(recurso.codigo)

    assert {:ok, %{cantidad_disponible: 25}} =
             GestorRecurso.registrar_entrada(recurso.codigo, 10, "Ana")

    assert {:ok, %{cantidad_disponible: 20}} =
             GestorRecurso.registrar_salida(recurso.codigo, 5, "Entrega", "Ana")

    assert {:ok, [%{codigo: codigo, cantidad_disponible: 20}]} = Persistencia.cargar_recurso()
    assert codigo == recurso.codigo
  end

  test "registra categorías válidas del catálogo de necesidades", %{codigo_zona: zona} do
    assert {:ok, recurso} =
             GestorRecurso.registrar(
               %{
                 nombre: "Frazadas",
                 categoria: "refugio",
                 unidad_medida: "unidades",
                 cantidad: 30,
                 minimo: 5,
                 ubicacion: "Bodega",
                 codigo_zona: zona
               },
               "Ana"
             )

    assert recurso.categoria == :refugio
    assert {:ok, [%{codigo: codigo, categoria: :refugio}]} = GestorRecurso.listar()
    assert codigo == recurso.codigo
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

  test "registra y consulta los movimientos de un recurso" do
    assert {:ok, historial} =
             Epicenter.GestorHistorial.registrar(:salida, "R001", 5, "Entrega", "Ana")

    assert historial.codigo_recurso == "R001"
    assert historial.tipo == :salida
    assert historial.cantidad == 5
    assert %DateTime{} = historial.fecha
    assert {:ok, [^historial]} = Epicenter.GestorHistorial.de_recurso("R001")
  end

  test "completa el albergue por su código y conserva sus datos iniciales", %{
    codigo_zona: zona
  } do
    assert {:ok, albergue} = Epicenter.GestorAlbergue.registro("Refugio", zona, 10)

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

  test "registra y recupera una necesidad incluyendo sus asignaciones", %{
    codigo_zona: zona
  } do
    assert {:ok, necesidad} =
             Epicenter.GestorNecesidad.registrar(
               zona,
               "Ana",
               :agua,
               "Agua potable",
               20,
               :alta,
               "Centro"
             )

    assert {:ok, recuperada} = Epicenter.GestorNecesidad.obtener(necesidad.id)
    assert recuperada.codigo_zona == zona
    assert recuperada.reportado_por == "Ana"
    assert recuperada.descripcion == "Agua potable"
    assert recuperada.cantidad == 20
    assert recuperada.asignaciones == []
  end

  test "completa una persona buscando por su identificador", %{codigo_zona: zona} do
    assert {:ok, persona} =
             Epicenter.GestorPersona.registro("123", :cedula, "Ana", zona, "albergue-1")

    assert {:ok, persona_completa} =
             Epicenter.GestorPersona.completar_informacion(
               persona.id,
               30,
               :estable,
               ["registro-1"]
             )

    assert persona_completa.id == persona.id
    assert persona_completa.documento == "123"
    assert persona_completa.codigo_zona == zona
    assert persona_completa.codigo_albergue == "albergue-1"
    assert persona_completa.edad == 30
    assert persona_completa.historial == ["registro-1"]
    assert {:ok, [^persona_completa]} = Epicenter.GestorPersona.listar()
  end

  test "el CRUD de mascotas usa los campos y las transiciones de su estructura", %{
    codigo_zona: zona
  } do
    datos = %{
      tipo: :perdida,
      especie: "Perro",
      nombre: "Luna",
      caracteristicas: "Mancha blanca",
      color: "Marrón",
      tamano: "mediana",
      zona: zona,
      contacto: "555-0100"
    }

    assert {:ok, mascota} = Epicenter.GestorMascota.registro("mascota-1", datos)
    assert mascota.id == "mascota-1"
    assert mascota.especie == "perro"
    assert mascota.zona == zona
    assert {:ok, ^mascota} = Epicenter.GestorMascota.obtener(mascota.id)

    assert {:ok, mascota_actualizada} =
             Epicenter.GestorMascota.cambiar_estado(mascota.id, :posible_coincidencia)

    assert mascota_actualizada.estado == :posible_coincidencia
    assert {:ok, [^mascota_actualizada]} = Epicenter.GestorMascota.listar()

    assert {:ok, ^mascota_actualizada} = Epicenter.GestorMascota.eliminar(mascota.id)
    assert {:ok, []} = Epicenter.GestorMascota.listar()
  end
end
