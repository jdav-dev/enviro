defmodule ST7735.State do
  @moduledoc false

  @enforce_keys [
    :backlight,
    :data_command_selection,
    :height,
    :invert,
    :offset_left,
    :offset_top,
    :spi_buffer_size,
    :spi_bus,
    :width
  ]
  defstruct @enforce_keys
end
