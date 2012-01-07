require 'cora'
require 'siri_objects'
require 'open-uri'

#############
# This is a plugin for SiriProxy that will allow you to control SickBeard.
# Example usage: "search sick beard backlog."
#############

class SiriProxy::Plugin::SickBeard < SiriProxy::Plugin

    def initialize(config)
        @host = config["sickbeard_host"]
        @port = config["sickbeard_port"]
        @api_key = config["sickbeard_api"]
    end
    
    @api_url = "http://#{@host}:#{@port}/api/#{@api_key}/?cmd="

    listen_for /search the back log/i do
        say "working before uri open"
        open("#{@api_url}sb.forcesearch") do |f|
        say "working after uri"
            no = 1
            f.each do |line|
                if /result.*success/.match("#{line}")
                    say "SickBeard is refreshing the Backlog."
                    break
                else
                    say "There was a problem refreshing the Backlog."
                end
                no += 1
                break if no > 5
            end
        end
        request_completed
    end

    listen_for /add new show/i do
        showName = ask "What Show would you like to add?"
        showID = ""
        showName = showName.gsub(/\s/, "")
        open ("#{@api_url}sb.searchtvdb&name=#{showName}") do |f|
            no =1
            f.each do |line|
                if /tvdbid/.match("#{line}")
                    showID = (/[0-9].*/.match("#{line}")).to_s()
                    say "#{showName} will be added to SickBeard."
                    break
                else
                    say "Sorry, #{showName} can't be found."
                end
            end
        end
        open ("#{@api_url}show.addnew&tvdbid=#{showID}") do |f|
            no = 1
            f.each do |line|
                if /result.*success/.match("#{line}")
                    say "#{showName} has been added to SickBeard."
                else
                    say "There was a problem adding #{showName} to SickBeard."
                end
            end
        end
        request_completed
    end
end