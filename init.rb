require 'gosu'
require_relative 'scene.rb'
require_relative 'camera.rb'
require_relative 'hero.rb'
require_relative 'garbage.rb'
require_relative 'map.rb'

class Window < Gosu::Window
  def initialize
    super(640, 480, false)
    self.caption = 'Gosu Game Jam 7 : Future'
    set_scene(:title)
  end

  def set_scene(scene)
    @scene = case scene
    when :title then SceneTitle.new(self)
    when :game then SceneGame.new(self)
    end
  end

  def needs_cursor?; true; end

  def button_down(id)
    super
    close! if id == Gosu::KB_ESCAPE
    @scene.button_down(id)
  end

  def update
    @dt ||= Gosu::milliseconds
    delta = Gosu.milliseconds - @dt

    @scene.update(delta)
    @dt = Gosu.milliseconds
  end

  def draw
    @scene.draw
  end
end

Window.new.show