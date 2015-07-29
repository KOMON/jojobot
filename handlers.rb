# coding: utf-8
require 'net/http'
require 'json'
# coding: utf-8
#handlers is a dict of regex strings to Procs that take a SlackRTM::Client
#and a dict

def responder(response_arr)
  return Proc.new { |client, msg, channel|
    replies = response_arr
    client.send({type: "message",
                 channel: channel,
                 text: replies.sample})
  }
end

def die_eval(str)
  res_arr = []
  match_arr = str.scan(/(\[.*?((\d*)d(\d+)).*?\])/)
  match_arr.each { |exp| 
    result = 0
    exp[2].to_i.times do result += rand(1..exp[3].to_i) end
    math = exp[0].sub exp[1], result.to_s
    begin
      result =  eval(math.gsub /[\[\]]/,'')
    rescue SyntaxError => e
      res_arr.push [exp[0], "Syntax Error", nil]
    end
    res_arr.push [exp[0], math, result]
  }
  return res_arr
end


dice_roller = Proc.new { | client, msg, channel |
  result = die_eval(msg)
  unless !result
    message = ""
    result.each { |res|
      unless !res[2]
        message += res[0] + " => " + res[1] + " => *" + res[2].to_s + "*\n"
      else message += res[0] + " => Syntax Error\n"
      end}
    client.send({type: "message",
                 channel: channel,
                 text: message})
  end
}

gatherer = Proc.new { |client, msg, channel |
  puts msg
  msg.gsub! /[:,.!?']/, ''
  msg.gsub! '-', ' '
  msg.gsub! ' ', '%20'
  puts msg
  uri = URI("http://api.mtgdb.info/search/text?start=0&limit=1".sub 'text', msg)
  puts uri.to_s
  res = Net::HTTP.get(uri)
  begin
    response = JSON.parse(res)
  rescue JSON::ParserError => e
    puts "not JSON! probs a 404"
    response = []
  end
  unless response == []
    client.send({type: "message",
                 channel: channel,
                 text: "http://api.mtgdb.info/content/card_images/id.jpeg".sub('id', response[0]["id"].to_s) + "\n" + "```" + response[0]["description"] + "```"})
  else puts "No response!"
  end
}

gather_exact = Proc.new { |client, msg, channel |
  msg.gsub! /:/, ''
  msg.gsub!'-', ' '
  msg.gsub! ' ', '%20'
  uri = URI("http://api.mtgdb.info/search/?q=name%20eq%20%27text%27&start=0&limit=1".sub 'text', msg)
  puts uri.to_s
  res = Net::HTTP.get(uri)
  begin
    response = JSON.parse(res)
  rescue JSON::ParserError => e
    puts "Not JSON! Probably a 404"
    response = []
  end
  unless response == []
    client.send({type: "message",
                 channel: channel,
                 text: "http://api.mtgdb.info/content/card_images/id.jpeg".sub('id', response[0]["id"].to_s) + "\n" + "```" + response[0]["description"] + "```"})
  else puts "No response!"
  end
}


$handlers = {
  '(^hello,*\s*jojo(bot)?[\.!?]*)' => responder(["Hello to you too"]),
  '(menacing)' => responder(["```ゴ        ゴ              ゴ\n    ゴ      ゴ \n      ゴ            \n    ゴ   ゴ \n     ゴ      ゴ    ゴ         ゴ ゴ```"]),
  '(how troublesome|oh dear|oh bother|good grief|jeeze)' => responder(["やれやれだぜ..."]),
  '(\[.+?\])' => dice_roller,
  '(eh,*\s*jojo(bot)?\?|isn\'t\s+that\s+right,*\s*jojo(bot)?\?)' => responder(["Yeah!", "Sure", "...", "Nah", "Not really"]),
  '\[\[(.*?)\]\]' => gatherer,
  '\{\{(.*?)\}\}' => gather_exact
}

