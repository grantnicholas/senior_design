require "sinatra/base"

class MyApp < Sinatra::Base
  get '/' do
    "Hello from MyApp!"
  end

  # $0 is the executed file
  # __FILE__ is the current file
  run! if __FILE__ == $0
end