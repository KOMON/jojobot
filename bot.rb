require 'slack-rtmapi'
require './handlers.rb'
require './token.rb'
url = SlackRTM.get_url token: $token
client = SlackRTM::Client.new websocket_url: url


def handle(client, msg)
  $handlers.each do |regex, reply|
    match_arr = Regexp.new(regex, Regexp::IGNORECASE).match msg["text"]
   if( match_arr && match_arr[1])
      reply.call(client, match_arr[1], msg["channel"])
    end
  end
end

client.on :open do puts "Connected" end
client.on :message do |msg|
  if(msg["type"] == "message")
    handle(client, msg)
  end
  puts msg
end
    
client.main_loop
assert false
