class ChessGame
  def render_background
    @primitives << {
      primitive_marker: :solid,
      x: 0, y: 0,
      w: @screen_width, h: @screen_height,
      r: 63, g: 63, b: 63,
    }
  end
end
