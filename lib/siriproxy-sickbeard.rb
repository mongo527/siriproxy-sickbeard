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
        response = ask "What Show would you like to add?"
        
        showIDName = tvdbSearch(response)
        
        if not showIDName["name"]
            request_completed
        else
            showDef = changeDef()
            addShow(showIDName["name"], showIDName["tvdbid"], showDef)
        end
        
        request_completed
    end

    listen_for /add (.+) to my shows/i do |response|
        
        showIDName = tvdbSearch(response)
        
        if not showIDName["name"]
            request_completed
        else
            showDef = changeDef()
            addShow(showIDName["name"], showIDName["tvdbid"], showDef)
        end
        
        request_completed
    end

    listen_for /((what is|whats) on (today|tonight)|(anything|any shows) on (today|tonight))/i do
        num = 0
        begin
            shows = sickbeardParser("future&sort=date&type=today")["data"]["today"]
            if shows == []
                say "You have no shows on today."
            else
                for i in shows
                    say "#{shows[num]['show_name']} is on tonight, #{shows[num]['airs']}."
                    num += 1
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
        num = 0
        begin
            shows = sickbeardParser("future&sort=date&type=soon")["data"]["soon"]
            if shows == []
                say "You have no shows on this week."
            else
                for i in shows
                    say "#{shows[num]['show_name']} is on #{shows[num]['airs']}."
                    num += 1
                    break if num > 2
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

    def sickbeardParser(cmd)
        
        base_url = "http://#{@host}:#{@port}/api/#{@api_key}/?cmd="
        url = "#{base_url}#{cmd}"
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