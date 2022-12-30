require 'bundler/setup'
require 'line/bot'
require 'sinatra'
require 'dotenv'
Dotenv.load 


class App < Sinatra::Base
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  post '/callback' do
    body = request.body.read
  
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      halt 400, {'Content-Type' => 'text/plain'}, 'Bad Request'
    end
  
    events = client.parse_events_from(body)
  
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
          when Line::Bot::Event::MessageType::Image
            message_id = event.message['id']
            response = client.get_message_content(message_id)
            tf = Tempfile.open("content")
            tf.write(response.body)
            p message_id
            p response
            client.reply_message(event['replyToken'], message_id)
          end
        end
      end
    "OK"
  end
end