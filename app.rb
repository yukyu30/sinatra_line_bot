require 'sinatra'
class App < Sinatra::Base
    get '/' do
        "Hello Wrold!"
    end
end