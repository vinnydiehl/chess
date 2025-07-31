SCENES = %w[game].freeze

%w[chess colors fen input piece].each { |f| require "app/chess/#{f}.rb" }

%w[scenes render].each { |dir| SCENES.each { |f| require "app/chess/#{dir}/#{f}.rb" } }

require "app/chess/render/shared.rb"

def tick(args)
  args.state.game ||= ChessGame.new(args)
  args.state.game.tick
end
