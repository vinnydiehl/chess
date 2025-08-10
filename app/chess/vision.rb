class ChessGame
  # Returns an array of the squares that a piece can see
  def piece_vision(piece, sx, sy, board = @board)
    if piece.type == :queen
      bishop_vision(piece, sx, sy, board) + rook_vision(piece, sx, sy, board)
    else
      send("#{piece.type}_vision", piece, sx, sy, board)
    end
  end

  # Returns an array of the squares that a color can see
  def color_vision(color, board = @board)
    squares = []

    board.each_with_index do |file, x|
      file.each_with_index do |piece, y|
        if piece&.color == color
          squares |= piece_vision(piece, x, y, board)
        end
      end
    end

    squares
  end

  def pawn_vision(piece, sx, sy, board)
    moves = []
    x, y = sx, sy

    if piece.color == :white
      y += 1

      # Check captures
      if x > 0
        x -= 1
        if board[x][y] && board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves << [x, y]
        end
      end
      x = sx
      if x < 7
        x += 1
        if board[x][y] && board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves << [x, y]
        end
      end
      x = sx

      # 2 spaces on first move
      if !board[x][y]
        moves << [x, y]

        if sy == 1
          y += 1
          moves << [x, y] if !board[x][y]
        end
      end
    else
      y -= 1

      # Check captures
      if x > 0
        x -= 1
        if board[x][y] && board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves << [x, y]
        end
      end
      x = sx
      if x < 7
        x += 1
        if board[x][y] && board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves << [x, y]
        end
      end
      x = sx

      # 2 spaces on first move
      if !board[x][y]
        moves << [x, y]

        if sy == 6
          y -= 1
          moves << [x, y] if !board[x][y]
        end
      end
    end

    moves
  end

  def bishop_vision(piece, sx, sy, board)
    moves = []
    x, y = sx, sy

    while x > 0 && y > 0
      x -= 1
      y -= 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end
    x = sx
    y = sy

    while x > 0 && y < 7
      x -= 1
      y += 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end
    x = sx
    y = sy

    while x < 7 && y > 0
      x += 1
      y -= 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end
    x = sx
    y = sy

    while x < 7 && y < 7
      x += 1
      y += 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end

    moves
  end

  def rook_vision(piece, sx, sy, board)
    moves = []
    x, y = sx, sy

    while x > 0
      x -= 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end
    x = sx

    while x < 7
      x += 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end
    x = sx

    while y > 0
      y -= 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end
    y = sy

    while y < 7
      y += 1
      if board[x][y]
        moves << [x, y] if board[x][y].color != piece.color
        break
      end
      moves << [x, y]
    end

    moves
  end

  def king_vision(piece, sx, sy, board)
    offsets = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [1, -1],
      [1, 0],
      [1, 1],
      [0, -1],
      [0, 1],
    ]

    offset_vision(offsets, piece, sx, sy, board)
  end

  def knight_vision(piece, sx, sy, board)
    offsets = [
      [-2, -1],
      [-2, 1],
      [-1, -2],
      [-1, 2],
      [1, -2],
      [1, 2],
      [2, -1],
      [2, 1],
    ]

    offset_vision(offsets, piece, sx, sy, board)
  end

  def offset_vision(offsets, piece, sx, sy, board)
    moves = []

    offsets.each do |ox, oy|
      x, y = sx + ox, sy + oy
      if (0..7).include?(x) && (0..7).include?(y) &&
         (!board[x][y] || board[x][y].color != piece.color)
        moves << [x, y]
      end
    end

    moves
  end
end
