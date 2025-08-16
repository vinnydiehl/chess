COLORS = %i[white black]

OTHER_COLOR = {
  white: :black,
  black: :white
}

PROMOTION_PIECES = %i[queen rook bishop knight]

# Define material values
PIECE_VALUE = {
  queen: 9,
  rook: 5,
  bishop: 3,
  knight: 3,
  pawn: 1,
  king: 0,
}
# We want bishops to be sorted above knights, so
# we can't just use PIECE_VALUE easily. :/
PIECE_SORTING_VALUE = {
  queen: 5,
  rook: 4,
  bishop: 3,
  knight: 2,
  pawn: 1,
  king: 0,
}

## GUI values

# Space between board and surrounding UI elements
BOARD_MARGIN = 5

# Captured pieces will overlap by a differing amount of pixels
CAPTURE_OVERLAP = {
  queen: 22,
  rook: 18,
  bishop: 18,
  knight: 18,
  pawn: 12,
}
