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
        showID = tvdbSearch(showName)
        
        if not showID
            say "Sorry, #{showName} can't be found."
        else
            addShow(showID, showName, response)
        end
            
        request_completed
    end

    listen_for /add (.*) to my shows/i do |response|
        showID = ""
        
        showName = oneWord("#{response}")
        showID = tvdbSearch(showName)
        
        if not showID
            say "Sorry, #{showName} can't be found."
        else
            addShow(showID, "#{showName}", response)
        end
        
        request_completed
    end

#    def getNum(number)
#        ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"].index(number.downcase)
        
#    end

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

    def addShow(showID, response, showSpaces)
        success = ""
        begin
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
                if /%20/.match(response)
                    if success
                        say "#{showSpaces} has been added to SickBeard."
                    else
                        say "There was a problem adding #{showSpaces} to SickBeard."
                    end
                else
                    if success
                        say "#{response} has been added to SickBeard."
                    else
                        say "There was a problem adding #{response} to SickBeard."
                    end
                end
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        end
    end

    def tvdbSearch(showName)
        showNameList = Array.new
        showID = ""
        success = ""
        count = 0
        
        begin
            open ("http://#{@host}:#{@port}/api/#{@api_key}/?cmd=sb.searchtvdb&name=#{showName}") do |f|
                f.each do |line|
                    if /name/.match("#{line}")
                        nameLine = "#{line}".gsub(/""*\\*\,*/, "").strip
                        showNameList.push(nameLine)
                        count += 1
                    end
                    break if count > 3
                end
                if count == 1
                    if /tvdbid/.match(showNameList[count-1])
                        success = true
                        showID = (/[0-9].*/.match(showNameList[count-1])).to_s()
                        break
                    else
                        success = false
                    end
                elsif count > 1
                    count.each do |numShow|
                        say "#{count.index(numShow)}: #{numShow}", spoken: ""
                    end
                    showID = ask "Please state the number of the show you would like to add."
                end
                    
                    
                return showID
            end
        rescue Errno::EHOSTUNREACH
            say "Sorry, I could not connect to your SickBeard Server."
        end
        return
    end
end