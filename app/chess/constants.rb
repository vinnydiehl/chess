COLORS = %i[white black]

OTHER_COLOR = {
  white: :black,
  black: :white
}

# From left to right
PROMOTION_PIECES = %i[queen rook bishop knight]
# From bottom to top
BOARD_EDITOR_PIECES = %i[pawn knight bishop rook queen king]

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
BOARD_PADDING = 5

# Captured pieces will overlap by a differing amount of pixels
CAPTURE_OVERLAP = {
  queen: 22,
  rook: 18,
  bishop: 18,
  knight: 18,
  pawn: 12,
}

NOTATION_MOVES_HEIGHT = 15
NOTATION_ROW_HEIGHT = 41
NOTATION_BOX_HEIGHT = NOTATION_MOVES_HEIGHT * NOTATION_ROW_HEIGHT
NOTATION_X_PADDING = 15
NOTATION_Y_PADDING = 3
NOTATION_MARGIN = 15
NOTATION_SIZE = 3
NOTATION_MOVE_NUM_PADDING = 65
NOTATION_MOVE_HIGHLIGHT_PADDING = 15
