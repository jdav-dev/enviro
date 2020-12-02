defmodule EnviroDisplay.MixProject do
  use Mix.Project

  @all_targets [:rpi0]

  def project do
    [
      app: :enviro_display,
      version: "0.1.0",
      elixir: "~> 1.11",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {EnviroDisplay.Application, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10.3"},
      {:scenic_sensor, "~> 0.7.0"},
      {:scenic_driver_glfw, "~> 0.10.1", targets: :host},
      {:scenic_driver_nerves_rpi, "~> 0.10.1", targets: @all_targets}
    ]
  end
end
