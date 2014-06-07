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
    data = JSON.parse request.body.read
    puts data
    File.open("/var/lib/transmission-daemon/downloads/#{data['archive_title']}.json", "w") do |f|
      f.write data
    end

    `transmission-create --comment "#{data['archive_title']}" --tracker "udp://tracker.openbittorrent.com:80/announce" --outfile /var/lib/transmission-daemon/downloads/ #{data['archive_title']}.torrent /var/lib/transmission-daemon/downloads/#{data['archive_title']}.json` 
    
    `transmission-remote 107.170.215.106:9091 --auth=transmission:tr@nsm1ss10n --add /var/lib/transmission-daemon/downloads/#{data['archive_title']}.torrent`

    json status: :success
  end
end
