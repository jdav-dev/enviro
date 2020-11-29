defmodule ST7735.FakeGpio do
  @moduledoc false

  @behaviour ST7735.GPIO

  def open(_pin_number, _direction, opts) do
    initial_value = Keyword.get(opts, :initial_value)
    Agent.start_link(fn -> initial_value end)
  end

  def write(pid, value) when value in [0, 1] do
    Agent.update(pid, fn _previous_value -> value end)
  end
end
