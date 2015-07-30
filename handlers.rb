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
  math = str
  match_arr = str.scan(/((\d*)d(\d+))/)
  match_arr.each { |exp| 
    result = 0
    exp[1].to_i.times do result += rand(1..exp[2].to_i) end
    math = math.sub exp[0], result.to_s
  }
  begin
    result =  eval(math.gsub /[\[\]]/,'')
  rescue SyntaxError => e
    return [str, "Syntax Error", nil]
  end
  return [str, math, result]
end


dice_roller = Proc.new { | client, msg, channel |
  result = die_eval(msg)
  unless !result
    client.send({type: "message",
                 channel: channel,
                 text: result[0] + " => " + result[1] + " => *" + result[2].to_s + "*"})
  end
}

def make_mtgapi_req(str, url, strict = false)
  if(strict)
  then
    str.gsub! /[:\"]/, ''
  else
    str.gsub! /[:,.!?'\"]/, ''
  end
  str.gsub! '-', ' '
  str.gsub! ' ', '%20'
  str.gsub! "'", '%27'
  uri = URI(url.sub '[text]', str)
  return Net::HTTP.get(uri)
end

gatherer = Proc.new { |client, msg, channel |
  res = make_mtgapi_req(msg, "http://api.mtgdb.info/search/[text]?limit=1")
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

  else client.send({type: "message",
                    channel: channel,
                    text: "Card not found!"})
  end
}

gather_exact = Proc.new { |client, msg, channel |
   res = make_mtgapi_req(msg, "http://api.mtgdb.info/search?q=name%20eq%20%27[text]%27&limit=1", true)
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

  else client.send({type: "message",
                    channel: channel,
                    text: "Card not found!"})
  end
}

joseph = Proc.new { |client, msg, channel |
  puts "called"
  responses = ["OH MAI GAADUU!", "OHH GAADU!", "OHHH SHIITU!", "SON OF A BIITCHU!"]
  client.send({type: "message",
               channel: channel,
               text: "http://i.imgur.com/TwHoamA.jpg\n" + responses.sample})
}

$handlers = {
  '(^hello,*\s*jojo(bot)?[\.!?]*)' => responder(["Hello to you too"]),
  '(menacing)' => responder(["```ゴ        ゴ              ゴ\n    ゴ      ゴ \n      ゴ            \n    ゴ   ゴ \n     ゴ      ゴ    ゴ         ゴ ゴ```"]),
  '(how troublesome|oh dear|oh bother|good grief|jeeze)' => responder(["やれやれだぜ..."]),
  '(\[.+?\d*d\d+\])' => dice_roller,
  '(eh,*\s*jojo(bot)?\?|isn\'t\s+that\s+right,*\s*jojo(bot)?\?)' => responder(["Yeah!", "Sure", "...", "Nah", "Not really"]),
  '\[\[(.*?)\]\]' => gatherer,
  '\{\{(.*?)\}\}' => gather_exact,
  '(omg|oh my god|holy shit)' => joseph
}

