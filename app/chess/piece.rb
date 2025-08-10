CODES = {
  pawn: "p",
  bishop: "b",
  knight: "n",
  rook: "r",
  queen: "q",
  king: "k"
}

class Piece
  attr_reader :color, :type

  def initialize(color, type)
    @color, @type = color, type
  end

  def code
    CODES[@type]
  end

  def sprite_path
    "sprites/pieces/#{@color.to_s[0]}#{code}.png"
  end
end

class ChessGame
  # Returns an array of squares that the piece on [sx, sy] can legally move to,
  # or nil if there are no legal moves.
  def legal_moves(piece, sx, sy)
    moves = []

    case piece.type
    when :pawn
      moves = pawn_legal_moves(piece, sx, sy)
    when :bishop
      moves = bishop_legal_moves(piece, sx, sy)
    when :knight
      moves = knight_legal_moves(piece, sx, sy)
    when :rook
      moves = rook_legal_moves(piece, sx, sy)
    when :queen
      moves = bishop_legal_moves(piece, sx, sy) + rook_legal_moves(piece, sx, sy)
    when :king
      moves = king_legal_moves(piece, sx, sy)
    end

    moves
  end

  def pawn_legal_moves(piece, sx, sy)
    moves = []
    x, y = sx, sy

    if piece.color == :white
      y += 1

      # Check captures
      if x > 0
        x -= 1
        if @board[x][y] && @board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves += [[x, y]]
        end
      end
      x = sx
      if x < 7
        x += 1
        if @board[x][y] && @board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves += [[x, y]]
        end
      end
      x = sx

      # 2 spaces on first move
      if !@board[x][y]
        moves += [[x, y]]

        if sy == 1
          y += 1
          moves += [[x, y]] if !@board[x][y]
        end
      end
    else
      y -= 1

      # Check captures
      if x > 0
        x -= 1
        if @board[x][y] && @board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves += [[x, y]]
        end
      end
      x = sx
      if x < 7
        x += 1
        if @board[x][y] && @board[x][y].color != piece.color ||
           [x, y] == @en_passant_target
          moves += [[x, y]]
        end
      end
      x = sx

      # 2 spaces on first move
      if !@board[x][y]
        moves += [[x, y]]

        if sy == 6
          y -= 1
          moves += [[x, y]] if !@board[x][y]
        end
      end
    end

    moves
  end

  def bishop_legal_moves(piece, sx, sy)
    moves = []
    x, y = sx, sy

    while x > 0 && y > 0
      x -= 1
      y -= 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end
    x = sx
    y = sy

    while x > 0 && y < 7
      x -= 1
      y += 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end
    x = sx
    y = sy

    while x < 7 && y > 0
      x += 1
      y -= 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end
    x = sx
    y = sy

    while x < 7 && y < 7
      x += 1
      y += 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end

    moves
  end

  def rook_legal_moves(piece, sx, sy)
    moves = []
    x, y = sx, sy

    while x > 0
      x -= 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end
    x = sx

    while x < 7
      x += 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end
    x = sx

    while y > 0
      y -= 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end
    y = sy

    while y < 7
      y += 1
      if @board[x][y]
        moves += [[x, y]] if @board[x][y].color != piece.color
        break
      end
      moves += [[x, y]]
    end

    moves
  end

  def king_legal_moves(piece, sx, sy)
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

    moves = offset_legal_moves(offsets, piece, sx, sy)

    if send("#{piece.color}_can_castle_kingside?") &&
       (1..2).all? { |n| sx + n <= 7 && @board[sx + n][sy].nil? }
      moves += [[sx + 2, sy]]
    end

    if send("#{piece.color}_can_castle_queenside?") &&
       (1..3).all? { |n| sx - n >= 0 && @board[sx -n][sy].nil? }
      moves += [[sx - 3, sy]]
    end

    moves
  end

  def knight_legal_moves(piece, sx, sy)
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

    offset_legal_moves(offsets, piece, sx, sy)
  end

  def offset_legal_moves(offsets, piece, sx, sy)
    moves = []

    offsets.each do |ox, oy|
      x, y = sx + ox, sy + oy
      if (0..7).include?(x) && (0..7).include?(y) &&
         (!@board[x][y] || @board[x][y].color != piece.color)
        moves += [[x, y]]
      end
    end

    moves
  end
end
