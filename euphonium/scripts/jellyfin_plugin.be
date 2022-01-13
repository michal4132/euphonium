class JellyfinPlugin : Plugin
    def init()
        self.configSchema = {
            'jellyfin_url': {
                'tooltip': 'Jellyfin instance url',
                'type': 'string',
                'defaultValue': ''
            },
            'jellyfin_username': {
                'tooltip': 'Username',
                'type': 'string',
                'defaultValue': ''
            },
            'jellyfin_password': {
                'tooltip': 'Password',
                'type': 'string',
                'defaultValue': ''
            },
        }

        self.applyDefaultValues()
        self.name = "jellyfin"
        self.themeColor = "#d2c464"
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

    app.updateSong({
        'songName': "test",
        'artistName': 'test',
        'sourceName': 'jellyfin',
        'icon': '',
        'albumName': 'test'
    })
    jellyfin_playSongByID(body['songURL'])
    app.setStatus('playing')
    http.sendJSON({ 'status': 'playing'}, request['connection'], 200)
end)
