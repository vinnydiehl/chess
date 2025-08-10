class ChessGame
  def resolve_move_input
    if mouse_on_board?
      if @mouse.key_down.left
        @x_orig, @y_orig = mouse_board_pos

        return if (@board[@x_orig][@y_orig].nil?)
        @piece_held = @board[@x_orig][@y_orig]
        @piece_original_pos = [@x_orig, @y_orig]
        @board[@x_orig][@y_orig] = nil
      end
    end

    if @piece_held && @mouse.key_up.left
      if mouse_on_board?
        x, y = mouse_board_pos

        @board[x][y] = @piece_held
        @piece_held = nil
        @piece_original_pos = nil

        # If releasing in the square of origin, nothing to see here
        return if [@x_orig, @y_orig] == [x, y]

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
        else
          @en_passant_target = nil
        end

        # Pawn promotion
        # For now, this just makes it into a queen.
        # TODO: allow promotion choice.
        if (piece_moved.color == :white && y == 7) ||
           (piece_moved.color == :black && y == 0)
          @board[x][y] = Piece.new(piece_moved.color, :queen)
        end
      else
        @board[@piece_original_pos.x][@piece_original_pos.y] = @piece_held
        @piece_held = nil
        @piece_original_pos = nil
      end
    end
  end
end
