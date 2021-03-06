require 'cora'
require 'siri_objects'
require 'open-uri'
require 'json'
require 'net/http'

#############
# This is a plugin for SiriProxy that will allow you to control SickBeard.
# Example usage: "search my shows backlog."
#############

class SiriProxy::Plugin::SickBeard < SiriProxy::Plugin

    def initialize(config)
        @host = config["sickbeard_host"]
        @port = config["sickbeard_port"]
        @api_key = config["sickbeard_api"]
        @plex_ip = config["plex_ip_port"]
        @plex_key = config["plex_key"]
    end
    
    listen_for /test (sick beard|my show|my shows) server/i do
        begin
            server = sickbeardParser("sb.ping")
            if server["result"] == "success"
                say "SickBeard is up and running!"
            elsif server["result"] == "denied"
                say "API Key given is incorrect. Please fix this in the config file."
            else
                say "There was a problem connecting to SickBeard."
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is not running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    listen_for /search (the|my shows|my show|sick beard) (back\slog|backlog)/i do
        begin
            server = sickbeardParser("sb.forcesearch")
            if server["result"] == "success"
                say "SickBeard is refreshing the Backlog!"
            else
                say "There was a problem refreshing the Backlog."
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    listen_for /add new show/i do
        begin
            response = ask "What Show would you like to add?"
            
            showIDName = tvdbSearch(response)
            
            if not showIDName["name"]
                request_completed
            else
                showDef = changeDef()
                addShow(showIDName["name"], showIDName["tvdbid"], showDef)
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    listen_for /add (.+) to my shows/i do |response|
        begin
            showIDName = tvdbSearch(response)
            
            if not showIDName["name"]
                request_completed
            else
                showDef = changeDef()
                addShow(showIDName["name"], showIDName["tvdbid"], showDef)
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    listen_for /(what is|whats|anything|any shows) on (today|tonight)/i do
        begin
            shows = sickbeardParser("future&sort=date&type=today")["data"]["today"]
            if shows == []
                say "You have no shows on today."
            else
                for i in shows
                    say "#{i['show_name']} is on tonight, #{i['airs']}."
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    listen_for /(what is|whats|whats) on this week/i do
        begin
            shows = sickbeardParser("future&sort=date&type=soon")["data"]["soon"]
            if shows == []
                say "You have no shows on this week."
            else
                for i in shows
                    break if shows.index(i) > 2
                    say "#{i['show_name']} is on #{i['airs']}."
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    listen_for /update (.*) from my shows/i do |response|
        begin
            show = searchShows(response)
            if not show[1]
                say "Sorry, I could not find #{response} in your shows."
            else
                updateShow(show[0], show[1])
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end
    
    listen_for /what shows did (i recently|i) (get|get recently)/i do
        begin
            shows = sickbeardParser("history&limit=3&type=downloaded")["data"]
            if shows == []
                say "Sorry, no shows were downloaded"
            else
                for i in shows
                    say "#{i['show_name']} season #{i['season']} episode #{i['episode']}"
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end
    
    listen_for /refresh my (media center|plex|show) library/i do
        begin
            Net::HTTP.get_response(URI.parse("http://#{@plex_ip}/library/sections/#{@plex_key}/refresh"))
            say "Plex is being updated."
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to Plex Media Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, Plex Media Servier is nut running."
        rescue Errno::ENETUNREACH
            say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            say "Sorry, The operation timed out."
        end
        request_completed
    end

    def sickbeardParser(cmd)
        
        url = "http://#{@host}:#{@port}/api/#{@api_key}/?cmd=#{cmd}"
        resp = Net::HTTP.get_response(URI.parse(url))
        data = resp.body
        
        result = JSON.parse(data)
        
        return result
    end

    def changeDef()
        defQuestion = ask "Would you like to change the quality from the default?"
        
        if /(Yes|Yeah|Yup)(.*)/.match(defQuestion)
            definition = ask "HDTV, SDTV, SDDVD, HDWebDL, HDBluray, FullHDBluray, or Unknown?", spoken: ""
        
        definition = definition.gsub(/\s/, "")
            
        return definition.downcase
        
        else
            return
        end
    end

    def getNum(strNum)
        if strNum.match("zero ")
            return 0
        end
        if strNum.match("one ")
            return 1
        end
        if strNum.match("two ")
            return 2
        end
        if strNum.match("three ")
            return 3
        end
        if strNum.match("four ")
            return 4
        end
        if strNum.match("five ")
            return 5
        end
    end           

    def addShow(showName, showID, definition)
        success = ""
        begin
            server = sickbeardParser("show.addnew&tvdbid=#{showID}&initial=#{definition}")
            if server["result"] == "success"
                return say "#{showName} was successfully added to SickBeard!"
            elsif server["result"] == "failure"
                message = server["message"]
                if /tvdbid/.match(message)
                    message = message.gsub(/tvdbid/, "TVDBID")
                end
                
                return say message
            else
                return say "There was a problem adding #{showName} to SickBeard."
            end
        rescue Errno::EHOSTUNREACH
            return say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            return say "Sorry, SickBeard is not running."
        rescue Errno::ENETUNREACH
            return say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            return say "Sorry, The operation timed out."
        end
    end

    def list_of_shows(shows)
        showList = Array.new
        showNumber = ""
        num = 0
        
        for count in shows
            showList.push(shows[num])
            num += 1
        end
        
        if showList.length == 1
            return showList[0]
        else
            showList.each do |showsFound|
                showNumber = showList.index(showsFound)+1
                say "#{showNumber}: #{showsFound['name']}", spoken: ""
                break if showNumber > 2
            end
            numWordResponse = ask "Please state the number of the show you would like to add."
            numResponse = getNum(numWordResponse.downcase)
            numResponse = numResponse.to_i()
            realNum = numResponse - 1
            return showList[realNum]
        end
    end

    def searchShows(response)
        begin
            shows = sickbeardParser("shows")["data"]
            for i in shows
                if i[1]["show_name"].downcase == response.downcase
                    return i[0], i[1]["show_name"]
                else
                    showName = response.gsub(/\s/, "")
                    if i[1]["show_name"].downcase == showName.downcase
                        return i[0], i[1]["show_name"]
                    end
                end
            end
        rescue Errno::EHOSTUNREACH
            return say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            return say "Sorry, SickBeard is not running."
        rescue Errno::ENETUNREACH
            return say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            return say "Sorry, The operation timed out."
        end
    end

    def updateShow(tvdbid, showName)
        begin
            server = sickbeardParser("show.update&tvdbid=#{tvdbid}")
            if server["result"] == "success"
                return say "#{showName} is being updated!"
            else
                return say "There was a problem updating #{showName}."
            end
        rescue Errno::EHOSTUNREACH
            return say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            return say "Sorry, SickBeard is not running."
        rescue Errno::ENETUNREACH
            return say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            return say "Sorry, The operation timed out."
        end
    end

    def tvdbSearch(response)
        showList = Array.new
        showNumber = ""
        num = 0
        
        begin
            if not /\s/.match(response)
                shows = sickbeardParser("sb.searchtvdb&name=#{response}")["data"]["results"]
                if shows == []
                    return say "Sorry, #{response} could not be found."
                else
                    return list_of_shows(shows)
                end
            else
                showName = response.gsub(/\s/, "%20")
                shows = sickbeardParser("sb.searchtvdb&name=#{showName}")["data"]["results"]
                if shows == []
                    showName = response.gsub(/\s/, "")
                    shows = sickbeardParser("sb.searchtvdb&name=#{showName}")["data"]["results"]
                    if shows == []
                        return say "Sorry, #{response} could not be found"
                    else
                        return list_of_shows(shows)
                    end
                else
                    for count in shows
                        showList.push(shows[num])
                        num += 1
                    end
                    
                    if showList.length == 1
                        return showList[0]
                    else
                        return list_of_shows(shows)
                    end
                end
            end
        rescue Errno::EHOSTUNREACH
            return say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            return say "Sorry, SickBeard is not running."
        rescue Errno::ENETUNREACH
            return say "Sorry, Could not connect to the network."
        rescue Errno::ETIMEDOUT
            return say "Sorry, The operation timed out."
        end
    end
end
