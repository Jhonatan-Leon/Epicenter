defmodule Epicenter.Persistencia do
  @path "epicenter/lib/Datos/Usuario.txt"

  def cargar_usuarios do
    File.read!(@path)
    |> String.split("\n")
    |> Enum.filter(fn linea -> String.trim(linea) end)
    |> Enum.reject(fn linea -> linea == "" end)
    |> Enum.map(fn linea ->
      [nombre_usuario, contraseña, nombre_completo, zona_principal, rol] = String.split(linea, ";")
      {:ok, usuario} = Epicenter.Usuario.nuevo(nombre_usuario, contraseña, nombre_completo, zona_principal, String.to_atom(rol))
      usuario
    end)
  end

  def guardar_usuarios(usuarios) do
    contenido = Enum.map(usuarios, fn usuario ->
      "#{usuario.nombre_usuario};#{usuario.contraseña};#{usuario.nombre_completo};#{usuario.zona_principal};#{Enum.join(usuario.rol, ",")}"
    end)
    |> Enum.join("\n")

    File.write!(@path, contenido)
  end
end
