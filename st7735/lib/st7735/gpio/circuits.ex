if Code.ensure_loaded?(Circuits.GPIO) do
  defmodule ST7735.GPIO.Circuits do
    @moduledoc false

    @behaviour ST7735.GPIO

    defdelegate open(pin_number, direction, opts), to: Circuits.GPIO
    defdelegate write(gpio, value), to: Circuits.GPIO
  end
end
