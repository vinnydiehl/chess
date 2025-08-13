class ChessGame
  def game_init
    @board_size = @screen_height
    @square_size = @board_size / 8

    ### Values for input and rendering
    # Left side of the board
    @x_offset = @screen_width / 4
    # Piece picker for pawn promotion
    @promotion_picker_rect = {
      x: @x_offset + ((@board_size - @square_size * 4) / 2),
      y: (@board_size - @square_size) / 2,
      w: @square_size * 4,
      h: @square_size,
    }

    @board = Array.new(8) { Array.new(8, nil) }
    @notation = ""

    @piece_held = nil
    @piece_original_pos = nil

    @x_orig, @y_orig = 0, 0

    @promotion = nil

    set_fen(FEN)

    play_sound(:game_start)
  end

  def game_tick
    resolve_move_input
  end

  def board_deep_copy(board = @board)
    temp = []

    board.each do |file|
      tf = []
      file.each { |piece| tf << piece }
      temp << tf
    end

    temp
  end
end
