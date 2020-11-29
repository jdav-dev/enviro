defmodule ST7735.SPI do
  @moduledoc false

  @type spi_bus :: any()

  @callback open(binary(), Keyword.t()) :: {:ok, spi_bus()} | {:error, any()}
  @callback transfer(spi_bus(), binary()) :: {:ok, binary()} | {:error, any()}
end
