defmodule Interfaz.FuenteTest do
  # Solo casos inválidos: se rechazan antes de llamar a la lógica,
  # así que no escriben en Usuario.json.
  use ExUnit.Case, async: true

  alias Interfaz.Fuente

  describe "conectar/2" do
    test "el usuario es obligatorio, sin espacios y de 3 a 20 caracteres" do
      assert {:error, "Escribe tu usuario."} = Fuente.conectar("   ", "1234")
      assert {:error, "El usuario no puede tener espacios."} = Fuente.conectar("ana maria", "1234")

      assert {:error, "El usuario debe tener entre 3 y 20 caracteres."} =
               Fuente.conectar("an", "1234")
    end

    test "la contraseña es obligatoria" do
      assert {:error, "Escribe tu contraseña."} = Fuente.conectar("laura", "")
    end
  end

  describe "registrar/4" do
    test "exige una contraseña de al menos 4 caracteres" do
      assert {:error, "La contraseña debe tener al menos 4 caracteres."} =
               Fuente.registrar("nuevo_usuario", "123", "ciudadano", "A1F03C9E7B2D4410")
    end

    test "solo permite ciudadano o voluntario" do
      for rol <- ["coordinador", "administrador", "jefe"] do
        assert {:error, "Al registrarte solo puedes ser ciudadano o voluntario."} =
                 Fuente.registrar("nuevo_usuario", "1234", rol, "A1F03C9E7B2D4410")
      end
    end

    test "la zona debe existir" do
      assert {:error, "Zona no válida."} =
               Fuente.registrar("nuevo_usuario", "1234", "voluntario", "marte")
    end
  end
end
