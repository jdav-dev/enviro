defmodule ST7735.Commands do
  @moduledoc false

  import ST7735.DataCommandSelection, only: [command_mode: 1]

  alias ST7735.State

  @spi_mod Application.compile_env(:st7735, :spi_mod, ST7735.SPI.Circuits)

  @commands [
    {"NOP", 0x00},
    {"SWRESET", 0x01},
    {"RDDID", 0x04},
    {"RDDST", 0x09},
    {"SLPIN", 0x10},
    {"SLPOUT", 0x11},
    {"PTLON", 0x12},
    {"NORON", 0x13},
    {"INVOFF", 0x20},
    {"INVON", 0x21},
    {"DISPOFF", 0x28},
    {"DISPON", 0x29},
    {"CASET", 0x2A},
    {"RASET", 0x2B},
    {"RAMWR", 0x2C},
    {"RAMRD", 0x2E},
    {"PTLAR", 0x30},
    {"MADCTL", 0x36},
    {"COLMOD", 0x3A},
    {"FRMCTR1", 0xB1},
    {"FRMCTR2", 0xB2},
    {"FRMCTR3", 0xB3},
    {"INVCTR", 0xB4},
    {"DISSET5", 0xB6},
    {"PWCTR1", 0xC0},
    {"PWCTR2", 0xC1},
    {"PWCTR3", 0xC2},
    {"PWCTR4", 0xC3},
    {"PWCTR5", 0xC4},
    {"VMCTR1", 0xC5},
    {"RDID1", 0xDA},
    {"RDID2", 0xDB},
    {"RDID3", 0xDC},
    {"RDID4", 0xDD},
    {"GMCTRP1", 0xE0},
    {"GMCTRN1", 0xE1},
    {"PWCTR6", 0xFC}
  ]

  for {name, data} <- @commands do
    atom_name = name |> String.downcase() |> String.to_atom()

    def unquote(atom_name)(%State{
          data_command_selection: data_command_selection,
          spi_bus: spi_bus
        }) do
      command_mode(data_command_selection)
      @spi_mod.transfer(spi_bus, unquote(<<data>>))
    end
  end
end