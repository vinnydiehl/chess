PIECE_NOTATION = {
  knight: "N",
  bishop: "B",
  rook: "R",
  queen: "Q",
  king: "K",
}

class ChessGame
  def notation_to_square(str)
    [str[0].ord - 97, str[1].to_i - 1]
  end

  def file_notation(x)
    (x + 97).chr
  end

  def rank_notation(y)
    (y + 1).to_s
  end

  def square_to_notation(square)
    "#{file_notation(square[0])}#{rank_notation(square[1])}"
  end

  def add_notation_line(arr)
    @notation << arr
  end

  def add_notation_segment(str)
    if @notation.last&.size == 1
      @notation.last << str
    else
      @notation << [str]
    end
  end

  def append_notation(str)
    @notation[-1][-1] += str
  end

  def piece_matches?(p1, p2)
    p1&.color == p2&.color && p1&.type == p2&.type
  end

  def update_notation(piece, origin, x, y, capture)
    opponent = OTHER_COLOR[piece.color]

    ox, oy = origin

    # Generate notation for the piece which has been moved
    piece_moved = ""
    if piece.type == :pawn
      # Pawn only has origin square notation if it has captured
      piece_moved += file_notation(origin[0]) if capture
    elsif piece.type == :king && (offset = x - ox).abs == 2
      # Castling
      add_notation_segment(offset < 0 ? "0-0-0" : "0-0")
      return
    else
      piece_moved += PIECE_NOTATION[piece.type]

      # Move disambiguation
      if piece.type != :king
        ambiguous_x = false
        ambiguous_y = false

        # Let's create a board in the position before this move
        orig_board = board_deep_copy
        orig_board[x][y] = nil
        orig_board[ox][oy] = piece

        # We need to loop over the board and check if any pieces of the same
        # type and color can move to the same square
        orig_board.each_with_index do |file, obx|
          file.each_with_index do |other_piece, oby|
            # Skip the piece which was moved
            next if [obx, oby] == [ox, oy]

            if piece_matches?(piece, other_piece)
              moves = legal_moves(other_piece, obx, oby, orig_board, piece.color)
              if moves&.include?([x, y])
                ambiguous_x ||= ox == obx
                ambiguous_y ||= oy == oby
                if !ambiguous_x && !ambiguous_y
                  # Favor file disambiguation over rank
                  ambiguous_y = true
                end
              end
            end
          end
        end

        # Because of the way files are looped over before ranks, we might end up
        # with a situation when ranks is disambiguated when it doesn't need to be.
        # We can unset that if that is the case
        if ambiguous_x && ambiguous_y &&
           orig_board.none? { |file| piece_matches?(file[oy], piece) }
          ambiguous_y = false
        end

        piece_moved += file_notation(ox) if ambiguous_y
        piece_moved += rank_notation(oy) if ambiguous_x
      end
    end

    # Generate the entire notation for this particular move
    notation_segment =
      "#{piece_moved}#{capture ? "x" : ""}#{square_to_notation([x, y])}"

    add_notation_segment(notation_segment)
    notate_check_or_mate(opponent)
  end

  def notate_check_or_mate(opponent)
    if checkmate?(opponent)
      append_notation("#")
    elsif in_check?(opponent)
      append_notation("+")
    end
  end

  def notation_str
    lines = @notation.map.with_index { |move, i| "#{i + 1}. #{move.join(' ')}" }
    lines << @result if @result
    lines.join("\n")
  end

  def print_notation
    puts "\n#{notation_str}"
  end
end
