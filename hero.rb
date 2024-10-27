class Hero
  attr_reader :x, :y, :size, :keys, :wire_length
  attr_accessor :collectors_angles, :attribs
  def initialize(scene, coords)
    @scene = scene
    @x, @y = *coords
    @size = 32
    @tile_size = 32
    @angle = 0

    @keys = {
      up: [Gosu::KB_UP, Gosu::KB_W],
      down: [Gosu::KB_DOWN, Gosu::KB_S],
      left: [Gosu::KB_LEFT, Gosu::KB_A],
      right: [Gosu::KB_RIGHT, Gosu::KB_D]
    }

    @attribs = {
      collectors: 1,
      speed: 0.4,
      range: 100,
      collect_speed: 0.2
    }

    @sprites = {
      player: Gosu::Image.new('gfx/player.png', retro: true),
      collector: Gosu::Image.new('gfx/collector.png', retro: true),
      range: Gosu::Image.new('gfx/range_1.png', retro: true),
      wire: Gosu::Image.new('gfx/wire.png', retro: true)
    }

    @collectors_angles = []
    @attribs[:collectors].times {|angle| @collectors_angles.push angle}

    @wire_path = []
    @wire_path.push [@x, @y] # power connexion
    @wire_path.push [@x, @y] # current position
    @wire_length = 0
  end

  def button_down(id)
  
  end

  def update(dt)
    # diagonal check
    x_axis_movement = (@keys[:left].any? {|key| Gosu.button_down?(key)} || @keys[:right].any? {|key| Gosu.button_down?(key)})
    y_axis_movement = (@keys[:up].any? {|key| Gosu.button_down?(key)} || @keys[:down].any? {|key| Gosu.button_down?(key)})
    diag = (x_axis_movement && y_axis_movement) ? 0.7 : 1 
    
    # player movement
    vel = @attribs[:speed] * dt * diag

    old_x, old_y = @x, @y
    old_angle = @angle

    @x -= vel if @keys[:left].any? {|key| Gosu.button_down?(key)}
    @x += vel if @keys[:right].any? {|key| Gosu.button_down?(key)}
    @y -= vel if @keys[:up].any? {|key| Gosu.button_down?(key)}
    @y += vel if @keys[:down].any? {|key| Gosu.button_down?(key)}

    # straight movement
    @angle = 180 if old_x > @x && old_y == @y
    @angle = 0 if old_x < @x && old_y == @y
    @angle = 270 if old_y > @y && old_x == @x
    @angle = 90 if old_y < @y && old_x == @x
    
    # diagonal
    @angle = 45 if old_y < @y && old_x < @x
    @angle = 135 if old_y < @y && old_x > @x
    @angle = 315 if old_y > @y && old_x < @x
    @angle = 225 if old_y > @y && old_x > @x
    
    # wire : we add a turn or align to the vaccum on the last one
    if old_angle != @angle
      @wire_path.push [@x, @y]
      @wire_length += Gosu.distance(@wire_path.last[0], @wire_path.last[1], @x, @y)
    else
      @wire_length += Gosu.distance(@wire_path.last[0], @wire_path.last[1], @x, @y)
      @wire_path.last[0] = @x
      @wire_path.last[1] = @y
    end

    # boundary
    half_size = @size / 2
    @x = half_size + @tile_size if @x < half_size + @tile_size
    @x = @scene.map.pixel_width - half_size - @tile_size if @x > @scene.map.pixel_width - half_size - @tile_size
    @y = half_size + @tile_size if @y < half_size + @tile_size
    @y = @scene.map.pixel_height - half_size - @tile_size if @y > @scene.map.pixel_width - half_size - @tile_size
  end

  def draw
    # draw range
    radius = @attribs[:range] / @sprites[:range].width.to_f
    @range_color ||= Gosu::Color.new(32, 255, 255, 255)
    @sprites[:range].draw_rot(@x, @y, 0, 0, 0.5, 0.5, radius, radius, @range_color)
    
    # collectors
    @attribs[:collectors].times do |i|
      angle = @collectors_angles[i]
      @sprites[:collector].draw_rot(@x, @y, 1, angle)
    end

    # player
    @sprites[:player].draw_rot(@x, @y, 1, @angle + 90)

    # wire
    last_point_x, last_point_y = nil, nil
    @wire_path.each_with_index do |point, i|
      x, y, angle, distance = *point

      if i == 0
        last_point_x, last_point_y = x, y
        next
      end
      
      angle = Gosu.angle(last_point_x, last_point_y, x, y)
      distance = Gosu.distance(last_point_x, last_point_y, x, y)
      @sprites[:wire].draw_rot(x, y, 0, angle + 90, 0.0, 0.5, distance / @sprites[:wire].width, 1)

      last_point_x, last_point_y = x, y
    end
  end
end