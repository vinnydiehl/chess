class ChessGame
  def game_init
    @board_size = @screen_height
    @square_size = @board_size / 8
    @capture_size = @square_size / 2
    @legal_marker_size = @square_size / 4
    @color_view = :white

    ### Values for input and rendering
    # Left side of the board
    @x_offset = @screen_width / 6
    # Piece picker for pawn promotion
    @promotion_picker_rect = {
      x: @x_offset + ((@board_size - @square_size * 4) / 2),
      y: (@board_size - @square_size) / 2,
      w: @square_size * 4,
      h: @square_size,
    }
    @captures_x_offset = @x_offset + @board_size + BOARD_PADDING
    # Notation box
    @notation_y_top = @screen_height - @capture_size - 10
    notation_x = @x_offset + @board_size + NOTATION_X_PADDING
    @notation_box = {
      x: notation_x,
      y: @notation_y_top - NOTATION_BOX_HEIGHT,
      w: @screen_width - notation_x - NOTATION_X_PADDING,
      h: NOTATION_MOVES_HEIGHT * NOTATION_ROW_HEIGHT
    }
    @notation_box_position = 0
    # Offset to center the legal move marker in the square
    @legal_center_offset = (@square_size / 2) - (@legal_marker_size / 2)

    @board = Array.new(8) { Array.new(8, nil) }
    @notation = []
    @result = nil

    @captures = { white: [], black: [] }

    @piece_held = nil
    @piece_original_pos = nil

    @piece_selected = nil
    @piece_already_selected = false

    @last_move_squares = nil

    @x_orig, @y_orig = 0, 0

    @promotion = nil

    # This will set the following:
    #   @board
    #   @color_to_move
    #   @white_can_castle_kingside
    #   @white_can_castle_queenside
    #   @black_can_castle_kingside
    #   @black_can_castle_queenside
    #   @en_passant_target
    #   @halfmove_count
    #   @move_count
    set_fen(FEN)

    # Keep track of all previous board positions for threefold repetition
    @positions_seen = [position_record]

    play_sound(:game_start)
  end

  def game_tick
    resolve_move_input
    process_mouse_inputs
    process_keyboard_inputs
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
