if Code.ensure_loaded?(Circuits.SPI) do
  defmodule ST7735.SPI.Circuits do
    @moduledoc false

    @behaviour ST7735.SPI

    defdelegate open(spi_bus, opts), to: Circuits.SPI
    defdelegate transfer(spi_bus, binary), to: Circuits.SPI
  end
end
