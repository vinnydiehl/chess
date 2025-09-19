class ChessGame
  def resolve_move_input
    if mouse_on_board? && @mouse.key_down.left
      return if @result

      return unless on_last_position?

      # Clicking on the pawn promotion picker
      if @promotion && (picker_pos = mouse_picker_pos)
        promotion_type = PROMOTION_PIECES[picker_pos]

        @board[@promotion.x][@promotion.y] =
          Piece.new(OTHER_COLOR[@color_to_move], promotion_type)

        @promotion = nil

        append_notation(PIECE_NOTATION[promotion_type])
        notate_check_or_mate(@color_to_move)

        # Need to update the last board position to include this promotion
        @positions[-1][:fen] = get_fen

        if (cm = checkmate?(@color_to_move)) || stalemate?(@color_to_move)
          @result = cm ? (@color_to_move == :black ? "1-0" : "0-1") : "½-½"

          # Play sound and update sound for last board position
          @positions[-1][:sound] = :game_end
          play_sound(:game_end)
        else
          @positions[-1][:sound] = :promotion
          play_sound(:promotion)
        end
      end

      x, y = mouse_board_pos

      # Move a selected piece if one of the legal squares is clicked on
      if @piece_selected &&
         legal_moves(@piece_selected, @x_orig, @y_orig).include?([x, y])
        move_piece(@piece_selected, x, y)
        return
      end

      # Otherwise, see if we're picking up a piece

      previous_selection = [@x_orig, @y_orig]
      @x_orig, @y_orig = x, y
      piece = @board[@x_orig][@y_orig]

      if !piece
        @x_orig, @y_orig = previous_selection
        return
      end

      # If switching selections, this needs to be reset
      if [@x_orig, @y_orig] != previous_selection
        @piece_already_selected = false
      end

      # Don't even let the piece be picked up if it's not
      # that color's turn
      if piece.color != @color_to_move
        @x_orig, @y_orig = previous_selection
        play_sound(:illegal)
        return
      end

      @piece_held = piece
      @piece_selected = piece
      @piece_original_pos = [@x_orig, @y_orig]
      @board[@x_orig][@y_orig] = nil
    end

    if @piece_held && @mouse.key_up.left
      if mouse_on_board?
        x, y = mouse_board_pos

        # Reject move if releasing in the sqaure of origin,
        # or the move is illegal
        if (released_in_origin = [@x_orig, @y_orig] == [x, y]) ||
           (illegal = !legal_moves(@piece_held, @x_orig, @y_orig)&.include?([x, y]))
          @board[@x_orig][@y_orig] = @piece_held
          @piece_held = nil

          if released_in_origin && @piece_selected
            @piece_already_selected = !@piece_already_selected
            unless @piece_already_selected
              @piece_selected = nil
              @piece_original_pos = nil
            end
          end

          if illegal
            @piece_already_selected = true
            play_sound(:illegal)
          end

          return
        end

        move_piece(@piece_held, x, y)
      else
        # Tried to drag a piece off the board, put it back
        @board[@piece_original_pos.x][@piece_original_pos.y] = @piece_held
        @piece_held = nil
        @piece_already_selected = true

        play_sound(:illegal)
      end
    end
  end

  def move_piece(piece, x, y)
    # There are multiple sounds that may be played. If this doesn't
    # get set, the normal sound will be played later
    sound = nil

    # If we've captured a piece, save it
    # En passant will be dealt with later
    capture = @board[x][y]

    # Resolve move
    @board[x][y] = piece
    if @piece_held
      @piece_held = nil
    elsif @piece_selected
      @piece_selected = nil
      @board[@x_orig][@y_orig] = nil
    end
    piece = @board[x][y]
    @piece_selected = nil

    # Castling
    if piece.type == :king
      if (@x_orig - x).abs == 2
        if x - @x_orig == 2
          # Castled kingside
          @board[7][y] = nil
          @board[x - 1][y] = Piece.new(piece.color, :rook)
        else
          # Castled queenside
          @board[0][y] = nil
          @board[x + 1][y] = Piece.new(piece.color, :rook)
        end

        sound = :castle
      end

      # Moving the king means no more castling for that color
      instance_variable_set("@#{piece.color}_can_castle_kingside", false)
      instance_variable_set("@#{piece.color}_can_castle_queenside", false)
    end
    # If you move a rook, no more castling on that side
    if piece.type == :rook &&
       [[0, 0], [0, 7], [7, 0], [7, 7]].include?([@x_orig, @y_orig])
      color_affected = { 0 => :white, 7 => :black }[@y_orig]
      side_affected = { 0 => :queenside, 7 => :kingside }[@x_orig]
      instance_variable_set("@#{color_affected}_can_castle_#{side_affected}", false)
    end

    if piece.type == :pawn
      # En passant
      ep_y = piece.color == :white ? y - 1 : y + 1

      # Set en passant target
      if (y - @y_orig).abs == 2
        @en_passant_target = [x, ep_y]
      else
        # Capture
        if [x, y] == @en_passant_target
          capture = @board[x][ep_y]
          @board[x][ep_y] = nil
        end

        @en_passant_target = nil
      end

      # Pawn promotion
      if (piece.color == :white && y == 7) ||
         (piece.color == :black && y == 0)
        @promotion = [x, y]
      end
    else
      @en_passant_target = nil
    end

    if capture
      @captures[@color_to_move] << capture
      sound = :capture
    end

    # Switch turns
    @color_to_move = OTHER_COLOR[@color_to_move]

    update_notation(piece, @piece_original_pos, x, y, capture)

    # Increment move counters
    @move_count += 1 if piece.color == :black
    @halfmove_total += 1
    if piece.type != :pawn && !capture
      @halfmove_count += 1
    else
      @halfmove_count = 0
    end

    @last_move_squares = [@piece_original_pos, [x, y]]

    @positions << position_entry
    @current_position += 1

    checkmate = checkmate?(@color_to_move)

    # Draw situations
    if !checkmate
      # Fifty-move rule
      draw = @halfmove_count >= 100

      # Threefold repetition rule
      #
      # Requirements: same board position, same color to move, and same
      #               legal moves for each piece for 3 times is a draw.
      #
      # The first 2 elements of the FEN and the legal moves recorded
      # gives us this information.
      draw ||= @positions.map { |p| [p[:fen].split(" ")[0..1], p[:legal_moves]] }
                         .tally.any? { |_, count| count >= 3 }

      if draw
        @result = "½-½"
        sound = :game_end
      end
    end

    @piece_original_pos = nil

    if (cm = checkmate) || stalemate?(@color_to_move)
      @result = cm ? (@color_to_move == :black ? "1-0" : "0-1") : "½-½"
      sound = :game_end
    elsif in_check?(@color_to_move)
      sound = :move_check
    end

    auto_scroll_notation

    sound ||= :move_self

    # Set sound if we're creating a new position
    @positions[-1][:sound] = sound if on_last_position?

    play_sound(sound)
  end
end
