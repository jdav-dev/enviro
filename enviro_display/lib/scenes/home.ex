defmodule EnviroDisplay.Scene.Home do
  use Scenic.Scene

  import Scenic.Primitives
  # import Scenic.Components

  alias Scenic.Graph
  # alias Scenic.ViewPort

  require Logger

  # @note """
  #   This is a very simple starter application.

  #   If you want a more full-on example, please start from:

  #   mix scenic.new.example
  # """

  @text_size 24

  # ============================================================================
  # setup

  # --------------------------------------------------------
  @impl Scenic.Scene
  def init(_, _opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    # {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    # show the version of scenic and the glfw driver
    # scenic_ver = Application.spec(:scenic, :vsn) |> to_string()
    # glfw_ver = Application.spec(:scenic_driver_glfw, :vsn) |> to_string()

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        time_spec(translate: {20, 40})
      ])

    Process.send_after(self(), :update_time, :timer.seconds(1))

    {:ok, graph, push: graph}
  end

  # @impl Scenic.Scene
  # def handle_input(event, _context, state) do
  #   Logger.info("Received event: #{inspect(event)}")
  #   {:noreply, state}
  # end

  defp time_spec(opts) do
    text_spec(Time.utc_now() |> Time.truncate(:second) |> Time.to_iso8601(), opts)
  end

  @impl Scenic.Scene
  def handle_info(:update_time, _graph) do
    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        time_spec(translate: {20, 40})
      ])

    Process.send_after(self(), :update_time, :timer.seconds(1))

    {:noreply, graph, push: graph}
  end
end
