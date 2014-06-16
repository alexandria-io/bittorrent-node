require 'sinatra'
require 'sinatra/json'
require "sinatra/config_file"
require 'json'

class Torrent < Sinatra::Base

  register Sinatra::ConfigFile
  config_file './config.yml'

  before do
    if env['HTTP_TORRENT_AUTH_TOKEN'].nil?
      halt 500, json(status: 'failure', message: 'missing HTTP_TORRENT_AUTH_TOKEN header')
    elsif env['HTTP_TORRENT_AUTH_TOKEN'] != settings.torrent_auth_token
      halt 500, json(status: 'failure', message: 'invalid HTTP_TORRENT_AUTH_TOKEN header')
    end
  end

  post '/create_torrent.json' do
    request.body.rewind
    data = request.body.read
    puts data
    parsed_data = JSON.parse data 

    Dir.mkdir "/var/lib/transmission-daemon/downloads/#{parsed_data['volume_title']}"

    parsed_data['pages'].each do |page|
      File.open("/var/lib/transmission-daemon/downloads/#{parsed_data['volume_title']}/#{page['page_title']}_#{page['page_text'].count}twts.json", "w") do |f|
        f.write page.to_json
      end
    end

    `transmission-create --comment "#{parsed_data['archive_title']} | #{parsed_data['volume_title']}" --tracker "udp://tracker.openbittorrent.com:80/announce" --outfile /var/lib/transmission-daemon/downloads/#{parsed_data['volume_title']}.torrent /var/lib/transmission-daemon/downloads/#{parsed_data['volume_title']}` 
    
    `transmission-remote ip_address:9091 --auth=transmission_user:transmission_pass --add /var/lib/transmission-daemon/downloads/#{parsed_data['volume_title']}.torrent`

    json status: :success
  end
end
