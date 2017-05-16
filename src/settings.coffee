fs = require 'fs'

new class MyouLogSettings
    constructor: ->
        @settings = settings =
            inactivity_check_interval: 300000
            auto_show_window_timeout: 300000
            global_shortcuts:
                yes: 'CommandOrControl+Alt+Y'
                no: 'CommandOrControl+Alt+N'
            open_on_startup: true
            log_file: 'log.json'

        @save_settings = save_settings = => new Promise (resolve, reject)=>
            data = JSON.stringify @settings, null, 4
            fs.writeFile 'settings.json', data, (err)->
                if err
                    console.log err
                    reject()
                else
                    console.log 'Saving settings:\n' + data
                    resolve()

        @load_settings = load_settings = => new Promise (resolve, reject)=>
            if fs.existsSync 'settings.json'
                fs.readFile 'settings.json', 'utf8', (err, data)=>
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
