class ChessGame
  def render_fen_menu
    render_background

    @primitives << [
      @multiline,
      @fen_buttons,
    ]
  end
end
