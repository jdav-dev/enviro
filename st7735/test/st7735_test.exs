defmodule ST7735Test do
  use ExUnit.Case

  alias ST7735.ExpectedData
  alias ST7735.FakeSpi
  alias ST7735.State

  doctest ST7735

  describe "handle_call/3" do
    setup :init

    test ":set_window sends the expected bytes over SPI", %{state: state} do
      {:reply, :ok, %State{spi_bus: spi_bus}} = ST7735.handle_call(:set_window, nil, state)
      assert FakeSpi.flush_transfers(spi_bus) == ExpectedData.set_window()
    end
  end

  describe "handle_continue/2" do
    setup :init

    test ":init_display sends the expected bytes over SPI", %{state: state} do
      {:noreply, %State{spi_bus: spi_bus}} = ST7735.handle_continue(:init_display, state)
      assert FakeSpi.flush_transfers(spi_bus) == ExpectedData.init_display()
    end
  end

  defp init(_) do
    {:ok, initial_state, _continue} = ST7735.init()
    {:ok, state: initial_state}
  end
end
