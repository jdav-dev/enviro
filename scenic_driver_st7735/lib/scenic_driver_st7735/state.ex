defmodule ScenicDriverST7735.State do
  @moduledoc false

  @enforce_keys [:capture, :refresh_interval, :st7735]
  defstruct [:capture, :refresh_interval, :last_crc, :st7735, :data]
end
