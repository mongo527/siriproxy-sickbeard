SiriProxy-SickBeard
==

About
--

Allows you to control [SickBeard](http://sickbeard.com), the ultimate PVR, with Siri!

Installation
--

1. Add the following to ~./siriproxy/config.yml

  - name: 'SickBeard'
      git: 'git://github.com/mongo527/siriproxy-sickbeard.git'
      sickbeard_host: '[Enter SickBeard IP Here]' # IP of SickBeard Server
      sickbeard_port: '8081' # Port SickBeard runs on
      sickbeard_api: '[Enter SickBeard API Here]' # SickBeard API Key, found at Config > General > API

2. Change options that need to be changed in config.yml.

3. Run the bundler
	- $ siriproxy bundle

4. Start SiriProxy using 
	- $ rvmsudo siriproxy server

5. Test SiriProxy-SickBeard
	- "Test SickBeard Server"

6. To update:
	- $ siriproxy update

Voice Commands
--

+ test sick beard server OR test my shows server
+ search the back log
+ add new show
+ add *show* to my shows
+ update *show* from my shows
+ what is on tonight
+ what is on this week
+ what shows did i get
+ refresh plex library OR refresh media center library

+ In my experience Siri has a problem when I say Sick Beard. So I instead say my shows.
+ Siri also has a problem with Plex, so media center or show is also accepted.

Notes
--

This is the first time I used Ruby. I figured it would be a decent way to learn the language. So help me where you can! 

Thanks!

Credits
--

Thanks to [Plamoni](https://github.com/plamoni/SiriProxy) and [Westbaer](https://github.com/westbaer/SiriProxy) for SiriProxy.

Thanks to midgetspy for [SickBeard](http://sickbeard.com).

You are free to use, modify, and redistribute the SiriProxy-SickBeard gem as long as proper credit is given to.