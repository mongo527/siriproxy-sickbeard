require 'cora'
require 'siri_objects'
require 'open-uri'
require 'json'
require 'net/http'

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
        end
        request_completed
    end

    listen_for /search the (back\slog|backlog)/i do
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
        end
        request_completed
    end

    listen_for /add new show/i do
        response = ask "What Show would you like to add?"
        
        showIDName = tvdbSearch(response)
        showDef = changeDef()
        
        if not showIDName
            say "Sorry, #{response} can't be found."
        else
            addShow(showIDName["name"], showIDName["tvdbid"], showDef)
        end
        
        request_completed
    end

    listen_for /add (.+) to my shows/i do |response|
        
        showIDName = tvdbSearch(response)
        showDef = changeDef()
        
        if not showIDName
            say "Sorry, #{response} can't be found."
        else
            addShow(showIDName["name"], showIDName["tvdbid"], showDef)
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
            server = sickbeard("show.addnew&tvdbid=#{showID}&initial=#{definition}")
            if server["result"] == "success"
                return say "#{showName} was successfully added to SickBeard!"
            elsif server["result"] == "failure"
                return say server["message"]
            else
                return say "There was a problem adding #{showName} to SickBeard."
            end
        rescue Errno::EHOSTUNREACH
            return say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            return say "Sorry, SickBeard is not running."
        end
    end

    def tvdbSearch(showName)
        showList = Array.new
        num = 0
        
        begin
            if not /\s/.match(response)
                shows = sickbeard("sb.searchtvdb&name=#{response}")["data"]["results"]
                if shows == []
                    return say "Sorry, #{response} could not be found."
                else
                    for count in shows
                        showList.push(shows[num])
                        num += 1
                    end
                    
                    if showList.length == 1
                        return showList[0]
                    else
                        showList.each do |showsFound|
                            showNumber.push(showList.index(showsFound)+1)
                            say "#{showNumber}: #{showsFound}", spoken: ""
                            break if showNumber > 3
                        end
                        numWordResponse = ask "Please state the number of the show you would like to add."
                        numResponse = getNum(numWordResponse.downcase)
                        numResponse = numResponse.to_i()
                        realNum = numResponse - 1
                        return showList[realNum]
                    end
                end
            else
                showName = response.gsub(/\s/, "%20")
                shows = sickbeard("sb.searchtvdb&name=#{showName}")["data"]["results"]
                if shows == []
                    showName = response.gsub(/\s/, "")
                    shows = sickbeard("sb.searchtvdb&name=#{showName}")["data"]["results"]
                    if shows == []
                        return say "Sorry, #{response} could not be found"
                    else
                        for count in shows
                            showList.push(shows[num])
                            num += 1
                        end
                        
                        if showList.length == 1
                            return showList[0]
                        else
                            showList.each do |showsFound|
                                showNumber.push(showList.index(showsFound)+1)
                                say "#{showNumber}: #{showsFound}", spoken: ""
                                break if showNumber > 3
                            end
                            numWordResponse = ask "Please state the number of the show you would like to add."
                            numResponse = getNum(numWordResponse.downcase)
                            numResponse = numResponse.to_i()
                            realNum = numResponse - 1
                            return showList[realNum]
                        end
                    end
                else
                    for count in shows
                        showList.push(shows[num])
                        num += 1
                    end
                    
                    if showList.length == 1
                        return showList[0]
                    else
                        showList.each do |showsFound|
                            showNumber.push(showList.index(showsFound)+1)
                            say "#{showNumber}: #{showsFound}", spoken: ""
                            break if showNumber > 3
                        end
                        numWordResponse = ask "Please state the number of the show you would like to add."
                        numResponse = getNum(numWordResponse.downcase)
                        numResponse = numResponse.to_i()
                        realNum = numResponse - 1
                        return showList[realNum]
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