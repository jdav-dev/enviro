defmodule ST7735.GPIO do
  @moduledoc false

  @type pin_number :: non_neg_integer()
  @type pin_direction :: :input | :output
  @type gpio :: any()

  @callback open(pin_number(), pin_direction(), Keyword.t()) :: {:ok, gpio()} | {:error, any()}
  @callback write(gpio(), 0 | 1) :: :ok
end
