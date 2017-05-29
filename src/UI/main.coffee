log = require '../log'

{react_utils, theme, mixins, components, sounds, format_time} = require './common.coffee'
# MyoUI includes some React utils.
{Component, React, ReactDOM} = react_utils
{div} = React.DOM
# "Component" returns a radium component which will allow us
# to use arrays and objects combined in the same style property.

is_linux = process.platform == 'linux'
is_win = process.platform == 'win32'
is_mac = process.platform == 'darwin'

electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
window.$window = ewin
ewin.setAlwaysOnTop true
ewin.setVisibleOnAllWorkspaces true

app_element = document.getElementById 'app'

# Adjusting window size to include window border
inset_rect = app_element.getClientRects()[0]
size = ewin.getSize()
window_border_width = size[0] - inset_rect.width
new_width = size[0] + window_border_width
min_height = ewin.getMinimumSize()[1]
ewin.setSize new_width, size[1]
ewin.setMinimumSize new_width, min_height
console.log new_width, min_height


ewin.on 'close', ()->
    report_window?.close()
    settings_window?.close()

{Tray, Menu, app, globalShortcut} = electron.remote
path = require 'path'

addEventListener 'keydown', (event)->
    if event.keyCode == 123
        ewin.webContents.openDevTools({mode:'detach'})

report_window = null
show_report_window = ->
    if report_window
        report_window.show()
    else
        report_window = ewin.create_report_window()
        report_window.on 'closed', ->
            report_window = null

settings_window = null
show_settings_window = ->
    if settings_window
        settings_window.show()
    else
        settings_window = ewin.create_settings_window()
        settings_window.on 'closed', ->
            settings_window = null

AutoLaunch = require 'auto-launch'
auto_launcher = window.auto_launcher = new AutoLaunch
    name: 'myou-log'


{settings, add_post_save_callback} = ewin

add_post_save_callback ->
    apply_settings()
    show_window()


show_main_window_shortcut = false
show_report_window_shortcut = false
show_settings_window_shortcut = false
yes_shortcut = false
no_shortcut = false

apply_settings = ->
    clearTimeout show_window_timeout
    clearInterval last_check_inactivity_interval

    if settings.open_on_startup
        auto_launcher.isEnabled().then (enabled)->
            if not enabled
                auto_launcher.enable().then ()->
                    console.log 'Open on system startup ENABLED'
    else
        auto_launcher.isEnabled().then (enabled)->
            if enabled
                auto_launcher.disable().then ()->
                    console.log 'Open on system startup DISABLED'

    if show_main_window_shortcut
        globalShortcut.unregister show_main_window_shortcut
    if show_report_window_shortcut
        globalShortcut.unregister show_report_window_shortcut
    if show_settings_window_shortcut
        globalShortcut.unregister show_settings_window_shortcut
    if yes_shortcut
        globalShortcut.unregister yes_shortcut
    if no_shortcut
        globalShortcut.unregister no_shortcut

    main_registered = globalShortcut.register settings.global_shortcuts.main_window, ->
        set_dialog 0
        show_window()
    report_registered = globalShortcut.register settings.global_shortcuts.report_window, show_report_window
    settings_registered = globalShortcut.register settings.global_shortcuts.settings_window, show_settings_window

    if main_registered
        show_main_window_shortcut = settings.global_shortcuts.main_window
    else
        show_main_window_shortcut = false
        console.warn 'Global shorcut in use: ' + settings.global_shortcuts.main_window
    if report_registered
        show_report_window_shortcut = settings.global_shortcuts.report_window
    else
        show_report_window_shortcut = false
        console.warn 'Global shorcut in use: ' + settings.global_shortcuts.report_window

apply_settings()

trayMenuTemplate = [

    {
       label: 'Show questions',
       click: ->
          show_window()
    }
    {
       label: 'Show report',
       click: ->
          show_report_window()
    }
    {
       label: 'Show settings',
       click: ->
          show_settings_window()
    }
    {
       label: 'Quit',
       click: ->
           localStorage.myoulog_win_position = JSON.stringify ewin.getPosition()
           tray.destroy()
           ewin.close()
    }
]

trayMenu = Menu.buildFromTemplate trayMenuTemplate

if is_win
    icon = '/../../assets/icons/win/icon.ico'
if is_mac
    icon = '/../../assets/icons/mac/icon.icns'
else
    icon = '/../../assets/icons/png/24x24.png'


tray = new Tray __dirname + icon

tray.setContextMenu trayMenu
tray.on 'click', ->
    show_window()
ewin.on 'minimize', ->
    hide_window()

addEventListener 'beforeunload', ->
    tray.destroy()
    globalShortcut.unregisterAll()

win_position = localStorage.myoulog_win_position
if win_position
    win_position = JSON.parse win_position
    ewin.setPosition win_position[0], win_position[1]

hidden_window = false
show_window_timeout = null
hide_window = (break_time=0)->
    hidden_window = true
    break_time = break_time or settings.auto_show_window_timeout
    ewin.hide()
    console.log "Set timeout to show window in #{format_time break_time}."
    show = ->
        show_window(true)
    show_window_timeout = setTimeout show, break_time

show_window_time = 0
show_window = (alarm)->
    hidden_window = false
    show_window_time = Date.now()
    ewin.setAlwaysOnTop true
    clearTimeout show_window_timeout
    # play again (not pause)
    if log.is_paused
        log.new_entry {pause:false, date:show_window_time}
    ewin.show()
    ewin.blur()
    if alarm
        ui_alarm?()
    else
        render_all?()
    set_inactivity_check?()



last_check_inactivity_interval = null
set_inactivity_check = ->
    clearInterval last_check_inactivity_interval
    check_inactivity = ->
        if hidden_window
            return
        set_dialog 0
        log.new_entry {active:false, date:show_window_time}
        ui_alarm()

    last_check_inactivity_interval = setInterval check_inactivity,
        settings.inactivity_check_interval

addEventListener 'click', set_inactivity_check
addEventListener 'keydown', -> if current_dialog == 1 then set_inactivity_check()

auto_hide_time = Infinity
last_auto_hide_interval = null
set_auto_hide_time = (time=10, callback=->)->
    clearInterval last_auto_hide_interval
    auto_hide_time = time
    if auto_hide_time == Infinity
        render_all()
        return

    auto_hide_interval = ->
        auto_hide_time -= 1
        if auto_hide_time == 0
            set_auto_hide_time Infinity
            set_dialog(0)
            callback?()
            hide_window()
        render_all()

    last_auto_hide_interval = setInterval auto_hide_interval, 1000
    render_all()

# This function will be filled on componentWillMount
set_dialog = ->
ui_alarm = ->
# This is to know the value of the current
# active dialog out of the component render function
current_dialog = 0
working_on_value = ''
selected_reward = 0
main_component = Component
    componentDidUpdate: ->
        current_dialog = @state.dialog

    componentWillReceiveProps: (next_props)->
        log_reward = log.get_reward()
        if @state.dialog == 2
            if not log_reward
                @setState {dialog:0}
        else
            selected_reward = log_reward


    componentWillMount: ->
        current_dialog = @state.dialog

        ui_alarm = (duration=1000)=>
            @setState {alarm:true}
            sounds.notification.play()
            disable_alarm = =>
                @setState {alarm:false}
            setTimeout disable_alarm, duration

        set_inactivity_check()
        set_dialog = (dialog=0)=>
            if dialog == 0
                set_inactivity_check()
            @setState {dialog}

        yes_sc = globalShortcut.register settings.global_shortcuts.yes, =>
            if @state.dialog == 0
                @setState dialog: 1
                ewin.focus()
                set_inactivity_check()
                set_auto_hide_time 10, ->
                    if not log.is_active
                        log.new_entry {active: true, date: Date.now()}

        no_sc = globalShortcut.register settings.global_shortcuts.no, =>
            if @state.dialog == 0
                log.new_entry {active: false, date: show_window_time}
                hide_window()

        if yes_sc
            yes_shortcut = settings.global_shortcuts.yes
        else
            yes_shortcut = false
            console.warn 'Global shorcut in use: ' + settings.global_shortcuts.yes
        if no_sc
            no_shortcut = settings.global_shortcuts.no
        else
            no_shortcut = false
            console.warn 'Global shorcut in use: ' + settings.global_shortcuts.no

    getInitialState: ->
        dialog: 0
        auto_highlight: true
    render: ->
        log_reward = log.get_reward()
        selected_reward = Math.min(selected_reward, log_reward)
        auto_highlight = @state.auto_highlight and (auto_hide_time != Infinity)
        if not @state.writing_working_on
            working_on_value = log.last_task
        working_on_submit = ()=>
            @setState {
                auto_highlight: true
                writing_working_on: false
            }
            if working_on_value
                log.new_entry {active: true, date: Date.now(), task: working_on_value}
            else
                log.new_entry {active: true, date: Date.now()}

            set_auto_hide_time Infinity
            hide_window()
            set_dialog 0


        are_you_working_message = 'Are you working?'

        date_now = Date.now()
        time = log.get_activity_duration log.last_activity_change.index

        time_since_show_window = date_now - show_window_time

        if log.entries.length
            if log.is_active
                are_you_working_message = "
                    You've been working for\n#{format_time(time)}\n\n
                    Are you still working?"
                if time_since_show_window > 60000
                    are_you_working_message = "
                        It looks like you've \nbeen distracted for\n#{format_time(time_since_show_window)}\n\n
                        Were you working?
                    "
            else
                are_you_working_message = "
                    You've been distracted for\n#{format_time(time)}\n\n
                    Did you start working?"

        dialogs = [
            [
                components.message are_you_working_message
                div
                    key: 'yes_no_container'
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                    ]
                    components.button
                        label:'yes'
                        useHighlight:true
                        title: "Global Shortcut: #{settings.global_shortcuts.yes}"
                        onClick: =>
                            set_inactivity_check()
                            @setState dialog: 1
                            set_auto_hide_time 10, ->
                                if not log.is_active
                                    log.new_entry {active: true, date: Date.now()}

                    components.button
                        label:'no'
                        useHighlight:true
                        title:"
                            Global Shortcut: #{settings.global_shortcuts.no}\n
                            I'll ask you again in 5 minutes
                            "
                        onClick: =>
                            log.new_entry {active: false, date: show_window_time}
                            hide_window()

                    if log_reward
                        components.button
                            label: 'rest'
                            useHighlight: true
                            title:"Available time:\n#{format_time log_reward}"
                            onClick: =>
                                selected_reward = Math.max settings.reward_pack, Math.min selected_reward, log_reward
                                @setState dialog: 2

            ]

            [
                components.message '''
                    What are you working on?
                    '''
                div
                    key: 'waywo_answer'
                    title:"I'll ask you again in 5 minutes"
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                        width: 'calc(100% - 30px)'
                    ]
                    components.text_input
                        autoFocus: true
                        useHighlight: true
                        forceHighlight: auto_highlight and log.last_entry?.task
                        label: "I'm working on"
                        read: -> working_on_value
                        onSubmit: working_on_submit
                        onChange: (new_value)=>
                            set_auto_hide_time Infinity
                            @setState {writing_working_on:true}
                            working_on_value = new_value
                        onClick: (event)=>
                            if event.target.className != 'text_input'
                                working_on_submit()
                            else
                                set_auto_hide_time Infinity

                        onMouseOver: =>
                            @setState {auto_highlight:false}
                        onMouseLeave: =>
                            @setState {auto_highlight:true}

                    components.button
                        label:"I don't know"
                        useHighlight:true
                        forceHighlight: auto_highlight and not (log.last_entry?.task)
                        onMouseOver: =>
                            @setState {auto_highlight:false}
                        onMouseLeave: =>
                            @setState {auto_highlight:true}
                        onClick: =>
                            set_auto_hide_time Infinity
                            @setState dialog: 0
                            log.new_entry {active: true, date: Date.now()}
                            hide_window()
                            @setState {auto_highlight:true}


                components.message "Time to auto-answer: #{auto_hide_time} sec",
                    opacity: if auto_hide_time == Infinity then 0 else 1
            ]
            [

                components.message "
                    How long do you
                    want to rest?
                    "
                components.slider
                    key: 'reward_slider'
                    min: Math.min 1000, settings.reward_pack/5
                    max: Math.max log_reward, settings.reward_pack
                    step: Math.min 1000, settings.reward_pack/5
                    allowManualEdit: false
                    formatValue: (v)->
                        format_time v
                    read: -> selected_reward
                    onSlideEnd: (v)-> selected_reward = v

                div
                    key: 'cancel_ok_container'
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                        margin: "10px 0 10px 0"
                    ]
                    components.button
                        label:'cancel'
                        useHighlight:true
                        title:"Back to the previous dialog"
                        onClick: =>
                            @setState dialog: 0

                    components.button
                        label:'ok'
                        useHighlight:true
                        title: "I'll ask you again after your break time."
                        onClick: =>
                            log.new_entry {pause: true, date: Date.now()}
                            @setState dialog: 0
                            hide_window selected_reward



            ]
        ]

        dialog = dialogs[@state.dialog]
        if not dialog?
            ewin.close()
            return

        div
            id: 'main_container'
            style: [
                mixins.columnFlex
                justifyContent: 'center'
                alignItems: 'center'
                top: '0'
                backgroundColor: if @state.alarm then theme.colors.green else theme.colors.light
                position: 'absolute'
                overflowX: 'hidden'
                WebkitAppRegion: 'drag'
                mixins.transition '0.5s', 'background-color'
                if is_linux then [
                    left: 0
                    width: '100vw'
                    height: '100vh'
                    borderRadius: 0
                ] else [
                    left: 4
                    width: 'calc(100vw - 10px)'
                    height: 'calc(100vh - 13px)'
                    borderRadius: theme.radius.r4
                    mixins.border3d 0.5
                    mixins.boxShadow theme.shadows.hard
                ]

            ]
            dialog


# Rendering main_component with ReactDOM in our HTML element `app`
render_all= ->
    ReactDOM.render main_component(), app_element

log.get_load_promise().then ->
    log.enable_last_date_checker()
    selected_reward = log.get_reward()
    show_window()


setInterval render_all, 1000

window.addEventListener 'resize', render_all
