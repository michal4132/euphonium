# TODO: Find better name
class GlobalConfigPlugin : Plugin
    def init()
        self.config_schema = {
            'eq': {
                'low': 0,
                'mid': 0,
                'high': 0
            },
            'volume': 50
        }

        self.name = "global_config"
        self.display_name = "Global Config"
        self.type = "system"

#        euphonium.register_handler('volumeChangedEvent', def (req)
#            print(req['volume'])
#            euphonium.apply_volume(int(req['volume']))
#        end)
    end

    def get_eq()
        return self.config_schema['eq']
    end
    
    def get_volume()
        return self.config_schema['volume']
    end
    
    def set_volume(volume)
        self.config_schema['volume'] = volume
    end
    
end

euphonium.register_plugin(GlobalConfigPlugin())
