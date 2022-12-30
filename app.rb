require 'bundler/setup'
require 'line/bot'
require 'sinatra'
require 'dotenv'
require 'base64'
Dotenv.load 


class App < Sinatra::Base
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def reply_text(event, texts)
    texts = [texts] if texts.is_a?(String)
    client.reply_message(
      event['replyToken'],
      texts.map { |text| {type: 'text', text: text} }
    )
  end

  def bin2base64 (bin)
    "data:#{content_type};base64,#{Base64.encode64(bin)}"
  end
  def create_tshirts(texture, title)
    access_token = ENV['SUZURI_API_KEY']
    url = URI.parse('https://suzuri.jp/api/v1/materials')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme === "https"

    req = Net::HTTP::Post.new(url.path)
    req["Authorization"] = "Bearer #{access_token}"
    req.body = {texture: texture, title: '無題'}.to_json
    req.content_type = "application/json"

    res = http.request(req)

    case res
    when Net::HTTPSuccess
      res.body.to_s
    else
      res.body.to_s
    end
  end
  
  get '/test' do
    body = 'https://s.gravatar.com/avatar/ecb04fa16f05ea11109632c00405fdbb'
    message = create_tshirts(body, "無題")
  
    message.to_s
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

            image = bin2base64(response.body)
            puts image
            message = create_tshirts(image, "無題")
            puts message
            reply_text(event, message.to_s)
          end
        end
      end
    "OK"
  end
end