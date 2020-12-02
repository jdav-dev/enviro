if Code.ensure_loaded?(Circuits.I2C) do
  defmodule EnviroFirmware.Ltr559 do
    use GenServer

    alias Circuits.I2C
    alias Scenic.Sensor

    @bus "i2c-1"
    @address 0x23
    @part_id 0x09
    @revision 0x02

    def start_link(opts) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def get_readings do
      GenServer.call(__MODULE__, :get_readings)
    end

    @impl GenServer
    def init(_opts) do
      with :ok <- File.write("/sys/module/i2c_bcm2708/parameters/combined", "1"),
           {:ok, ref} <- I2C.open(@bus),
           :ok <- init_sensor(ref),
           {:ok, :lux} <- Sensor.register(:lux, "0.1.0", "light sensor"),
           {:ok, :proximity} <- Sensor.register(:proximity, "0.1.0", "proximity sensor") do
        send(self(), :update_sensor)
        {:ok, %{lux: nil, proximity: nil, ref: ref}}
      else
        error -> {:stop, error}
      end
    end

    defp init_sensor(ref) do
      with :ok <- check_sensor(ref),
           :ok <- reset_sensor(ref),
           :ok <- configure_ps_led(ref),
           :ok <- configure_ps_pulses(ref),
           :ok <- enable_als(ref),
           :ok <- enable_ps(ref),
           :ok <- configure_als_measurement_rate(ref) do
        :ok
      end
    end

    defp check_sensor(ref) do
      register = <<0x86>>

      case I2C.write_read!(ref, @address, register, 1) do
        <<@part_id::4, @revision::4>> -> :ok
        _ -> {:error, "LTR559 not found"}
      end
    end

    defp reset_sensor(ref) do
      register = <<0x80>>
      reserved = 0b000
      als_gain = 0b000
      sw_reset = 0b1
      als_mode = 0b0
      data = <<reserved::3, als_gain::3, sw_reset::1, als_mode::1>>
      I2C.write!(ref, @address, register <> data)

      fn ->
        wait_for_sw_reset(ref)
      end
      |> Task.async()
      |> Task.await()
    end

    defp wait_for_sw_reset(ref) do
      register = <<0x80>>

      <<_reserved::3, _als_gain::3, sw_reset::1, _als_mode::1>> =
        I2C.write_read!(ref, @address, register, 1)

      case sw_reset do
        0 ->
          :ok

        1 ->
          Process.sleep(50)
          wait_for_sw_reset(ref)
      end
    end

    defp configure_ps_led(ref) do
      register = <<0x82>>
      led_pulse_modulation_frequency = 0b000
      led_duty_cycle = 0b11
      led_current = 0b011
      data = <<led_pulse_modulation_frequency::3, led_duty_cycle::2, led_current::3>>
      I2C.write!(ref, @address, register <> data)
    end

    defp configure_ps_pulses(ref) do
      register = <<0x83>>
      reserved = 0
      count = 1
      data = <<reserved::4, count::4>>
      I2C.write!(ref, @address, register <> data)
    end

    defp enable_als(ref) do
      register = <<0x80>>
      reserved = 0
      als_gain = 0b010
      sw_reset = 0
      als_mode = 1
      data = <<reserved::3, als_gain::3, sw_reset::1, als_mode::1>>
      I2C.write!(ref, @address, register <> data)
    end

    defp enable_ps(ref) do
      register = <<0x81>>
      reserved = 0
      ps_saturation_indicator_enable = 1
      active = 0b11
      data = <<reserved::2, ps_saturation_indicator_enable::1, reserved::3, active::2>>
      I2C.write!(ref, @address, register <> data)
    end

    defp configure_als_measurement_rate(ref) do
      register = <<0x85>>
      reserved = 0
      als_integration_time = 0b001
      als_measurement_rate = 0b000
      data = <<reserved::2, als_integration_time::3, als_measurement_rate::3>>
      I2C.write!(ref, @address, register <> data)
    end

    @impl GenServer
    def handle_call(:get_readings, _from, %{lux: lux, proximity: proximity} = state) do
      {:reply, %{lux: lux, proximity: proximity}, state}
    end

    @impl GenServer
    def handle_info(:update_sensor, %{lux: lux, proximity: proximity, ref: ref} = state) do
      <<
        _als_data_valid::1,
        _als_gain::3,
        _als_interrupt::1,
        als_data::1,
        _ps_interrupt::1,
        ps_data::1
      >> = I2C.write_read!(ref, @address, <<0x8C>>, 1)

      updated_lux =
        case als_data do
          0 ->
            lux

          1 ->
            updated_lux = read_lux(ref)
            Sensor.publish(:lux, updated_lux)
            updated_lux
        end

      updated_proximity =
        case ps_data do
          0 ->
            proximity

          1 ->
            updated_proximity = read_proximity(ref)
            Sensor.publish(:proximity, updated_proximity)
            updated_proximity
        end

      Process.send_after(self(), :update_sensor, :timer.seconds(1))
      {:noreply, %{state | lux: updated_lux, proximity: updated_proximity}}
    end

    defp read_lux(ref) do
      <<data_0::8, data_1::8, data_2::8, data_3::8>> = I2C.write_read!(ref, @address, <<0x88>>, 4)

      als_0 = :binary.decode_unsigned(<<data_1, data_0>>)
      als_1 = :binary.decode_unsigned(<<data_3, data_2>>)

      ratio =
        case als_0 + als_1 > 0 do
          true -> als_1 * 100 / (als_1 + als_0)
          false -> 101
        end

      {ch0_c, ch1_c} =
        case ratio do
          ratio when ratio < 45 -> {17743, -11059}
          ratio when ratio < 64 -> {42785, 19548}
          ratio when ratio < 85 -> {5926, -1185}
          _ratio -> {0, 0}
        end

      # TODO: These numbers are a bit magical. Figure out how to make this more clear and tie them
      # to where this is configured over I2C.
      integration_time = 50
      gain = 4

      lux = als_0 * ch0_c - als_1 * ch1_c
      lux = lux / (integration_time / 100)
      lux = lux / gain
      lux = lux / 10000

      lux
    end

    defp read_proximity(ref) do
      <<ps_data_low::8, _ps_saturation_flag::1, _reserved::4, ps_data_high::3>> =
        I2C.write_read!(ref, @address, <<0x8D>>, 2)

      :binary.decode_unsigned(<<0::5, ps_data_high::3, ps_data_low::8>>)
    end
  end
end
