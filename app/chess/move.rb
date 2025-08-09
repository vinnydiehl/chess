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

        # En passant
        piece_moved = @board[x][y]
        if piece_moved.type == :pawn
          ep_y = piece_moved.color == :white ? y - 1 : y + 1

          # Set en passant target
          if (y - @y_orig).abs == 2
            @en_passant_target = [x, ep_y]
          else
            # Capture
            if [x, y] == @en_passant_target
              @board[x][ep_y] = nil
            end

            if [@x_orig, @y_orig] != [x, y]
              @en_passant_target = nil
            end
          end
        elsif [@x_orig, @y_orig] != [x, y]
          @en_passant_target = nil
        end

      else
        @board[@piece_original_pos.x][@piece_original_pos.y] = @piece_held
        @piece_held = nil
        @piece_original_pos = nil
      end
    end
  end
end
