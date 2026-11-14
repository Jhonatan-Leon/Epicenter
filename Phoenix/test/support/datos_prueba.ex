defmodule InterfazWeb.DatosPrueba do
  @moduledoc """
  Ayuda para los tests que escriben en los JSON de la lógica.

  Los JSON viven en la carpeta temporal que arma `test_helper.exs`
  (`Epicenter.Persistencia.ruta_datos/1`), nunca en `epicenter/lib/Datos`.
  """

  import ExUnit.Callbacks, only: [on_exit: 1]

  @doc """
  Deja vacíos los `archivos` indicados, agrega los `usuarios` de prueba a
  Usuario.json y restaura todo al terminar el test.
  """
  def preparar(archivos, usuarios \\ []) do
    respaldar(["Usuario.json" | archivos])

    for archivo <- archivos, do: File.write!(ruta(archivo), "[]")
    agregar_usuarios(usuarios)
    :ok
  end

  @doc "Usuario de prueba con el formato que guarda la lógica."
  def usuario(nombre_usuario, rol, zona) do
    %{
      "nombre_usuario" => nombre_usuario,
      "contrasena" => "clave",
      "rol" => rol,
      "nombre_completo" => String.capitalize(nombre_usuario),
      "zona_principal" => zona
    }
  end

  defp respaldar(archivos) do
    originales = for archivo <- archivos, do: {archivo, File.read!(ruta(archivo))}

    on_exit(fn ->
      for {archivo, contenido} <- originales, do: File.write!(ruta(archivo), contenido)
    end)
  end

  defp agregar_usuarios([]), do: :ok

  defp agregar_usuarios(usuarios) do
    nombres = Enum.map(usuarios, & &1["nombre_usuario"])

    existentes =
      ruta("Usuario.json")
      |> File.read!()
      |> Jason.decode!()
      |> Enum.reject(&(&1["nombre_usuario"] in nombres))

    File.write!(ruta("Usuario.json"), Jason.encode!(usuarios ++ existentes))
  end

  defp ruta(archivo), do: Epicenter.Persistencia.ruta_datos(archivo)
end
