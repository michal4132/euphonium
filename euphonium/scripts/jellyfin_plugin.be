class JellyfinPlugin : Plugin
    def init()
        self.configSchema = {
            'jellyfin_url': {
                'tooltip': 'Jellyfin instance url',
                'type': 'string',
                'defaultValue': 'https://jellyfin.cf'
            },
            'jellyfin_username': {
                'tooltip': 'Username',
                'type': 'string',
                'defaultValue': 'test'
            },
            'jellyfin_password': {
                'tooltip': 'Password',
                'type': 'string',
                'defaultValue': 'dupa12'
            },
        }

        self.applyDefaultValues()
        self.name = "jellyfin"
        self.themeColor = "#4B0082"
        self.displayName = "Jellyfin"
        self.type = "plugin"
        self.exposeWebApp = true
    end
    def onEvent(event, data)
        if event == EVENT_SET_PAUSE
            jellyfin_set_pause(data)
        end
        
        if event == EVENT_CONFIG_UPDATED
            jellyfin_config_updated()
        end
    end
end

app.registerPlugin(JellyfinPlugin())

# HTTP Handlers
http.handle('POST', '/jellyfin/playByTrackID', def(request)
    var body = json.load(request['body'])
    jellyfin_playSongByID(body['TrackID'])
    http.sendJSON({ 'status': 'playing'}, request['connection'], 200)
end)
