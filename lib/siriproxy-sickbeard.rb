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
    
    #    @api_url = "http://#{@host}:#{@port}/api/#{@api_key}/?cmd="

    listen_for /search the (back\slog|backlog)/i do
        success=""
        open("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=sb.forcesearch") do |f|
            no = 1
            f.each do |line|
                if /result.*success/.match("#{line}")
                    success = true
                    break
                else
                    success = false
                end
                no += 1
                break if no > 5
            end
            if success
                say "Sickbeard is refreshing the Backlog."
            else
                say "There was a problem refreshing the Backlog."
            end
        end
        request_completed
    end

    listen_for /add new show/i do
        response = ask "What Show would you like to add?"
        
        showID = tvdbSearch(response)
        
        if showID == nil
            say "Sorry, #{response} can't be found."
        else
            addShow(showID)
        end
            
        request_completed
    end

#    def getNum(number)
#        ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"].index(number.downcase)
        
#    end

    def addShow(showID)
        success = ""
        open ("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=show.addnew&tvdbid=#{showID}") do |f|
            no = 1
            f.each do |line|
                if /result.*success/.match("#{line}")
                    success = true
                    break
                else
                    success = false
                end
            end
            if success
                say "#{response} has been added to SickBeard."
            else
                say "There was a problem adding #{response} to SickBeard."
            end
        end
    end

    def tvdbSearch(response)
        showID = ""
        showName = ""
        oneWord = ""
        success = ""
        if /\S*\s\S.*/.match("#{response}")
            oneWord = ask "Should #{response} be one word?"
        end
        if oneWord == "Yes "
            showName = response.gsub(/\s/, "")
        else
            showName = response.gsub(/\s/, "%20")
        end
        open ("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=sb.searchtvdb&name=#{showName}") do |f|
            no = 1
            f.each do |line|
                if /tvdbid/.match("#{line}")
                    success = true
                    showID = (/[0-9].*/.match("#{line}")).to_s()
                    break
                else
                    success = false
                end
            end
            return showID
        end
    end
end