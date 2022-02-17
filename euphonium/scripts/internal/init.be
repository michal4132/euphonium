# Load essential modules
core.load("internal/http.be")
core.load("internal/plugin.be")
core.load("internal/hooks.be")
core.load("internal/euphonium.be")
core.load("internal/api.be")
core.load("internal/global_config.be")

# Load plugins
core.load("plugin/cspot.be")
core.load("plugin/webradio.be")

# Load ESP32 modules
if core.platform() == "esp32"
    core.load("esp32/init.be")
end

# load user configuration
core.load("extensions.be")
