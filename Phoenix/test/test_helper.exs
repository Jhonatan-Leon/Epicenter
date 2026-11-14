datos_base = Path.expand("../../epicenter/lib/Datos", __DIR__)
datos_prueba = Path.join(System.tmp_dir!(), "epicenter_phoenix_test_#{System.pid()}")
File.mkdir_p!(datos_prueba)

datos_base
|> Path.join("*.json")
|> Path.wildcard()
|> Enum.each(fn archivo -> File.cp!(archivo, Path.join(datos_prueba, Path.basename(archivo))) end)

Application.put_env(:epicenter, :ruta_datos, datos_prueba)
ExUnit.after_suite(fn _resultado -> File.rm_rf!(datos_prueba) end)

ExUnit.start()
