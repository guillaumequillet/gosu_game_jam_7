class Scene
  attr_reader :window
  def initialize(window)
    @window = window
    @font = Gosu::Font.new(16, {name: Gosu::default_font_name})
    @font2 = Gosu::Font.new(28, {name: Gosu::default_font_name})
  end

  def set_scene(scene)
    @window.set_scene(scene)
  end

  def button_down(id)
  
  end
end

class SceneGame < Scene
  attr_reader :map, :hero
  def initialize(window)
    super(window)
  
    @tile_size = 32
    @map = Map.new(self, 40, 40, @tile_size)
    @hero = Hero.new(self, @map.get_center)
    @camera = Camera.new(self, @hero)

    @state = :game

    @level = 0
    @score = 0
    level_up

    @time_before_spawn = Gosu.random(100, 3000)
    @last_spawn = Gosu.milliseconds
    @garbages = []
    @closest_garbages = nil
    @max_garbages = 100

    @music = Gosu::Song.new('sfx/Xuological Jeremy (NES).mp3')
    @music.play(true)

    @sounds = {
      collect: Gosu::Sample.new('sfx/short-woosh-109592.mp3'),
      validate: Gosu::Sample.new('sfx/ui_correct_button2-103167.mp3'),      
      wire: Gosu::Sample.new('sfx/bonus-143026.mp3'),      
      levelup: Gosu::Sample.new('sfx/level-up-47165.mp3')      
    }

    @gfx = {
      earth: Gosu::Image.new('gfx/earth.png', retro: true),
      earth_covered: Gosu::Image.new('gfx/earth_covered.png', retro: true),
      overlay_hud: Gosu::Image.new('gfx/overlay_hud.png', retro: true)
    }
  end

  def button_down(id)
    case @state
    when :game

    when :leveling
      if @timer_before_press >= 500
        change = true
        if @hero.keys[:up].include?(id)
          @hero.attribs[:collectors] += 1
          @hero.collectors_angles.push 0
        elsif @hero.keys[:down].include?(id)
          @hero.attribs[:range] += 100
        elsif @hero.keys[:left].include?(id)
          @hero.attribs[:collect_speed] += 0.2
        elsif @hero.keys[:right].include?(id)
          @hero.attribs[:speed] += 0.1
        else
          change = false
        end
        if change
          @sounds[:validate].play
          level_up
        end
      end
    when :game_over
      # we restart the game
      @window.set_scene(:game)
    end
  end

  def level_up
    @state = :game
    @level += 1
    @collected_garbage = 0
    @collection_objective = (1 + @level)**2
  end

  def garbage_spawn(dt)
    if Gosu.milliseconds - @last_spawn >= @time_before_spawn
      garbages = @level * (Gosu.random(1, 5)).floor

      # we can't spawn more garbages than allowed, not to insta kill the player
      garbages = @max_garbages if garbages >= @max_garbages

      garbages.times do
        padding = 2 
        x, y = Gosu.random(padding, @map.width - 2 * padding), Gosu.random(padding, @map.height - 2 * padding)
        sprite = Garbage.get_random
        @garbages.push Garbage.new(self, sprite, x * @tile_size, y * @tile_size)
        @time_before_spawn = Gosu.random(100, 5000)
      end
      @last_spawn = Gosu.milliseconds
    end
  end

  def garbage_select_closest
    @closest_garbages = nil

    # we select the closest garbages from the player that landed on the ground
    if !@garbages.empty?
      # we only consider garbage within player range and already on the ground
      @candidates = @garbages.select {|garbage| garbage.height == 0 && Gosu.distance(@hero.x, @hero.y, garbage.x, garbage.y) <= @hero.attribs[:range]}
      
      # and we assign to collect the closests, according to the collectors quantity
      if !@candidates.empty?
        @candidates.sort! {|a, b| Gosu.distance(@hero.x, @hero.y, a.x, a.y) <=> Gosu.distance(@hero.x, @hero.y, b.x, b.y)}
        @closest_garbages = @candidates.take(@hero.attribs[:collectors])

        # we set the orientation for collectors
        @closest_garbages.each_with_index do |garbage, i|
          @hero.collectors_angles[i] = Gosu.angle(@hero.x, @hero.y, garbage.x, garbage.y) - 90.0
        end
      end
    end
  end

  def collect_garbage
    if !@closest_garbages.nil? 
      @closest_garbages.each do |closest_garbage|
        # we play the collect sound, adjust score and stats and remove garbage from the game
        if closest_garbage.collides_hero?(@hero)
          @collected_garbage += 1
          @sounds[:collect].play(1)
          @score += closest_garbage.points
          @garbages.delete_at(@garbages.index(closest_garbage))

          # if we got enough garbage, it's time to level up !
          if @collected_garbage >= @collection_objective
            @collected_garbage = 0
            @timer_before_press = 0
            @timer_before_press_tick = Gosu.milliseconds
            @state = :leveling
            @sounds[:levelup].play
          end
        end
      end
    end
  end

  def update_garbage(dt)
    garbage_spawn(dt)
    garbage_select_closest
    @garbages.each_with_index do |garbage, i| 
      is_attracted = !@closest_garbages.nil? && @closest_garbages.include?(garbage)
      garbage.update(dt, is_attracted)
    end
    collect_garbage
  end

  def update(dt)
    case @state
    when :game
      # garbage percent calculation
      @percent = (@garbages.size.to_f / @max_garbages.to_f) * 100
      @state = :game_over if @percent >= 100
      
      # wire length bonus
      bonus_gap = 10000
      bonus_score = 10000
      last_wire_length = (@hero.wire_length / bonus_gap).floor

      @hero.update(dt)
      if (@hero.wire_length / bonus_gap).floor > last_wire_length
        @score += bonus_score
        @sounds[:wire].play
      end

      update_garbage(dt)
    when :leveling
      @timer_before_press += Gosu.milliseconds - @timer_before_press_tick
      @timer_before_press_tick = Gosu.milliseconds
    when :game_over

    end
  end

  def draw_hud
    # overlay hud
    @gfx[:overlay_hud].draw(0, 0, 0, 1, 1, Gosu::Color.new(128, 255, 255, 255))

    # top left
    @font.draw_text("Level : #{@level}", 10, 10, 1)
    @font.draw_text("Garbage : #{@garbages.size}", 10, 30, 1)
    @font.draw_text("Objective : #{@collected_garbage} / #{@collection_objective}", 10, 50, 1)
    @font.draw_text("Wire Length : #{@hero.wire_length.floor}", 10, 70, 1)
    @font.draw_text("Score : #{@score}", 10, 100, 1)

    # bottom left
    @font.draw_text("Collectors : #{@hero.attribs[:collectors]}", 10, 400, 1)
    @font.draw_text("Collect Speed : #{@hero.attribs[:collect_speed].floor(1)}", 10, 420, 1)
    @font.draw_text("Speed : #{@hero.attribs[:speed].floor(1)}", 10, 440, 1)
    @font.draw_text("Range : #{@hero.attribs[:range].floor(1)}", 10, 460, 1)

    # earth
    padding = 10
    x, y = @window.width - @gfx[:earth].width - padding, @window.height - @gfx[:earth].height - padding
    @gfx[:earth].draw(x, y, 10)

    height = ((@garbages.size * @gfx[:earth_covered].height) / @max_garbages.to_f).floor

    Gosu.clip_to(x, y + @gfx[:earth_covered].height - height, @gfx[:earth_covered].width, height) do
      @gfx[:earth_covered].draw(x, y, 10, 1, 1, Gosu::Color.new(128, 255, 255, 255))
    end

    percent = @percent.floor.to_s + ' %'
    stroke = 2

    x, y = x + @gfx[:earth].width / 2 - @font2.text_width(percent) / 2, y + @gfx[:earth].height / 2 - @font2.height / 2
    @font2.draw_text(percent, x, y, 12, 1, 1, Gosu::Color::RED)  
    @font2.draw_text(percent, x + stroke, y, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x - stroke, y, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x, y - stroke, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x, y + stroke, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x - stroke, y - stroke, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x + stroke, y + stroke, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x + stroke, y - stroke, 11, 1, 1, Gosu::Color::WHITE)  
    @font2.draw_text(percent, x - stroke, y + stroke, 11, 1, 1, Gosu::Color::WHITE)  
  end

  def draw_minimap
    padding = 10
    scale = 2
    empty_color = Gosu::Color.new(200, 128, 128, 128)
    trash_color = Gosu::Color::RED
    hero_color = Gosu::Color::GREEN

    Gosu.translate(@window.width - @map.width * scale - padding, padding) do
      Gosu.draw_rect(0, 0, @map.width * scale, @map.height * scale, empty_color, 10)
      @garbages.each do |garbage|
        x, y = (garbage.x / @tile_size).floor * scale, (garbage.y / @tile_size).floor * scale
        Gosu.draw_rect(x, y, 2, 2, trash_color, 11)
      end
      Gosu.draw_rect((@hero.x / @tile_size).floor * scale, (@hero.y / @tile_size).floor * scale, 2, 2, hero_color, 11)
    end
  end

  def draw_action
    @camera.look do
      @map.draw
      @hero.draw
      @garbages.each {|garbage| garbage.draw}
    end
  end

  def draw
    case @state
    when :game
      draw_action
      draw_hud
      draw_minimap
    when :leveling
      # we keep action drawn
      draw_action

      # we draw some overlay above to darken it
      Gosu.draw_rect(0, 0, @window.width, @window.height, Gosu::Color.new(200, 0, 0, 0))

      # we display options to level up
      @font.draw_text("COLLECTOR+", 225, 15, 2, 2, 2)
      @font.draw_text("RANGE+", 265, 430, 2, 2, 2)
      @font.draw_text("COLLECT+", 25, 215, 2, 2, 2)
      @font.draw_text("SPEED+", 500, 215, 2, 2, 2)

      # and the Level Up display itself
      txt = "Level Up !"
      @font2.draw_text(txt, @window.width / 2 - @font2.text_width(txt) / 2, @window.height / 2 - @font2.height, 2, 1, 1, Gosu::Color::RED)
    when :game_over
      # we keep action drawn
      draw_action
      
      # we draw some opaque overlay
      Gosu.draw_rect(0, 0, @window.width, @window.height, Gosu::Color.new(200, 0, 0, 0))
      @font.draw_text('Game Over', 130, 100, 10, 5, 5)
      @font.draw_text("You reached level #{@level}.", 30, 200, 10, 2, 2)
      @font.draw_text("Score : #{@score} points", 30, 250, 10, 2, 2)
      @font.draw_text("- Press any key to restart -", 155, 400, 10, 2, 2)
    end
  end
end

class SceneTitle < Scene
  def initialize(window)
    super(window)
    @bg = Gosu::Image.new('gfx/scene_title.png', retro: true)
  end
  def button_down(id)
    set_scene(:game)
  end

  def draw
    @bg.draw(0, 0, 0)
  end

  def update(dt)

  end
end