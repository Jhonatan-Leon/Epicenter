defmodule Epicenter.AutorizacionTest do
  use ExUnit.Case, async: false

  alias Epicenter.Autorizacion

  @zona_centro "A1F03C9E7B2D4410"
  @zona_norte "B7D24E901FA3C665"

  setup do
    ruta = Epicenter.Persistencia.ruta_datos("Usuario.json")
    contenido_original = File.read!(ruta)

    File.write!(ruta, """
    [
      {"nombre_usuario":"ciudadano","contrasena":"clave","rol":"ciudadano","zona_principal":"Norte"},
      {"nombre_usuario":"voluntario","contrasena":"clave","rol":"voluntario","zona_principal":"Norte"},
      {"nombre_usuario":"coordinador","contrasena":"clave","rol":"coordinar","zona_principal":"Centro"},
      {"nombre_usuario":"administrador","contrasena":"clave","rol":"administrador","zona_principal":null}
    ]
    """)

    on_exit(fn -> File.write!(ruta, contenido_original) end)
    :ok
  end

  test "ciudadanos registran necesidades pero no gestionan inventario" do
    assert Autorizacion.puede?(:ciudadano, :registrar_necesidad)
    refute Autorizacion.puede?(:ciudadano, :asignar_recurso)

    assert {:ok, %{rol: :ciudadano}} =
             Autorizacion.autorizar("ciudadano", :registrar_necesidad)
  end

  test "voluntarios pueden operar en terreno pero no administrar zonas" do
    assert {:ok, %{rol: :voluntario}} =
             Autorizacion.autorizar("voluntario", :registrar_ingreso_albergue)

    assert {:error, :permiso_denegado} =
             Autorizacion.autorizar("voluntario", :gestionar_zonas)
  end

  test "coordinadores quedan limitados a su zona asignada" do
    assert Autorizacion.puede?(:coordinar, :registrar_necesidad_critica)

    assert {:ok, %{rol: :coordinar}} =
             Autorizacion.autorizar("coordinador", :asignar_recurso, @zona_centro)

    assert {:error, :fuera_de_zona} =
             Autorizacion.autorizar("coordinador", :asignar_recurso, @zona_norte)

    assert {:error, :zona_requerida} =
             Autorizacion.autorizar("coordinador", :asignar_recurso)
  end

  test "administradores tienen alcance global y permisos administrativos" do
    assert {:ok, %{rol: :administrador}} =
             Autorizacion.autorizar("administrador", :administrar_usuarios)

    assert {:ok, %{rol: :administrador}} =
             Autorizacion.autorizar("administrador", :asignar_recurso, @zona_norte)
  end

  test "el ejecutor no llama la operación si la autorización falla" do
    resultado =
      Autorizacion.ejecutar("ciudadano", :asignar_recurso, @zona_norte, fn _usuario ->
        flunk("La operación no debe ejecutarse")
      end)

    assert resultado == {:error, :permiso_denegado}
  end

  test "rechaza usuarios inexistentes y acciones desconocidas" do
    assert {:error, :usuario_no_autenticado} =
             Autorizacion.autorizar("no-existe", :registrar_necesidad)

    assert {:error, :permiso_denegado} =
             Autorizacion.autorizar("administrador", :accion_desconocida)

    refute Autorizacion.puede?(:ciudadano, :registrar_necesidad_critica)
  end
end
