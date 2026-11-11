defmodule Epicenter.GestorMensajeFamiliaTest do
  use ExUnit.Case, async: false

  alias Epicenter.{GestorMensaje, GestorPersona}

  setup do
    rutas = [
      Path.expand("../lib/Datos/Mensaje.json", __DIR__),
      Path.expand("../lib/Datos/Persona.json", __DIR__)
    ]

    contenidos = Enum.map(rutas, &File.read!/1)
    Enum.each(rutas, &File.write!(&1, "[]"))

    on_exit(fn ->
      Enum.zip(rutas, contenidos) |> Enum.each(fn {ruta, contenido} -> File.write!(ruta, contenido) end)
    end)

    {:ok, _} = GestorPersona.reportar_persona("1094887123", "Andrés Gómez", 34, "zona_norte", "en_albergue")
    {:ok, _} = GestorPersona.reportar_persona("41923554", "María López", 67, "centro", "sin_informacion")

    :ok
  end

  describe "enviar/3" do
    test "crea un mensaje pendiente con fecha, remitente, destinatario y contenido" do
      assert {:ok, mensaje} =
               GestorMensaje.enviar("Carmen Gómez (hermana)", "1094887123", " Te estamos buscando ")

      assert mensaje.remitente == "Carmen Gómez (hermana)"
      assert mensaje.destinatario == "1094887123"
      assert mensaje.contenido == "Te estamos buscando"
      assert mensaje.estado == :pendiente
      assert %DateTime{} = mensaje.fecha_envio
    end

    test "se guarda y se recupera con su estado y su fecha" do
      {:ok, mensaje} = GestorMensaje.enviar("Carmen", "1094887123", "Hola")

      assert {:ok, recuperado} = GestorMensaje.obtener(mensaje.codigo)
      assert recuperado.estado == :pendiente
      assert %DateTime{} = recuperado.fecha_envio
    end

    test "rechaza un destinatario que no es una persona reportada" do
      assert {:error, "Persona no encontrada"} = GestorMensaje.enviar("Carmen", "999", "Hola")
      assert {:ok, []} = GestorMensaje.listar()
    end

    test "rechaza campos vacíos" do
      assert {:error, :remitente_vacio} = GestorMensaje.enviar(" ", "1094887123", "Hola")
      assert {:error, :destinatario_vacio} = GestorMensaje.enviar("Carmen", "", "Hola")
      assert {:error, :contenido_vacio} = GestorMensaje.enviar("Carmen", "1094887123", "   ")
      assert {:error, :contenido_vacio} = GestorMensaje.enviar("Carmen", "1094887123", nil)
    end
  end

  describe "listar_por_persona/1" do
    test "devuelve solo los mensajes de esa persona, del más reciente al más antiguo" do
      {:ok, primero} = GestorMensaje.enviar("Carmen", "1094887123", "Primero")
      {:ok, _otra} = GestorMensaje.enviar("Familia López", "41923554", "Mamá, llama")
      {:ok, segundo} = GestorMensaje.enviar("Carmen", "1094887123", "Segundo")

      assert {:ok, [uno, dos]} = GestorMensaje.listar_por_persona("1094887123")
      assert {uno.codigo, dos.codigo} == {segundo.codigo, primero.codigo}
    end

    test "una persona sin mensajes devuelve una lista vacía" do
      assert {:ok, []} = GestorMensaje.listar_por_persona("41923554")
    end

    test "rechaza un documento vacío" do
      assert {:error, :destinatario_vacio} = GestorMensaje.listar_por_persona("")
    end
  end

  describe "marcar/2" do
    test "marca un mensaje como entregado y lo guarda" do
      {:ok, mensaje} = GestorMensaje.enviar("Carmen", "1094887123", "Hola")

      assert {:ok, %{estado: :entregado}} = GestorMensaje.marcar(mensaje.codigo, :entregado)
      assert {:ok, %{estado: :entregado}} = GestorMensaje.obtener(mensaje.codigo)
    end

    test "acepta el estado como texto y permite volver a pendiente" do
      {:ok, mensaje} = GestorMensaje.enviar("Carmen", "1094887123", "Hola")

      assert {:ok, %{estado: :entregado}} = GestorMensaje.marcar(mensaje.codigo, "entregado")
      assert {:ok, %{estado: :pendiente}} = GestorMensaje.marcar(mensaje.codigo, "pendiente")
    end

    test "solo cambia el mensaje indicado" do
      {:ok, uno} = GestorMensaje.enviar("Carmen", "1094887123", "Uno")
      {:ok, dos} = GestorMensaje.enviar("Carmen", "1094887123", "Dos")

      {:ok, _} = GestorMensaje.marcar(uno.codigo, :entregado)

      assert {:ok, %{estado: :pendiente}} = GestorMensaje.obtener(dos.codigo)
    end

    test "rechaza un estado inválido o un mensaje que no existe" do
      {:ok, mensaje} = GestorMensaje.enviar("Carmen", "1094887123", "Hola")

      assert {:error, :estado_invalido} = GestorMensaje.marcar(mensaje.codigo, :leido)
      assert {:error, :estado_invalido} = GestorMensaje.marcar(mensaje.codigo, nil)
      assert {:error, "Mensaje no encontrado"} = GestorMensaje.marcar("no-existe", :entregado)
    end
  end
end
