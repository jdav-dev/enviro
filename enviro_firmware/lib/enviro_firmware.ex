defmodule EnviroFirmware do
  @moduledoc """
  Documentation for EnviroFirmware.
  """

  if Code.ensure_loaded?(Bme280) do
    def bme280, do: Bme280.measure(EnviroFirmware.Bme280)
  end

  if Code.ensure_loaded?(Bme280) and Code.ensure_loaded?(Circuits.I2C) do
    def get_readings do
      EnviroFirmware.Bme280
      |> Bme280.measure()
      |> Map.from_struct()
      |> Map.merge(EnviroFirmware.Ltr559.get_readings())
    end
  end
end
