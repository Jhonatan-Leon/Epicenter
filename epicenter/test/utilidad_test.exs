defmodule UtilidadTest do
  use ExUnit.Case, async: true

  test "verificar_cantidad acepta cantidades no negativas" do
    assert :ok = Utilidad.verificar_cantidad(5)
    assert :ok = Utilidad.verificar_cantidad(0)
  end

  test "verificar_cantidad rechaza cantidades negativas y valores no numéricos" do
    assert {:error, "La cantidad no puede ser negativa"} = Utilidad.verificar_cantidad(-1)
    assert {:error, "La cantidad debe ser un número"} = Utilidad.verificar_cantidad("cinco")
  end
end
