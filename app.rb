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

  def reply_image(event, url)
    client.reply_message(
      event['replyToken'],
      [
        {
          type: "image",
          originalContentUrl: url,
          previewImageUrl: url
        },
        {type: "text", text: '写真からTシャツを作ったよ'}
      ]
    )
  end

  def bin2base64 (bin)
    "data:#{content_type};base64,#{Base64.strict_encode64(bin)}"
  end

  def create_tshirts_image(texture, title)
    access_token = ENV['SUZURI_API_KEY']
    url = URI.parse('https://suzuri.jp/api/v1/materials')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme === "https"

    req = Net::HTTP::Post.new(url.path)
    req["Authorization"] = "Bearer #{access_token}"
    req.body = {texture: texture, title: '無題', products: [{itemId: 1, published: false, resizeMode: 'contain'}]}.to_json
    req.content_type = "application/json"

    res = http.request(req)

    json = JSON.parse(res.body)
    json["products"][0]["sampleImageUrl"]
  end

  get '/ping' do
    "pong"
  end

  get '/make' do
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
            image_url= create_tshirts_image(image, "無題")
        
            reply_image(event,image_url)
          end
        end
      end
    "OK"
  end
end