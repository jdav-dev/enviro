defmodule ST7735.FakeSpi do
  @moduledoc false

  @behaviour ST7735.SPI

  def open(_spi_bus, _opts) do
    Agent.start_link(fn -> [] end)
  end

  def transfer(pid, binary) do
    Agent.update(pid, fn acc ->
      [binary | acc]
    end)

    {:ok, ""}
  end

  def flush_transfers(pid) do
    Agent.get_and_update(pid, fn transfers ->
      {
        transfers |> Enum.reverse() |> :erlang.list_to_binary(),
        []
      }
    end)
  end
end
