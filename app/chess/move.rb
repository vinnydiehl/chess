class ChessGame
  def resolve_move_input
    if mouse_on_board? && @mouse.key_down.left
      return if @result

      # Clicking on the pawn promotion picker
      if @promotion && (picker_pos = mouse_picker_pos)
        promotion_type = PROMOTION_PIECES[picker_pos]

        @board[@promotion.x][@promotion.y] =
          Piece.new(OTHER_COLOR[@color_to_move], promotion_type)

        @promotion = nil

        append_notation(PIECE_NOTATION[promotion_type])
        notate_check_or_mate(@color_to_move)

        play_sound(:promotion)
      end

      # Otherwise, see if we're picking up a piece

      @x_orig, @y_orig = mouse_board_pos
      piece = @board[@x_orig][@y_orig]

      return unless piece

      # Don't even let the piece be picked up if it's not
      # that color's turn
      if piece.color != @color_to_move
        play_sound(:illegal)
        return
      end

      @piece_held = piece
      @piece_original_pos = [@x_orig, @y_orig]
      @board[@x_orig][@y_orig] = nil
    end

    if @piece_held && @mouse.key_up.left
      if mouse_on_board?
        x, y = mouse_board_pos

        # Reject move if releasing in the sqaure of origin,
        # or the move is illegal
        if [@x_orig, @y_orig] == [x, y] ||
           (illegal = !legal_moves(@piece_held, @x_orig, @y_orig)&.include?([x, y]))
          @board[@x_orig][@y_orig] = @piece_held
          @piece_held = nil
          play_sound(:illegal) if illegal
          return
        end

        # There are multiple sounds that may be played. If this doesn't
        # get set, the normal sound will be played later
        sound = nil

        # Is this a capture?
        capture = @board[x][y]
        if capture
          @captures[@color_to_move] << capture
          sound = :capture
        end

        # Resolve move
        @board[x][y] = @piece_held
        @piece_held = nil
        piece_moved = @board[x][y]

        # Castling
        if piece_moved.type == :king
          if (@x_orig - x).abs == 2
            if x - @x_orig == 2
              # Castled kingside
              @board[7][y] = nil
              @board[x - 1][y] = Piece.new(piece_moved.color, :rook)
            else
              # Castled queenside
              @board[0][y] = nil
              @board[x + 1][y] = Piece.new(piece_moved.color, :rook)
            end

            sound = :castle
          end

          # Moving the king means no more castling for that color
          instance_variable_set("@#{piece_moved.color}_can_castle_kingside", false)
          instance_variable_set("@#{piece_moved.color}_can_castle_queenside", false)
        end
        # If you move a rook, no more castling on that side
        if piece_moved.type == :rook &&
           [[0, 0], [0, 7], [7, 0], [7, 7]].include?([@x_orig, @y_orig])
          color_affected = { 0 => :white, 7 => :black }[@y_orig]
          side_affected = { 0 => :queenside, 7 => :kingside }[@x_orig]
          instance_variable_set("@#{color_affected}_can_castle_#{side_affected}", false)
        end

        if piece_moved.type == :pawn
          # En passant
          ep_y = piece_moved.color == :white ? y - 1 : y + 1

          # Set en passant target
          if (y - @y_orig).abs == 2
            @en_passant_target = [x, ep_y]
          else
            # Capture
            if [x, y] == @en_passant_target
              @board[x][ep_y] = nil
            end

            @en_passant_target = nil
          end

          # Pawn promotion
          if (piece_moved.color == :white && y == 7) ||
             (piece_moved.color == :black && y == 0)
            @promotion = [x, y]
          end
        else
          @en_passant_target = nil
        end

        # Switch turns
        @color_to_move = OTHER_COLOR[@color_to_move]

        update_notation(piece_moved, @piece_original_pos, x, y, capture)

        # Increment move counters
        @move_count += 1 if piece_moved.color == :black
        if piece_moved.type != :pawn && !capture
          @halfmove_count += 1
        else
          @halfmove_count = 0
        end

        checkmate = checkmate?(@color_to_move)

        # Draw situations
        if !checkmate
          draw = false

          # Fifty-move rule
          draw = @halfmove_count >= 100

          # Threefold repetition rule
          @positions_seen << position_record
          draw ||= @positions_seen.tally.any? { |_, count| count >= 3 }

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

        play_sound(sound || :move_self)
      else
        # Tried to drag a piece off the board, put it back
        @board[@piece_original_pos.x][@piece_original_pos.y] = @piece_held
        @piece_held = nil
        @piece_original_pos = nil

        play_sound(:illegal)
      end
    end
  end

  # Entry into @positions_seen, for threefold repetition rule
  # Must have same board position, color to move, and legal moves to count
  # for repetition, so this will account for en passant and castling
  def position_record
    [
      get_position,
      @color_to_move,
      @board.each_with_index.map do |file, trx|
        file.each_with_index.map { |p, try| p ? legal_moves(p, trx, try) : nil }
      end,
    ]
  end
end
