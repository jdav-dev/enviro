if Code.ensure_loaded?(Bme280) do
  defmodule EnviroFirmware.Bme280 do
    use GenServer

    alias Bme280.Measurement
    alias Scenic.Sensor

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    @impl GenServer
    def init(_opts) do
      with {:ok, bme280} <- Bme280.start_link([], []),
           {:ok, :humidity} <- Sensor.register(:humidity, "0.1.0", "humidity sensor"),
           {:ok, :pressure} <- Sensor.register(:pressure, "0.1.0", "pressure sensor"),
           {:ok, :temperature} <- Sensor.register(:temperature, "0.1.0", "temperature sensor") do
        send(self(), :update_sensor)
        {:ok, bme280}
      end
    end

    @impl GenServer
    def handle_info(:update_sensor, bme280) do
      %Measurement{
        humidity: humidity,
        pressure: pressure,
        temperature: temperature
      } = Bme280.measure(bme280)

      Sensor.publish(:humidity, humidity)
      Sensor.publish(:pressure, pressure)
      Sensor.publish(:temperature, temperature)

      Process.send_after(self(), :update_sensor, :timer.seconds(1))

      {:noreply, bme280}
    end
  end
end
