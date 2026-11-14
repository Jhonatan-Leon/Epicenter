defmodule Interfaz.Fuente.ComunTest do
  use ExUnit.Case, async: true

  alias Interfaz.Fuente.Comun

  test "un JSON dañado se informa por nombre de archivo, sin volcar su contenido" do
    error = %{
      archivo: "c:/x/epicenter/lib/Datos/Mensaje.json",
      etapa: :decodificacion,
      razon: %{data: String.duplicate("contenido largo ", 200)}
    }

    mensaje = Comun.traducir(error)

    assert mensaje =~ "Mensaje.json"
    refute mensaje =~ "contenido largo"
  end

  test "los errores de la lógica salen en español" do
    assert Comun.traducir(:categoria_incompatible) =~ "misma categoría"
    assert Comun.traducir(:permiso_denegado) == "Tu rol no permite esta acción."
  end
end
