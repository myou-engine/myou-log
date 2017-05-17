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
            open_on_startup: true
            log_file: app_data + 'log.json'
            reward_ratio: 1/4
            reward_pack: 300000 # 5 min

        @save_settings = save_settings = => new Promise (resolve, reject)=>
            data = JSON.stringify @settings, null, 4
            fs.writeFile app_data + 'settings.json', data, (err)->
                if err
                    console.log err
                    reject()
                else
                    console.log 'Saving settings:\n' + data
                    resolve()

        @load_settings = load_settings = => new Promise (resolve, reject)=>
            if fs.existsSync app_data + 'settings.json'
                fs.readFile app_data + 'settings.json', 'utf8', (err, data)=>
                    if err
                        console.log err
                        console.log 'Using default settings.'
                    else
                        try
                            old_settings = JSON.parse(data)
                            for k,v of old_settings
                                @settings[k] = v
                            console.log 'Settings file read.'
                        catch err
                            console.log err
                            console.log 'Using default settings.'

                        save_settings().then ->
                            resolve()
            else
                save_settings().then ->
                    resolve()

settings = new MyouLogSettings
module.exports = settings
