defmodule ST7735.DataCommandSelection do
  @moduledoc false

  use GenServer

  @gpio_mod Application.compile_env(:st7735, :gpio_mod, ST7735.GPIO.Circuits)

  @command_mode 0
  @data_mode 1

  def start_link(pin_number) do
    GenServer.start_link(__MODULE__, pin_number)
  end

  def command_mode(pid) do
    GenServer.call(pid, :command_mode)
  end

  def data_mode(pid) do
    GenServer.call(pid, :data_mode)
  end

  @impl GenServer
  def init(pin_number) do
    case @gpio_mod.open(pin_number, :output, initial_value: @data_mode) do
      {:ok, gpio} -> {:ok, gpio}
      error -> {:stop, error}
    end
  end

  @impl GenServer
  def handle_call(:command_mode, _from, gpio) do
    @gpio_mod.write(gpio, @command_mode)
    {:reply, :ok, gpio}
  end

  def handle_call(:data_mode, _from, gpio) do
    @gpio_mod.write(gpio, @data_mode)
    {:reply, :ok, gpio}
  end
end
