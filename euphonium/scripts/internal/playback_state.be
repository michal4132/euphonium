class PlaybackState : Plugin
    var state
    def init()
        # dynamic config
        self.state = {
            'song': {
                'songName': 'Queue empty',
                'artistName': '--',
                'sourceName': '--',
                'icon': '',
                'albumName': '--'
            },
            'status': 'paused'
        }

        # persistent config
        self.config_schema = {
            'eq_low': { 'defaultValue': 0, 'type': 'number' },
            'eq_mid': { 'defaultValue': 0, 'type': 'number' },
            'eq_high': { 'defaultValue': 0, 'type': 'number' },
            'volume': { 'defaultValue': 50, 'type': 'number' }
        }

        self.apply_default_values()
        self.name = "playback_state"
        self.type = "system"
    
        euphonium.register_handler('volumeChangedEvent', def (req)
            self.persist_config()
            euphonium.apply_volume(int(req['volume']))
        end)
    end

    def get_state()
        var full_state = {}

        # copy dynamic config
        for key : self.state.keys()
            full_state[key] = self.state[key]
        end

        # copy persistent config
        full_state['eq'] = {'low': self.config_schema['eq_low']['value'],
                            'mid': self.config_schema['eq_mid']['value'],
                            'high': self.config_schema['eq_high']['value']}
        full_state['volume'] = self.config_schema['volume']['value']

        return full_state
    end

    def set_status(status)
        self.state['status'] = status
    end

    def get_status()
        return self.state['status']
    end

    def set_eq(low, mid, high)
        self.config_schema['eq_low']['value'] = low
        self.config_schema['eq_mid']['value'] = mid
        self.config_schema['eq_high']['value'] = high
        self.persist_config()
    end

    def get_eq()
        var eq = {}
        eq.push(self.config_schema['eq_low'])
        eq.push(self.config_schema['eq_mid'])
        eq.push(self.config_schema['eq_high'])
        return eq
    end
    
    def get_volume()
        return self.config_schema['volume']['value']
    end
    
    def set_volume(volume)
        self.config_schema['volume']['value'] = volume
        self.persist_config()
    end
end

var playback_state = PlaybackState()
euphonium.register_plugin(playback_state)
euphonium.playback_state = playback_state