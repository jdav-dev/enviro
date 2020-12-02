defmodule ScenicDriverST7735.MixProject do
  use Mix.Project

  @all_targets [:rpi0]

  def project do
    [
      app: :scenic_driver_st7735,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic, "~> 0.10.3"},

      # Dependencies for all targets except :host
      {:scenic_driver_nerves_rpi, "~> 0.10.1", targets: @all_targets},
      {:rpi_fb_capture, "~> 0.3.0", targets: @all_targets},
      {:st7735, path: "../st7735", targets: @all_targets}
    ]
  end
end
