defmodule ScenicDriverST7735 do
  @moduledoc """
  Documentation for `ScenicDriverST7735`.
  """

  use Scenic.ViewPort.Driver

  alias RpiFbCapture.Capture
  alias Scenic.ViewPort.Driver
  alias ScenicDriverST7735.State

  require Logger

  @default_refresh_interval 100

  @impl Scenic.ViewPort.Driver
  def init(viewport, {width, height} = size, opts) do
    vp_supervisor = vp_supervisor(viewport)

    with {:ok, _} <-
           Driver.start_link({vp_supervisor, size, %{module: Scenic.Driver.Nerves.Rpi}}),
         {:ok, st7735} <- ST7735.start_link(height: height, width: width),
         {:ok, capture} <- RpiFbCapture.start_link(display: 0, height: height, width: width) do
      initial_state = %State{
        capture: capture,
        refresh_interval: opts[:refresh_interval] || @default_refresh_interval,
        st7735: st7735
      }

      send(self(), :capture)
      {:ok, initial_state}
    else
      error -> {:stop, error}
    end
  end

  defp vp_supervisor(viewport) do
    [supervisor_pid | _] =
      viewport
      |> Process.info()
      |> get_in([:dictionary, :"$ancestors"])

    supervisor_pid
  end

  @impl Scenic.ViewPort.Driver
  def handle_info(
        :capture,
        %State{capture: capture, refresh_interval: refresh_interval, st7735: st7735} = state
      ) do
    Process.send_after(self(), :capture, refresh_interval)

    {:ok, %Capture{data: data}} = RpiFbCapture.capture(capture, :rgb565)

    crc = :erlang.crc32(data)

    if crc != state.last_crc do
      reversed_data =
        data
        |> :erlang.binary_to_list()
        |> Enum.reverse()
        |> :erlang.list_to_binary()

      ST7735.display(st7735, reversed_data)
    end

    {:noreply, %{state | data: data, last_crc: crc}}
  end

  @impl Scenic.ViewPort.Driver
  def handle_call(:get_data, _from, %{data: data} = state) do
    {:reply, data, state}
  end
end
