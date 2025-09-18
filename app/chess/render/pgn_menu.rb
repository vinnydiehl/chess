class ChessGame
  def render_pgn_menu
    render_background

    @primitives << [
      @multiline,
      @pgn_buttons,
    ]
  end
end
