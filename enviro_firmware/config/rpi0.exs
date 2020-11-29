import Config

config :enviro_display, :viewport, %{
  name: :main_viewport,
  size: {160, 80},
  default_scene: {EnviroDisplay.Scene.Home, nil},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    }
  ]
}
