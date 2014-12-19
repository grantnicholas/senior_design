require './app.rb'

map '/' do 
	run Public
end

map '/' do 
	run Protected
end