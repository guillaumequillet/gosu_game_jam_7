require 'json'

class Garbage
  @@sprite_size = 32
  @@garbage_sprites = Gosu::Image.load_tiles('gfx/garbage_sprites.png', @@sprite_size, @@sprite_size, retro: true)
  @@json_data = JSON.parse(File.read('garbage.json'))

  attr_reader :x, :y, :height, :type, :points
  def initialize(scene, sprite, x, y)
    @scene = scene
    @sprite = sprite
    @x, @y = x, y
    @rotation = 0
    @scale = 1
    @rotation_multiplicator = 5
    @height = Gosu.random(@scene.window.height / 2, @scene.window.height)
    @gravity = 1.2
    
    @type = @@json_data[@sprite.to_s]['type'].to_sym
    @weight_impact = @@json_data[@sprite.to_s]['weight_impact'].to_f
    @points = @@json_data[@sprite.to_s]['points'].to_i

    load_sfx
  end

  def load_sfx
    if !defined?(@@garbage_sounds)
      @@garbage_sounds = {
        glass: Gosu::Sample.new('sfx/glass-shatter-7-95202.mp3'),
        metal: Gosu::Sample.new('sfx/metal-beaten-sfx-230501.mp3'),
        paper: Gosu::Sample.new('sfx/paper-collect-1-186598.mp3'),
        plastic: Gosu::Sample.new('sfx/plastic-crunch-83779.mp3')
      }
    end
  end

  def self.get_random
    Gosu.random(0, @@garbage_sprites.size).floor
  end

  def collides_hero?(hero)
    return false if hero.x > @x + @@sprite_size / 2
    return false if hero.x + hero.size / 2 < @x
    return false if hero.y > @y + @@sprite_size / 2
    return false if hero.y + hero.size / 2 < @y
    return true
  end

  def update(dt, is_attracted)
    if @height > 0
      @height -= dt * @gravity
      if @height <= 0
        @height = 0
        @@garbage_sounds[@type].play(0.01)
      end
    end

    if is_attracted
      x_hero = @scene.hero.x
      y_hero = @scene.hero.y
      collect_speed = @scene.hero.attribs[:collect_speed] * @weight_impact
      @rotation += collect_speed * @rotation_multiplicator * dt
    
      angle_to_player = Gosu.angle(@x, @y, x_hero, y_hero)
      @x += Gosu.offset_x(angle_to_player, collect_speed * dt)
      @y += Gosu.offset_y(angle_to_player, collect_speed * dt)

      # if the garbage is almost on the vaccum, we shrink it
      distance = Gosu.distance(@x, @y, x_hero, y_hero)
      if distance < 100
        @scale = distance / 100.0
      end
    # we don't want some unattracted shrinked object on the floor
    else
      @scale = 1
    end
  end

  def draw
    # shadow drawing
    if @height > 0
      @shadow_color ||= Gosu::Color.new(128, 0, 0, 0)
      @@garbage_sprites[@sprite].draw_rot(@x, @y, 0, @rotation, 0.5, 0.5, 1, 1, @shadow_color)
    end

    @@garbage_sprites[@sprite].draw_rot(@x, @y - @height, 0, @rotation, 0.5, 0.5, @scale, @scale)
  end
end