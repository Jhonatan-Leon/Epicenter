defmodule GestorRecursoTest do
  use ExUnit.Case, async: true

  test "suma la disponibilidad del recurso para la zona seleccionada" do
    inventarios = [
      %Epicenter.Inventario{
        id: "inv-1",
        zonas: ["zona-1"],
        codigo_recurso: "agua",
        codigo_centro: "centro-1",
        cantidad_disponible: 10
      },
      %Epicenter.Inventario{
        id: "inv-2",
        zonas: ["zona-1", "zona-2"],
        codigo_recurso: "agua",
        codigo_centro: "centro-2",
        cantidad_disponible: 5
      },
      %Epicenter.Inventario{
        id: "inv-3",
        zonas: ["zona-1"],
        codigo_recurso: "alimento",
        codigo_centro: "centro-3",
        cantidad_disponible: 20
      }
    ]

    codigos_zona = ["zona-1", "zona-2"]

    assert {:ok, 15} =
             Epicenter.GestorRecurso.consultar_disponibilidad(
               "zona-1",
               "agua",
               codigos_zona,
               inventarios
             )

    assert {:ok, 0} =
             Epicenter.GestorRecurso.consultar_disponibilidad(
               "zona-2",
               "alimento",
               codigos_zona,
               inventarios
             )

    assert {:error, "La zona no existe"} =
             Epicenter.GestorRecurso.consultar_disponibilidad(
               "zona-3",
               "agua",
               codigos_zona,
               inventarios
             )
  end

  test "rechaza un valor que no sea una lista de inventarios" do
    assert {:error, "Las listas de zonas o inventarios no son válidas"} =
             Epicenter.GestorRecurso.consultar_disponibilidad("zona-1", "agua", nil, nil)
  end
end
