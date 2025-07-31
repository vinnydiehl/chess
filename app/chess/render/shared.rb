class ChessGame
  def render_background
    @primitives << {
      primitive_marker: :solid,
      x: 0, y: 0,
      w: @screen_width, h: @screen_height,
      r: 0, g: 0, b: 0,
    }
  end
end
