defmodule ST7735.Backlight do
  @moduledoc false

  use GenServer

  @gpio_mod Application.compile_env(:st7735, :gpio_mod, ST7735.GPIO.Circuits)

  @off 0
  @on 1

  def start_link(pin_number) do
    GenServer.start_link(__MODULE__, pin_number)
  end

  def off(pid) do
    GenServer.cast(pid, :off)
  end

  def on(pid) do
    GenServer.cast(pid, :on)
  end

  @impl GenServer
  def init(pin_number) do
    case @gpio_mod.open(pin_number, :output, initial_value: @on) do
      {:ok, gpio} -> {:ok, gpio}
      error -> {:stop, error}
    end
  end

  @impl GenServer
  def handle_cast(:off, gpio) do
    @gpio_mod.write(gpio, @off)
    {:noreply, gpio}
  end

  def handle_cast(:on, gpio) do
    @gpio_mod.write(gpio, @on)
    {:noreply, gpio}
  end
end
