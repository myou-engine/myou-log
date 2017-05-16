log = require './log'

{react_utils, theme, mixins, components, sounds, format_time} = require './common_ui.coffee'
# MyoUI includes some React utils.
{Component, React, ReactDOM} = react_utils
{div} = React.DOM
# "Component" returns a radium component which will allow us
# to use arrays and objects combined in the same style property.

is_linux = process.platform == 'linux'

electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
window.settings = ewin.settings

window.$window = ewin
ewin.setAlwaysOnTop true
ewin.setVisibleOnAllWorkspaces true

addEventListener 'keydown', (event)->
    if event.keyCode == 123
        ewin.webContents.openDevTools({mode:'detach'})

settings = ewin.settings
window.$settings = settings

AutoLaunch = require 'auto-launch'
auto_launcher = window.auto_launcher = new AutoLaunch
    name: 'myou-log'

if not ewin.isDebug
    auto_launcher.enable().then ()->
        console.log 'Auto-launch enabled'

{Tray, Menu, app, globalShortcut} = electron.remote
path = require 'path'
trayMenuTemplate = [

    {
       label: 'Show app',
       click: ->
          show_window()
    }
    {
       label: 'Report viewer',
       click: ->
          ewin.create_report_window()
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

tray = new Tray __dirname + '/../static_files/images/icon.png'

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

show_window_timeout = null
hide_window = (break_time=0)->
    ewin.hide()
    console.log 'Set timeout to show window in 5 min.'
    show = ->
        show_window(true)
    show_window_timeout = setTimeout show,
        break_time or settings.auto_show_window_timeout

show_window_time = 0
show_window = (alarm)->
    show_window_time = Date.now()
    ewin.setAlwaysOnTop true
    clearTimeout show_window_timeout
    ewin.show()
    ewin.blur()
    if alarm
        ui_alarm?()
    else
        render_all?()
    set_inactivity_check?()

show_window()

last_check_inactivity_interval = null
set_inactivity_check = ->
    clearInterval last_check_inactivity_interval
    check_inactivity = ->
        time = (Date.now() - log.last_activity_change_date)
        if ewin.isVisible() and current_dialog == 0
            log.new_entry {active:false, date:show_window_time}
            render_all()
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
main_component = Component
    componentDidUpdate: ->
        current_dialog = @state.dialog

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

        yes_shortcut = globalShortcut.register settings.global_shortcuts.yes, =>
            if @state.dialog == 0
                @setState dialog: 1
                ewin.focus()
                set_auto_hide_time 10, ->
                    if not log.is_active
                        log.new_entry {active: true, date: Date.now()}

        no_shortcut = globalShortcut.register settings.global_shortcuts.no, =>
            if @state.dialog == 0
                log.new_entry {active: false, date: show_window_time}
                hide_window()

        if not yes_shortcut
            console.warn 'Global shorcut in use: ' + settings.global_shortcuts.yes
        if not no_shortcut
            console.warn 'Global shorcut in use: ' + settings.global_shortcuts.no

    getInitialState: ->
        dialog: 0
        auto_highlight: true
    render: ->
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
        time = (date_now - log.last_activity_change_date)
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
                    id: "yes_no_container"
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'

                    ]
                    components.button
                        label:'yes'
                        useHighlight:true
                        title: 'Global Shortcut: CommandOrControl+Alt+Y'
                        onClick: =>
                            @setState dialog: 1
                            set_auto_hide_time 10, ->
                                if not log.is_active
                                    log.new_entry {active: true, date: Date.now()}

                    components.button
                        label:'no'
                        useHighlight:true
                        title:"
                            Global Shortcut: CommandOrControl+Alt+N\n
                            I'll ask you again in 5 minutes
                            "
                        onClick: =>
                            log.new_entry {active: false, date: show_window_time}
                            hide_window()
            ]

            [
                components.message '''
                    What are you working on?
                    '''
                div
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
                alignItems: 'flex-start'
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
app_element = document.getElementById 'app'

render_all= ->
    ReactDOM.render main_component(), app_element

log.get_load_promise().then ->
    log.enable_last_date_checker()
    render_all()

setInterval render_all, 1000

window.addEventListener 'resize', render_all
