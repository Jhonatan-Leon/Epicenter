defmodule Epicenter.GenserverTest do
  use ExUnit.Case, async: true

  test "inicia bajo la aplicación y responde a las consultas de usuarios" do
    assert is_pid(Process.whereis(Epicenter.Genserver))
    assert {:ok, usuarios} = Epicenter.Genserver.listar()
    assert is_list(usuarios)
  end
end
