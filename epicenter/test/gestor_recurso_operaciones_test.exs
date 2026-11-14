defmodule Epicenter.GestorRecursoOperacionesTest do
  use ExUnit.Case, async: false

  alias Epicenter.{GestorNecesidad, GestorRecurso, Persistencia}

  setup do
    zonas = Persistencia.carga_zonas() |> Map.keys()
    [zona_origen, zona_destino | _] = zonas

    Persistencia.guardar_recursos([])
    Persistencia.guardar_necesidades([])
    Persistencia.guardar_historiales([])

    {:ok, zona_origen: zona_origen, zona_destino: zona_destino}
  end

  test "rechaza asignar una categoría distinta sin descontar el recurso", %{
    zona_origen: zona
  } do
    recurso = guardar_recurso("R001", zona, "origen", :agua, "litros", 10)
    necesidad = crear_necesidad(zona, :alimentos)

    assert {:error, :categoria_incompatible} =
             GestorRecurso.asignar_a_necesidad(recurso.codigo, necesidad.id, 2, "operador")

    assert {:ok, [%{cantidad_disponible: 10}]} = Persistencia.cargar_recurso()
  end

  test "permite asignar una categoría coincidente", %{zona_origen: zona} do
    recurso = guardar_recurso("R001", zona, "origen", :agua, "litros", 10)
    necesidad = crear_necesidad(zona, :agua)

    assert {:ok, %{cantidad_disponible: 8}} =
             GestorRecurso.asignar_a_necesidad(recurso.codigo, necesidad.id, 2, "operador")

    assert {:ok, %{asignaciones: [%{cantidad: 2, recurso: "R001"}]}} =
             GestorNecesidad.obtener(necesidad.id)
  end

  test "transfiere a la zona solicitada y no mezcla unidades distintas", %{
    zona_origen: zona_origen,
    zona_destino: zona_destino
  } do
    origen = guardar_recurso("R001", zona_origen, "origen", :agua, "litros", 10)
    destino_existente = guardar_recurso("R002", zona_destino, "destino", :agua, "botellas", 3)

    assert {:ok, _recurso_origen} =
             GestorRecurso.transferir(origen.codigo, 2, "destino", zona_destino, "operador")

    assert {:ok, recursos} = Persistencia.cargar_recurso()
    assert Enum.find(recursos, &(&1.codigo == origen.codigo)).cantidad_disponible == 8
    assert Enum.find(recursos, &(&1.codigo == destino_existente.codigo)).cantidad_disponible == 3

    assert Enum.any?(recursos, fn recurso ->
             recurso.ubicacion == "destino" and recurso.unidad_medida == "litros" and
               recurso.codigo_zona == zona_destino and recurso.cantidad_disponible == 2
           end)
  end

  test "requiere zona cuando no puede inferirse desde la ubicación", %{zona_origen: zona} do
    recurso = guardar_recurso("R001", zona, "origen", :agua, "litros", 10)

    assert {:error, :zona_destino_requerida} =
             GestorRecurso.transferir(recurso.codigo, 2, "sin-registro", "operador")
  end

  defp crear_necesidad(zona, tipo) do
    {:ok, necesidad} =
      GestorNecesidad.registrar(zona, "operador", tipo, "Solicitud", 10, :alta)

    necesidad
  end

  defp guardar_recurso(codigo, zona, ubicacion, categoria, unidad, cantidad) do
    recurso = %Epicenter.Recurso{
      codigo: codigo,
      nombre: "Agua",
      categoria: categoria,
      unidad_medida: unidad,
      ubicacion: ubicacion,
      codigo_zona: zona,
      cantidad_disponible: cantidad,
      minimo: 0
    }

    Persistencia.guardar_recursos([recurso | elem(Persistencia.cargar_recurso(), 1)])
    recurso
  end
end
