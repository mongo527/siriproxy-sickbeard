require 'cora'
require 'siri_objects'
require 'open-uri'
#require 'nokogiri'

#############
# This is a plugin for SiriProxy that will allow you to control SickBeard.
# Example usage: "search sickbeard backlog."
#############

class SiriProxy::Plugin::SickBeard < SiriProxy::Plugin

    def initialize(config)
        @host = config["sickbeard_host"]
        @port = config["sickbeard_port"]
        @api_key = config["sickbeard_api"]
        @username = config["sickbeard_username"]
        @password = config["sickbeard_password"]
    end
    
    
end