defmodule ST7735 do
  @moduledoc """
  Documentation for `ST7735`.
  """

  use GenServer

  import ST7735.Commands
  import ST7735.DataCommandSelection, only: [data_mode: 1]

  alias ST7735.Backlight
  alias ST7735.DataCommandSelection
  alias ST7735.State

  @spi_mod Application.compile_env(:st7735, :spi_mod, ST7735.SPI.Circuits)

  @default_spi_bus_name "spidev0.1"
  @default_spi_speed_hz 10_000_000
  @default_dc_pin_number 9
  @default_backlight_pin_number 12
  @default_spi_buffer_size 4096

  @default_width 80
  @default_height 160
  @default_invert true

  @st7735_cols 132
  @st7735_rows 162

  def start_link(opts) do
    {name, st7735_opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, st7735_opts, name: name)
  end

  def display(server \\ __MODULE__, data) when is_binary(data) do
    GenServer.cast(server, {:display, data})
  end

  @impl GenServer
  def init(opts \\ []) do
    spi_bus_name = opts[:spi_bus_name] || @default_spi_bus_name
    spi_speed_hz = opts[:spi_speed_hz] || @default_spi_speed_hz
    spi_buffer_size = opts[:spi_buffer_size] || read_spi_buffer_size()
    dc_pin_number = opts[:dc_pin_number] || @default_dc_pin_number

    backlight_pin_number = opts[:backlight_pin_number] || @default_backlight_pin_number

    width = opts[:width] || @default_width
    height = opts[:height] || @default_height
    invert = opts[:invert] || @default_invert
    offset_left = opts[:offset_left] || div(@st7735_cols - width, 2)
    offset_top = opts[:offset_top] || div(@st7735_rows - height, 2)

    with {:ok, data_command_selection} <- DataCommandSelection.start_link(dc_pin_number),
         {:ok, backlight} <- Backlight.start_link(backlight_pin_number),
         {:ok, spi_bus} <- @spi_mod.open(spi_bus_name, speed_hz: spi_speed_hz) do
      initial_state = %State{
        backlight: backlight,
        data_command_selection: data_command_selection,
        height: height,
        invert: invert,
        offset_left: offset_left,
        offset_top: offset_top,
        spi_buffer_size: spi_buffer_size,
        spi_bus: spi_bus,
        width: width
      }

      {:ok, initial_state, {:continue, :init_display}}
    end
  end

  defp read_spi_buffer_size do
    with {:ok, binary} <- File.read("/sys/module/spidev/parameters/bufsiz"),
         {spi_buffer_size, _} <- Integer.parse(binary) do
      spi_buffer_size
    else
      _ -> @default_spi_buffer_size
    end
  end

  @impl GenServer
  def handle_call(:set_window, _from, state) do
    set_window(state)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast({:display, data}, state) do
    set_window(state)

    case data(data, state) do
      {:ok, _} -> {:noreply, state}
      error -> {:stop, error, state}
    end
  end

  @impl GenServer
  def handle_continue(
        :init_display,
        %State{
          height: height,
          invert: invert,
          offset_left: offset_left,
          offset_top: offset_top,
          width: width
        } = state
      ) do
    # Software reset
    swreset(state)
    Process.sleep(150)

    # Out of sleep mode
    slpout(state)
    Process.sleep(500)

    # Frame rate ctrl - normal mode
    frmctr1(state)
    # Rate = fosc/(1x2+40) * (LINE+2C+2D)
    data(0x01, state)
    data(0x2C, state)
    data(0x2D, state)

    # Frame rate ctrl - idle mode
    frmctr2(state)
    # Rate = fosc/(1x2+40) * (LINE+2C+2D)
    data(0x01, state)
    data(0x2C, state)
    data(0x2D, state)

    # Frame rate ctrl - partial mode
    frmctr3(state)
    # Dot inversion mode
    data(0x01, state)
    data(0x2C, state)
    data(0x2D, state)
    # Line inversion mode
    data(0x01, state)
    data(0x2C, state)
    data(0x2D, state)

    # Display inversion ctrl
    invctr(state)
    # No inversion
    data(0x07, state)

    # Power control
    pwctr1(state)
    data(0xA2, state)
    # -4.6V
    data(0x02, state)
    # auto mode
    data(0x84, state)

    # Power control
    pwctr2(state)
    # Opamp current small
    data(0x0A, state)
    # Boost frequency
    data(0x00, state)

    # Power control
    pwctr4(state)
    # BCLK/2, Opamp current small & Medium low
    data(0x8A, state)
    data(0x2A, state)

    # Power control
    pwctr5(state)
    data(0x8A, state)
    data(0xEE, state)

    # Power control
    vmctr1(state)
    data(0x0E, state)

    case invert do
      true -> invon(state)
      false -> invoff(state)
    end

    # Memory access control (directions)
    madctl(state)
    # row addr/col addr, bottom to top refresh
    data(0xC8, state)

    # set color mode
    colmod(state)
    # 16-bit color
    data(0x05, state)

    # Column addr set
    caset(state)
    # XSTART = 0
    data(0x00, state)
    data(offset_left, state)
    # XEND = ROWS - height
    data(0x00, state)
    data(width + offset_left - 1, state)

    # Row addr set
    raset(state)
    # XSTART = 0
    data(0x00, state)
    data(offset_top, state)
    # XEND = COLS - width
    data(0x00, state)
    data(height + offset_top - 1, state)

    # Set Gamma
    gmctrp1(state)
    data(0x02, state)
    data(0x1C, state)
    data(0x07, state)
    data(0x12, state)
    data(0x37, state)
    data(0x32, state)
    data(0x29, state)
    data(0x2D, state)
    data(0x29, state)
    data(0x25, state)
    data(0x2B, state)
    data(0x39, state)
    data(0x00, state)
    data(0x01, state)
    data(0x03, state)
    data(0x10, state)

    # Set Gamma
    gmctrn1(state)
    data(0x03, state)
    data(0x1D, state)
    data(0x07, state)
    data(0x06, state)
    data(0x2E, state)
    data(0x2C, state)
    data(0x29, state)
    data(0x2D, state)
    data(0x2E, state)
    data(0x2E, state)
    data(0x37, state)
    data(0x3F, state)
    data(0x00, state)
    data(0x00, state)
    data(0x02, state)
    data(0x10, state)

    # Normal display on
    noron(state)
    Process.sleep(10)

    # Display on
    dispon(state)
    Process.sleep(100)

    {:noreply, state}
  end

  defp set_window(
         %State{
           height: height,
           offset_left: offset_left,
           offset_top: offset_top,
           width: width
         } = state
       ) do
    x0 = offset_left
    x1 = width - 1 + offset_left

    y0 = offset_top
    y1 = height - 1 + offset_top

    # Column addr set
    caset(state)
    # XSTART and XEND
    data(<<x0::16, x1::16>>, state)

    # Row addr set
    raset(state)
    # YSTART and YEND
    data(<<y0::16, y1::16>>, state)

    # write to RAM
    ramwr(state)
  end

  defp data(data, state) when is_integer(data) and 0 <= data and data <= 255 do
    data(<<data>>, state)
  end

  defp data(data, %State{spi_buffer_size: spi_buffer_size} = state)
       when is_binary(data) and byte_size(data) > spi_buffer_size do
    data
    |> :erlang.binary_to_list()
    |> Enum.chunk_every(spi_buffer_size)
    |> Enum.map(&:erlang.list_to_binary/1)
    |> Enum.reduce_while({:ok, ""}, fn
      chunk, {:ok, _} -> {:cont, data(chunk, state)}
      _chunk, error -> {:halt, error}
    end)
  end

  defp data(data, %State{data_command_selection: data_command_selection, spi_bus: spi_bus})
       when is_binary(data) do
    data_mode(data_command_selection)
    @spi_mod.transfer(spi_bus, data)
  end
end
