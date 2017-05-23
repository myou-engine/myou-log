fs = require 'fs'
{app} = require 'electron'
app_data = app.getPath('appData').replace('\\', '/') + '/myou-log/'

new class MyouLogSettings


    constructor: ->
        @settings = settings =
            inactivity_check_interval: 300000
            auto_show_window_timeout: 300000
            global_shortcuts:
                yes: 'CommandOrControl+Alt+Y'
                no: 'CommandOrControl+Alt+N'
                main_window: 'CommandOrControl+Alt+Q'
                report_window: 'CommandOrControl+Alt+R'
            open_on_startup: true
            log_file: app_data + 'log.json'
            reward_ratio: 1/4
            reward_pack: 300000 # 5 min

        @save_settings = save_settings = =>
            data = JSON.stringify @settings, null, 4
            try
                fs.writeFileSync app_data + 'settings.json', data
                console.log 'Saving settings:\n' + data
            catch err
                console.log err

        @load_settings = load_settings = =>
            combine_changes = (original, changes)->
                for k,v of changes
                    if not original[k]?
                        original[k] = v
                    else if typeof(v) == 'object'
                        combine_changes original[k], v
                    else
                        original[k] = v

            if fs.existsSync app_data + 'settings.json'
                try
                    data = fs.readFileSync(app_data + 'settings.json', 'utf8').toString()
                    old_settings = JSON.parse(data)
                    combine_changes(@settings, old_settings)
                    console.log 'Settings file read.'
                catch err
                    console.log err
                    console.log 'Using default settings.'

            save_settings()

settings = new MyouLogSettings
module.exports = settings
