defmodule EnviroFirmware do
  @moduledoc """
  Documentation for EnviroFirmware.
  """

  @doc """
  Hello world.

  ## Examples

      iex> EnviroFirmware.hello
      :world

  """
  def hello do
    :world
  end

  if Code.ensure_loaded?(Bme280) do
    def bme280, do: Bme280.measure(EnviroFirmware.Bme280)
  end
end
