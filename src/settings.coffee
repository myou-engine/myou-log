fs = require 'fs'
{app} = require 'electron'
app_data = app.getPath('appData').replace('\\', '/') + '/myou-log/'
is_linux = process.platform == 'linux'
is_win = process.platform == 'win32'
is_mac = process.platform == 'darwin'



new class MyouLogSettings
    constructor: ->
        ctrl_key = if is_mac then "Command" else "Control"
        @settings = settings =
            inactivity_check_interval: 300000
            auto_show_window_timeout: 300000
            reminder_time: 60000
            global_shortcuts:
                yes: "#{ctrl_key}+Alt+Y"
                no: "#{ctrl_key}+Alt+N"
                questions_window: "#{ctrl_key}+Alt+Q"
                report_window: "#{ctrl_key}+Alt+R"
                settings_window: "#{ctrl_key}+Alt+S"
                sound_test: "#{ctrl_key}+Alt+P"
            open_on_startup: true
            log_file: app_data + 'log.json'
            reward_ratio: 1/4
            reward_pack: 300000 # 5 min
            day_boundary_inactivity: 2*3600*1000

        backwards_compatibility = (s)->
            debugger
            s.global_shortcuts.questions_window = s.global_shortcuts.main_window or "#{ctrl_key}+Alt+Q"
            delete s.global_shortcuts.main_window
            return s

        combine_changes = (original, changes)->
            for k,v of changes
                if not original[k]?
                    original[k] = v
                else if typeof(v) == 'object'
                    combine_changes original[k], v
                else
                    original[k] = v

        post_save_callbacks = []

        @add_post_save_callback = (callback)->
            post_save_callbacks.push callback

        default_settings = JSON.parse JSON.stringify(settings)

        @apply_default_settings = apply_default_settings = ->
            combine_changes settings, default_settings

        @save_settings = save_settings = (isDebug)=>
            if isDebug
                if @settings.open_on_startup
                    @settings.open_on_startup = false
                if not @settings.auto_open_dev_tools?
                    @settings.auto_open_dev_tools = false

            data = JSON.stringify @settings, null, 4
            try
                if  not fs.existsSync app_data
                    fs.mkdirSync app_data
                fs.writeFileSync app_data + 'settings.json', data
                console.log 'Saving settings:\n' + data
                for cb in post_save_callbacks
                    cb()

            catch err
                console.log err

        @load_settings = load_settings = =>
            if fs.existsSync app_data + 'settings.json'
                try
                    data = fs.readFileSync(app_data + 'settings.json', 'utf8').toString()
                    old_settings = backwards_compatibility  JSON.parse(data)
                    combine_changes(@settings, old_settings)
                    console.log 'Settings file read.'
                catch err
                    console.log err
                    console.log 'Using default settings.'

            save_settings()

myou_logs_settings = new MyouLogSettings
module.exports = myou_logs_settings
