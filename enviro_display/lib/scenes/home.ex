defmodule EnviroDisplay.Scene.Home do
  use Scenic.Scene

  import Scenic.Primitives

  alias Scenic.Graph
  alias Scenic.Sensor

  require Logger

  @text_size 12

  @graph Graph.build(font: :roboto, font_size: @text_size)
         |> text("time: 00:00:00",
           text_align: :left_top,
           rotate: 270 * (:math.pi() / 180),
           translate: {0 * @text_size + 4, 156},
           id: :time
         )
         |> text("humidity: 0.0",
           text_align: :left_top,
           rotate: 270 * (:math.pi() / 180),
           translate: {1 * @text_size + 4, 156},
           id: :humidity
         )
         |> text("lux: 0.0",
           text_align: :left_top,
           rotate: 270 * (:math.pi() / 180),
           translate: {2 * @text_size + 4, 156},
           id: :lux
         )
         |> text("pressure: 0.0",
           text_align: :left_top,
           rotate: 270 * (:math.pi() / 180),
           translate: {3 * @text_size + 4, 156},
           id: :pressure
         )
         |> text("proximity: 0",
           text_align: :left_top,
           rotate: 270 * (:math.pi() / 180),
           translate: {4 * @text_size + 4, 156},
           id: :proximity
         )
         |> text("temperature: 0.0",
           text_align: :left_top,
           rotate: 270 * (:math.pi() / 180),
           translate: {5 * @text_size + 4, 156},
           id: :temperature
         )

  @impl Scenic.Scene
  def init(_, _opts) do
    Sensor.subscribe(:humidity)
    Sensor.subscribe(:lux)
    Sensor.subscribe(:pressure)
    Sensor.subscribe(:proximity)
    Sensor.subscribe(:temperature)

    send(self(), :update_time)
    {:ok, @graph, push: @graph}
  end

  @impl Scenic.Scene
  def handle_info(:update_time, graph) do
    Process.send_after(self(), :update_time, :timer.seconds(1))

    modified_graph =
      graph
      |> Graph.modify(
        :time,
        &text(&1, "time: #{Time.utc_now() |> Time.truncate(:second) |> Time.to_iso8601()}")
      )

    {:noreply, modified_graph, push: modified_graph}
  end

  def handle_info({:sensor, registered, _sensor}, graph)
      when registered in [:registered, :unregistered] do
    {:noreply, graph}
  end

  def handle_info({:sensor, :data, {:humidity, data, _timestamp}}, graph) do
    modified_graph =
      graph
      |> Graph.modify(
        :humidity,
        &text(&1, "humidity: #{data}")
      )

    {:noreply, modified_graph, push: modified_graph}
  end

  def handle_info({:sensor, :data, {:lux, data, _timestamp}}, graph) do
    modified_graph =
      graph
      |> Graph.modify(
        :lux,
        &text(&1, "lux: #{data}")
      )

    {:noreply, modified_graph, push: modified_graph}
  end

  def handle_info({:sensor, :data, {:pressure, data, _timestamp}}, graph) do
    modified_graph =
      graph
      |> Graph.modify(
        :pressure,
        &text(&1, "pressure: #{data}")
      )

    {:noreply, modified_graph, push: modified_graph}
  end

  def handle_info({:sensor, :data, {:proximity, data, _timestamp}}, graph) do
    modified_graph =
      graph
      |> Graph.modify(
        :proximity,
        &text(&1, "proximity: #{data}")
      )

    {:noreply, modified_graph, push: modified_graph}
  end

  def handle_info({:sensor, :data, {:temperature, data, _timestamp}}, graph) do
    modified_graph =
      graph
      |> Graph.modify(
        :temperature,
        &text(&1, "temperature: #{data}")
      )

    {:noreply, modified_graph, push: modified_graph}
  end
end
