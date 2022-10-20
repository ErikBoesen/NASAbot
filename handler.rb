require "json"
require "mebots"
require "json"
require "net/http"

PREFIX = "nasa"
BOT = Bot.new("nasabot", ENV["BOT_TOKEN"])
POST_URI = URI("https://api.groupme.com/v3/bots/post")
POST_HTTP = Net::HTTP.new(POST_URI.host, POST_URI.port)
POST_HTTP.use_ssl = true
POST_HTTP.verify_mode = OpenSSL::SSL::VERIFY_PEER

def receive(event:, context:)
  message = JSON.parse(request.body.read)
  responses = process(message)
  if responses
    reply(responses, message["group_id"])
  end
  return {
    statusCode: 200,
    body: {
      message: "Message received",
      input: event
    }.to_json
  }
end

def get_image()
  uri = URI("https://api.nasa.gov/planetary/apod?api_key=" + (ENV["APOD_KEY"] || "DEMO_KEY"))
  response = Net::HTTP.get(uri)
  return JSON.parse(response)
end

def process(message)
  text = message["text"].downcase
  responses = []
  if message["sender_type"] == "user"
    if text.start_with?(PREFIX)
      image = get_image()
      responses.push("NASA Image of the Day " + image["date"] + "\n\n" + image["explanation"])
      responses.push(image["url"] || image["hdurl"])
    end
  end
  return responses
end

def reply(message, group_id)
  if message.kind_of?(Array)
    message.each { |item|
      reply(item, group_id)
    }
  else
    req = Net::HTTP::Post.new(POST_URI, "Content-Type" => "application/json")
    req.body = {
        bot_id: BOT.instance(group_id).id,
        text: message,
    }.to_json
    POST_HTTP.request(req)
  end
end
