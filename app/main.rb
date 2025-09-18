SCENES = %w[game fen_menu pgn_menu].freeze

require "lib/input.rb"

%w[constants button castling check chess color_view colors
   fen input mate material move notation pgn piece
   position position_editor vision].each { |f| require "app/chess/#{f}.rb" }

%w[scenes render].each { |dir| SCENES.each { |f| require "app/chess/#{dir}/#{f}.rb" } }

require "app/chess/render/shared.rb"

def tick(args)
  args.state.game ||= ChessGame.new(args)
  args.state.game.tick
end
