defmodule Interfaz.Fuente.SesionTest do
  # Solo casos inválidos: se rechazan antes de llamar a la lógica,
  # así que no escriben en Usuario.json.
  use ExUnit.Case, async: true

  alias Interfaz.Fuente.Sesion

  describe "conectar/2" do
    test "el usuario es obligatorio, sin espacios y de 3 a 20 caracteres" do
      assert {:error, "Escribe tu usuario."} = Sesion.conectar("   ", "1234")

      assert {:error, "El usuario no puede tener espacios."} =
               Sesion.conectar("ana maria", "1234")

      assert {:error, "El usuario debe tener entre 3 y 20 caracteres."} =
               Sesion.conectar("an", "1234")
    end

    test "la contraseña es obligatoria" do
      assert {:error, "Escribe tu contraseña."} = Sesion.conectar("laura", "")
    end
  end

  describe "registrar/5" do
    test "exige una contraseña de al menos 4 caracteres" do
      assert {:error, "La contraseña debe tener al menos 4 caracteres."} =
               Sesion.registrar("nuevo_usuario", "123", "Laura Gómez", "ciudadano", "Centro")
    end

    test "solo permite ciudadano o voluntario" do
      for rol <- ["coordinador", "administrador", "jefe"] do
        assert {:error, "Al registrarte solo puedes ser ciudadano o voluntario."} =
                 Sesion.registrar("nuevo_usuario", "1234", "Laura Gómez", rol, "Centro")
      end
    end

    test "el nombre completo es obligatorio y de 3 a 60 caracteres" do
      assert {:error, "Escribe tu nombre completo."} =
               Sesion.registrar("nuevo_usuario", "1234", "  ", "ciudadano", "Centro")

      assert {:error, "El nombre completo debe tener entre 3 y 60 caracteres."} =
               Sesion.registrar("nuevo_usuario", "1234", "Al", "ciudadano", "Centro")
    end

    test "la zona se elige por nombre y debe existir" do
      assert {:error, "Zona no válida."} =
               Sesion.registrar("nuevo_usuario", "1234", "Laura Gómez", "voluntario", "marte")

      assert {:error, "Zona no válida."} =
               Sesion.registrar(
                 "nuevo_usuario",
                 "1234",
                 "Laura Gómez",
                 "voluntario",
                 "A1F03C9E7B2D4410"
               )
    end
  end
end
