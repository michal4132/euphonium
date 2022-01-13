import string

EVENT_CONFIG_UPDATED = 'conf_updated'
EVENT_VOLUME_UPDATED = 'volume_updated'
EVENT_SYSTEM_INIT = 'system_init'
EVENT_SET_PAUSE = 'set_pause'

class Plugin
    var name
    var type
    var displayName
    var configSchema
    var audioOutput
    var exposeWebApp
    var configurationLoaded
    var themeColor

    def applyDefaultValues()
        self.exposeWebApp = false
        self.configurationLoaded = false
        self.audioOutput = false
        self.themeColor = "#fff"

        for key : self.configSchema.keys()
            self.configSchema[key]['value'] = self.configSchema[key]['defaultValue']
        end
    end

    def initAudio()
    end

    def onEvent(event, data)
    end

    def configValue(key)
        return self.configSchema[key]['value']
    end

    def getBareValues()
        var bareValues = {}
        for key : self.configSchema.keys()
            bareValues[key] = self.configSchema[key]['value']
        end

        return bareValues
    end

    def persistConfig()
        var bareValues = self.getBareValues()
        print(bareValues)
        conf_persist(self.name + ".config.json", json.dump(bareValues))
    end

    def loadConfig(schema)
        var schemaObj = json.load(schema)
        if (schemaObj == nil) 
            schemaObj = {}
        end

        for key : schemaObj.keys()
            self.configSchema[key]['value'] = schemaObj[key]
        end
    end
end

class App
    var eventHandlers
    var plugins
    var playbackState
    var pluginsInitialized
    var networkState
    var currentPlayer

    def init()
        self.pluginsInitialized = false
        self.eventHandlers = {
            'handleRouteEvent': def (request)
                http.handleRequest(request)
            end,
            'songChangedEvent': def (song)
                self.updateSong(song)
            end,
            'audioTakeoverEvent': def (req)
                self.currentPlayer = req['source']
                self.sendNotification("success", self.currentPlayer, "Took over playback")
            end,
            'playbackError': def (req)
                self.currentPlayer = req['source']
                self.sendNotification("error", self.currentPlayer, req["errorMessage"])
            end,
            'statusChangedEvent': def (req)
                if req['isPaused']
                    self.playbackState['status'] = 'paused'
                else
                    self.playbackState['status'] = 'playing'
                end
                self.updatePlaybackInfo()
            end,
            'youtubeEvent': def (ev)
                self.getPluginByName('youtube').onEvent('youtube', ev)
            end,
            'volumeChangedEvent': def (req)
                self.applyVolume(int(req['volume']))
            end,
            'handleConfigLoaded': def (config)
                self.loadConfForPlugin(config)
            end
        }
        self.plugins = []
        self.playbackState = {
            'song': {
                'songName': 'Queue empty',
                'artistName': '--',
                'sourceName': '--',
                'icon': '',
                'albumName': '--'
            },
            'eq': {
                'low': 0,
                'mid': 0,
                'high': 0
            },
            'volume': 50,
            'status': 'paused'
        }
        self.networkState = 'offline'
    end

    def registerHandler(type, handler)
        self.eventHandlers[type] = handler
    end

    def handleEvent(eventType, eventData)
        if (self.eventHandlers[eventType] != nil)
            self.eventHandlers[eventType](eventData)
        end
    end

    def updateSong(playbackInfo)
        self.playbackState['song'] = playbackInfo

        print(playbackInfo)
        if playbackInfo['sourceName'] != ''
            print("Being updated")
            self.playbackState['song']['sourceThemeColor'] = self.getPluginByName(playbackInfo['sourceName']).themeColor
        end
        self.updatePlaybackInfo()
    end

    def setStatus(playbackStatus)
        self.playbackState['status'] = playbackStatus
        self.updatePlaybackInfo()
    end

    def updatePlaybackInfo()
        http.publishEvent("playback", self.playbackState)
    end

    def sendNotification(type, from, text, submessage)
        var secondMessage = ""
        if submessage != nil 
            secondMessage = submessage
        end
        http.publishEvent("notification", { 'type': type, 'message': text, 'source': from, 'submessage': submessage })
    end

    def getAudioOutput()
        for plugin : self.plugins
            if (plugin.audioOutput) 
                return plugin
            end
        end

        return nil
    end

    def initRequiredPlugins()
        self.networkState = 'online'
        var plugin = self.getAudioOutput()
        if (plugin != nil)
            plugin.onEvent(EVENT_CONFIG_UPDATED, {})
            plugin.initAudio()
            setSignedness(plugin.getSignedness())
        end

        start_plugin_thread('cspot', self.getPluginByName('cspot').getBareValues())
        start_plugin_thread('webradio', self.getPluginByName('webradio').getBareValues())
        start_plugin_thread('jellyfin', self.getPluginByName('jellyfin').getBareValues())

        start_plugin_thread('bluetooth', {})
        #start_plugin_thread('youtube', self.getPluginByName('youtube').getBareValues())

        self.initHTTP()
    end

    def initHTTP()
        start_plugin_thread('http', {})
    end

    def registerPlugin(plugin)
        print('Registering plugin: ' + plugin.name)
        self.plugins.push(plugin)
        print(self.plugins)
    end

    def loadConfiguration()
        for plugin : self.plugins
            conf_load(plugin.name + ".config.json")
        end
    end

    def getPluginByName(name)
        for plugin : self.plugins
            if (plugin.name == name) 
                return plugin
            end
        end

        return nil
    end

    def broadcastEvent(eventType, eventData)
        for plugin : self.plugins
            plugin.onEvent(eventType, eventData)
        end
    end

    def sendPluginEvent(plugin, eventType, eventData)
        plugin = self.getPluginByName(plugin)
        plugin.onEvent(eventType, eventData)
    end

    def loadConfForPlugin(conf)
        var strIndex = string.find(conf['key'], ".config.json")
        if (strIndex > 0)
            var pluginName = string.split(conf['key'], strIndex)[0]
            plugin = self.getPluginByName(pluginName)
            plugin.loadConfig(conf['value'])
            plugin.configurationLoaded = true
            self.loadPluginsWhenReady()
        end
    end

    def loadPluginsWhenReady()
        if (!self.pluginsInitialized)
            for plugin : self.plugins
                if (!plugin.configurationLoaded)
                    return
                end
            end

            self.pluginsInitialized = true

            for plugin : self.plugins
                if plugin.type == 'init_handler'
                    plugin.onEvent(EVENT_SYSTEM_INIT, {})
                    return
                end
            end

            if get_platform() == 'desktop'
                self.initRequiredPlugins()
            end
        end
    end

    def applyVolume(volume)
        if get_platform() == 'desktop'
            setVolume(volume)
        else
            var dacPlugin = self.getPluginByName('dac')
            if !dacPlugin.hasHardwareVolume()
                setVolume(volume)
            end
        end

        self.playbackState['volume'] = volume
        self.updatePlaybackInfo()
        print("Broadcasting volume data")
        self.broadcastEvent(EVENT_VOLUME_UPDATED, volume)
    end
end

var app = App()

# Native closures
def initializeOutputs()
    print('Initializing audio output')
    app.initAudioOutput()
end

def handleEvent(eventType, eventData)
    app.handleEvent(eventType, eventData)
end

# HTTP Endpoints
http.handle('GET', '/plugins', def (request)
    var result = []
    for plugin : app.plugins
        result.push({
            'name': plugin.name,
            'displayName': plugin.displayName,
            'type': plugin.type
        })

        if plugin.exposeWebApp
            result.push({
                'name': plugin.name,
                'displayName': plugin.displayName,
                'type': 'app'
            })
        end
    end

    http.sendJSON(result, request['connection'], 200)
end)

http.handle('GET', '/plugins/:name', def (request)
    var result = {
        'status': 'error'
    }

    for plugin : app.plugins 
        if plugin.name == request['urlParams']['name']
            for key : plugin.configSchema.keys()
                if plugin.configSchema[key].find('value') == nil
                    plugin.configSchema[key]['value'] = plugin.configSchema[key]['defaultValue']
                end
            end

            result = {
                'displayName': plugin.displayName,
                'themeColor': plugin.themeColor,
                'configSchema': plugin.configSchema
            }
        end
    end

    http.sendJSON(result, request['connection'], 200)
end)

http.handle('POST', '/plugins/:name', def (request)
    var result = {
        'status': 'error'
    }
    var bodyObj = json.load(request['body'])

    var plugin = app.getPluginByName(request['urlParams']['name'])

    var confSchema = plugin.configSchema

    for key : bodyObj.keys()
        confSchema[key]['value'] = bodyObj[key]
    end

    plugin.persistConfig()
    http.sendJSON({ 'configSchema': confSchema, 'displayName': plugin.displayName, 'themeColor': plugin.themeColor }, request['connection'], 200)
    app.sendNotification("info", plugin.name, "Configuration updated")
    plugin.onEvent(EVENT_CONFIG_UPDATED, {})
end)

http.handle('GET', '/playback', def (request)
    http.sendJSON(app.playbackState, request['connection'], 200)
end)

http.handle('GET', '/info', def (request)
    http.sendJSON({
        'version': get_version(),
        'networkState': app.networkState
    }, request['connection'], 200)
end)

http.handle('POST', '/volume', def (request)
    var body = json.load(request['body'])
    app.applyVolume(int(body['volume']))

    http.sendJSON(body, request['connection'], 200)
end)

http.handle('POST', '/eq', def (request)
    var body = json.load(request['body'])
    eqSetBands(real(body['low']), real(body['mid']), real(body['high']))
    app.playbackState['eq'] = body
    app.updatePlaybackInfo()
    http.sendJSON(body, request['connection'], 200)
end)

http.handle('POST', '/play', def (request)
    app.playbackState['status'] = json.load(request['body'])['status']
    cspot = app.getPluginByName(app.currentPlayer)

    if app.playbackState['status'] == 'playing'
        cspot.onEvent(EVENT_SET_PAUSE, false)
    else
        cspot.onEvent(EVENT_SET_PAUSE, true)
    end

    core_empty_buffers()
    http.sendJSON({'status': 'ok'}, request['connection'], 200)
end)


def loadPlugins()
    app.loadConfiguration()
end

start_plugin_thread('persistor', {})
