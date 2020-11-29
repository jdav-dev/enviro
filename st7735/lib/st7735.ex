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
  @default_rotation 270
  @default_invert true

  @st7735_cols 132
  @st7735_rows 162

  def start_link(opts) do
    {name, st7735_opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, st7735_opts, name: name)
  end

  def display(server \\ __MODULE__, image) do
    GenServer.cast(server, {:display, image})
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
    rotation = opts[:rotation] || @default_rotation
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
        rotation: rotation,
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
  def handle_cast({:display, image}, state) do
    set_window(state)
    data(state, image)
    {:noreply, state}
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
    data(state, 0x01)
    data(state, 0x2C)
    data(state, 0x2D)

    # Frame rate ctrl - idle mode
    frmctr2(state)
    # Rate = fosc/(1x2+40) * (LINE+2C+2D)
    data(state, 0x01)
    data(state, 0x2C)
    data(state, 0x2D)

    # Frame rate ctrl - partial mode
    frmctr3(state)
    # Dot inversion mode
    data(state, 0x01)
    data(state, 0x2C)
    data(state, 0x2D)
    # Line inversion mode
    data(state, 0x01)
    data(state, 0x2C)
    data(state, 0x2D)

    # Display inversion ctrl
    invctr(state)
    # No inversion
    data(state, 0x07)

    # Power control
    pwctr1(state)
    data(state, 0xA2)
    # -4.6V
    data(state, 0x02)
    # auto mode
    data(state, 0x84)

    # Power control
    pwctr2(state)
    # Opamp current small
    data(state, 0x0A)
    # Boost frequency
    data(state, 0x00)

    # Power control
    pwctr4(state)
    # BCLK/2, Opamp current small & Medium low
    data(state, 0x8A)
    data(state, 0x2A)

    # Power control
    pwctr5(state)
    data(state, 0x8A)
    data(state, 0xEE)

    # Power control
    vmctr1(state)
    data(state, 0x0E)

    case invert do
      true -> invon(state)
      false -> invoff(state)
    end

    # Memory access control (directions)
    madctl(state)
    # row addr/col addr, bottom to top refresh
    data(state, 0xC8)

    # set color mode
    colmod(state)
    # 16-bit color
    data(state, 0x05)

    # Column addr set
    caset(state)
    # XSTART = 0
    data(state, 0x00)
    data(state, offset_left)
    # XEND = ROWS - height
    data(state, 0x00)
    data(state, width + offset_left - 1)

    # Row addr set
    raset(state)
    # XSTART = 0
    data(state, 0x00)
    data(state, offset_top)
    # XEND = COLS - width
    data(state, 0x00)
    data(state, height + offset_top - 1)

    # Set Gamma
    gmctrp1(state)
    data(state, 0x02)
    data(state, 0x1C)
    data(state, 0x07)
    data(state, 0x12)
    data(state, 0x37)
    data(state, 0x32)
    data(state, 0x29)
    data(state, 0x2D)
    data(state, 0x29)
    data(state, 0x25)
    data(state, 0x2B)
    data(state, 0x39)
    data(state, 0x00)
    data(state, 0x01)
    data(state, 0x03)
    data(state, 0x10)

    # Set Gamma
    gmctrn1(state)
    data(state, 0x03)
    data(state, 0x1D)
    data(state, 0x07)
    data(state, 0x06)
    data(state, 0x2E)
    data(state, 0x2C)
    data(state, 0x29)
    data(state, 0x2D)
    data(state, 0x2E)
    data(state, 0x2E)
    data(state, 0x37)
    data(state, 0x3F)
    data(state, 0x00)
    data(state, 0x00)
    data(state, 0x02)
    data(state, 0x10)

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
    # XSTART
    data(state, <<x0::16>>)
    # XEND
    data(state, <<x1::16>>)

    # Row addr set
    raset(state)
    # YSTART
    data(state, <<y0::16>>)
    # YEND
    data(state, <<y1::16>>)

    # write to RAM
    ramwr(state)
  end

  defp data(state, data) when is_integer(data) and 0 <= data and data <= 255 do
    data(state, <<data>>)
  end

  defp data(%State{spi_buffer_size: spi_buffer_size} = state, data)
       when is_binary(data) and byte_size(data) > spi_buffer_size do
    data
    |> :erlang.binary_to_list()
    |> Enum.chunk_every(spi_buffer_size)
    |> Enum.map(&:erlang.list_to_binary/1)
    |> Enum.reduce_while({:ok, ""}, fn
      chunk, {:ok, _} -> {:cont, data(state, chunk)}
      _chunk, error -> {:halt, error}
    end)
  end

  defp data(%State{data_command_selection: data_command_selection, spi_bus: spi_bus}, data)
       when is_binary(data) do
    data_mode(data_command_selection)
    @spi_mod.transfer(spi_bus, data)
  end
end
