class Camera
  attr_reader :offset_x, :offset_y
  def initialize(scene, target)
    @scene = scene
    @target = target
  end

  def look
    # we center the view on the center of the screen
    half_window_width = @scene.window.width / 2
    half_window_height = @scene.window.height / 2

    @offset_x = half_window_width - @target.x
    @offset_y = half_window_height - @target.y

    # except when the view reaches the border of the map
    @offset_x = 0 if @target.x < half_window_width
    @offset_y = 0 if @target.y < half_window_height
    @offset_x = @scene.window.width - @scene.map.pixel_width if @scene.map.pixel_width - @target.x < half_window_width
    @offset_y = @scene.window.height - @scene.map.pixel_height if @scene.map.pixel_height - @target.y < half_window_height

    Gosu.translate(@offset_x, @offset_y) do
      yield
    end
  end
end