require './app.rb'

configure do
    set :protection, except: [:frame_options]
end

map '/' do 
	run Public
end

map '/' do 
	run Protected
end

