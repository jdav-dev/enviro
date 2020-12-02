import Config

config :enviro_display, :viewport, %{
  name: :main_viewport,
  size: {80, 160},
  default_scene: {EnviroDisplay.Scene.Home, nil},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: ScenicDriverST7735
    }
  ]
}
