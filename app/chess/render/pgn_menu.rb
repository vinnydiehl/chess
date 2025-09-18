class ChessGame
  def render_pgn_menu
    render_background

    if @loading
      @primitives << {
        x: @cx, y: @cy,
        text: "Loading PGN...",
        size_enum: 15,
        alignment_enum: 1,
        vertical_alignment_enum: 1,
        r: 255, g: 255, b: 255,
      }
    else
      @primitives << [
        @multiline,
        @pgn_buttons,
      ]
    end
  end
end
