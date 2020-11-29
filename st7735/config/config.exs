import Config

if Mix.env() == :test do
  config :st7735, :gpio_mod, ST7735.FakeGpio
  config :st7735, :spi_mod, ST7735.FakeSpi
end
