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
    
    listen_for /test (sick beard|my show|my shows) server/i do
        begin
            open ("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=sb.ping") do |f|
                f.each do |line|
                    if /result.*success/.match("#{line}")
                        say "SickBeard is up and running!"
                    elsif /message.*WRONG\sAPI.*/.match("#{line}")
                        say "API Key given is incorrect. Please fix this in the config file."
                    end
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        rescue Errno::ECONNREFUSED
            say "Sorry, SickBeard is not running."
        end
        request_completed
    end

    listen_for /search the (back\slog|backlog)/i do
        success=""
        begin
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
                    say "SickBeard is refreshing the Backlog."
                else
                    say "There was a problem refreshing the Backlog."
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        end
        request_completed
    end

    listen_for /add new show/i do
        response = ask "What Show would you like to add?"
        
        showName = oneWord(response)        
        showIDName = tvdbSearch(showName)
        showDef = changeDef()
        
        if not showIDName[0]
            say "Sorry, #{showName} can't be found."
        else
            addShow(showIDName[0], showIDName[1], showDef)
        end
            
        request_completed
    end

    listen_for /add (.+) to my shows/i do |response|
        showID = ""
        
        showName = oneWord("#{response}")
        showIDName = tvdbSearch(showName)
        showDef = changeDef()
        
        if not showID
            say "Sorry, #{showName} can't be found."
        else
            addShow(showIDName[0], showIDName[1], showDef)
        end
        
        request_completed
    end

    def changeDef()
        defQuestion = ask "Would you like to change the quality from the default?"
        
        if /(Yes|Yeah|Yup)(.*)/.match(defQuestion)
            definition = ask "HDTV, SDTV, SDDVD, HDWebDL, HDBluray, FullHDBluray, or Unknown?", spoken: ""
            
            if /(\S*\s*\S*)/.match(definition)
                definition = definition.gsub(/(\S*\s*\S*), "")
            end
            
            return definition
        
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

    def oneWord(response)
        single = ""
        if /\S*\s\S.*/.match("#{response}")
            single = ask "Should #{response} be one word?"
        end
        if /(Yes|Yeah|Yup)(.*)/.match(single)
            showName = response.gsub(/\s/, "")
        else
            showName = response.gsub(/\s/, "%20")
        end
        
        return showName
    end            

    def addShow(showID, showName, definition)
        success = ""
        begin
            open ("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=show.addnew&tvdbid=#{showID}&initial=#{definition}") do |f|
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
                    say "#{showName} has been added to SickBeard."
                else
                    say "There was a problem adding #{showName} to SickBeard."
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        end
    end

    def tvdbSearch(showName)
        showNameList = Array.new
        showIDList = Array.new
        success = ""
        count = 0
        
        begin
            open ("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=sb.searchtvdb&name=#{showName}") do |f|
                f.each do |line|
                    if /name/.match("#{line}")
                        nameLineArray = "#{line}".split(/":\s"/)
                        nameLine = nameLineArray[1].gsub(/",/, "").strip
                        showNameList.push(nameLine)
                        count += 1
                    end
                    if /tvdbid/.match("#{line}")
                        showID = (/[0-9].*/.match("#{line}")).to_s()
                        showIDList.push(showID)
                        success = true
                    else
                        success = false
                    end
                    break if count > 3
                end
                if count == 1
                    return showIDList[0], showNameList[0]
                    
                elsif count > 1
                    showNameList.each do |numShow|
                        say "#{showNameList.index(numShow)}: #{numShow}", spoken: ""
                    end
                    numWordResponse = ask "Please state the number of the show you would like to add."
                    numResponse = getNum(numWordResponse.downcase)
                    numResponse += 1
                    return showIDList[numResponse-1], showNameList[numResponse-1]
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        end
        return
    end
end