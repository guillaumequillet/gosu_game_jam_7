class Map
  attr_reader :width, :height
  def initialize(scene, width, height, tile_size)
    @scene = scene
    @width, @height = width, height
    @tile_size = tile_size
    @tileset = Gosu::Image.load_tiles("gfx/tileset.png", @tile_size, @tile_size, retro: true)
  end

  def pixel_width; @width * @tile_size; end
  def pixel_height; @height * @tile_size; end

  def get_center
    [(@width * @tile_size) / 2.0, (@height * @tile_size) / 2.0]
  end

  def update

  end

  def draw
    @record ||= Gosu.render(self.pixel_width, self.pixel_height, retro: false) do
      @height.times do |x|
        @height.times do |y|
          # floor asset
          tile = (4..7).to_a.sample
          
          # wall asset
          tile = 1 if (x == 0 || x == @width - 1 || y == 0 || y == @height - 1) 
          @tileset[tile].draw(x * @tile_size, y * @tile_size, 0)
        end
      end
      # power plug
      x, y = (@width / 2).floor, (@height / 2).floor 
      @tileset[0].draw((x - 0.5) * @tile_size, (y - 0.5) * @tile_size, 0)
    end
    @record.draw(0, 0, 0)
  end
end