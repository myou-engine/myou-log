
{MyoUI, Theme, mixins, css_utils, react_utils} = require 'myoui'
# TODO: It is requiring local myoui from package.json but it is not commited.
# current published myoui version (0.0.2) is not fully compatible with this app.

# adding default css code to the document
require 'myoui/default_fonts'
require 'myoui/default_animations'

theme = new Theme
window.theme = theme
# adding webkitAppRegion to default theme
theme.UIElement.push {WebkitAppRegion: 'no-drag', cursor: 'pointer'}
theme.UIElementContainer = (disabled, useHighlight)-> [
    if useHighlight
        ':hover': [
            mixins.boxShadow theme.shadows.smallSoft
            background: 'white'
            color: 'black !important' # it's not working
            ]
    mixins.transition '250ms', 'background shadow width'
    if disabled
        opacity: 0.5
        pointerEvents: 'none'
    else
        opacity: 1
        pointerEvents:'all'
    minHeight:'auto'
    borderRadius: theme.radius.r3
]

myoui = new MyoUI theme
electron = require 'electron'
window.ewin = ewin = electron.remote.getCurrentWindow()
ewin.setAlwaysOnTop true
window.isDebug = ewin.isDebug

hide_window_timeout = null
hide_window = ->
    ewin.hide()
    setTimeout show_window, 60000 * 5 # 5 min

show_window = ->
    ewin.show()
    set_inactivity_check?()

show_window()

{Tray, Menu} = electron.remote
path = require 'path'
trayMenuTemplate = [

    {
       label: 'Show app',
       click: ->
          show_window()
    },
    {
       label: 'Clear log and quit',
       click: ->
          clear_log?()
          ewin.close()
    },
    {
       label: 'Quit',
       click: ->
          ewin.close()
    }
]

window.trayMenu = Menu.buildFromTemplate trayMenuTemplate
if tray?
    tray.destroy()
window.tray = new Tray require('./static_files/images/icon.png').replace('file://','')
tray.setContextMenu trayMenu
tray.on 'click', ->
    show_window()
ewin.on 'restore', ->
    clearTimeout hide_window_timeout
    if current_dialog == 1
        set_auto_hide_time 10
ewin.on 'minimize', ->
    hide_window()

app = document.getElementById 'app'

log = (localStorage.myoulog? and JSON.parse(localStorage.myoulog)) or []
if isDebug
    window.log = log

activity_state = (localStorage.myoulog_activity_state? and
    JSON.parse(localStorage.myoulog_activity_state)) or
    {active: false, date: Date.now()}
last_task = localStorage.myoulog_last_task or ''
first_log = false

add_log_entry = (entry)->
    new_entry = false
    if entry.active != activity_state.active
        activity_state.active = entry.active
        activity_state.date = entry.date
        localStorage.myoulog_activity_state = JSON.stringify activity_state
        new_entry = true

    if entry.task? and entry.task != last_task
        last_task = entry.task
        localStorage.myoulog_last_task = last_task
        new_entry = true

    if new_entry
        first_log = true
        console.log 'New log entry:', entry
        log.push entry
        localStorage.myoulog = JSON.stringify log


window.clear_log = ->
    localStorage.removeItem 'myoulog'
    localStorage.removeItem 'myoulog_activity_state'
    localStorage.removeItem 'myoulog_last_task'
    localStorage.removeItem 'myoulog_last_date'

if localStorage.myoulog_last_date?
    last_date = parseInt localStorage.myoulog_last_date
    add_log_entry {active:false, date:last_date}

last_check_inactivity_interval = null
set_inactivity_check = ->
    clearInterval last_check_inactivity_interval
    check_inactivity = ->
        if ewin.isVisible() and current_dialog == 0
            add_log_entry {active:false, date:Date.now()}
            render_all()

    last_check_inactivity_interval = setInterval check_inactivity, 60000

# Creating instances of myoui elements
text_input = new myoui.TextInput
    label: (maxWidth='calc(100% - 30px)')->
        maxWidth: 'calc(100% - 10px)'
        margin: "0px #{theme.spacing}px"

button = new myoui.Button
    button:
        maxWidth: 200

# MyoUI includes some React utils.
{Component, React, ReactDOM} = react_utils
{div} = React.DOM
# "Component" returns a radium component which will allow us
# to use arrays and objects combined in the same style property.

message = (message, custom_style) ->
    div
        className: 'myoui'
        style:[
            whiteSpace: 'pre-wrap'
            theme.UIElement
            minHeight: 'auto'
            textAlign: 'center'
            fontSize: 20
            fontWeight: 100
            alignSelf: 'center'
            WebkitAppRegion: 'drag'
            custom_style
        ]
        message

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

# This is to know the value of the current
# active dialog out of the component render function
current_dialog = 0

main_component = Component
    componentDidUpdate: (cosas)->
        current_dialog = @state.dialog

    componentWillMount: ->
        current_dialog = @state.dialog
        set_inactivity_check()
        set_dialog = (dialog=0)=>
            if dialog == 0
                set_inactivity_check()
            @setState {dialog}

    getInitialState: ->
        dialog: 0

    render: ->
        working_on_value = last_task
        working_on_submit = ()=>
            if working_on_value
                add_log_entry {active: true, date: Date.now(), task: working_on_value}
            else
                add_log_entry {active: true, date: Date.now()}

            set_auto_hide_time Infinity
            hide_window()
            set_dialog 0
        working_on =
            useHighlight: true
            label: "I'm working on"
            read: -> working_on_value
            onSubmit: working_on_submit
            onChange: (new_value)-> working_on_value = new_value
            onClick: (event)->
                if event.target.className != 'text_input'
                    working_on_submit()
            onFocus: ->
                set_auto_hide_time Infinity


        are_you_working_message = 'Are you working?'

        if log.length
            time = (Date.now() - activity_state.date)
            if time < 60000 # 1min
                ftime = '\nless than 1 min'
            else if time < 3600000 # 1hour
                ftime = '\n' + Math.floor(time/60000) + ' min'
            else
                hours = time/3600000
                only_hours = Math.floor(hours)
                only_min = Math.floor((hours - only_hours) * 60)
                ftime = '\n' + only_hours + ' hours ' + only_min + ' min'

            if activity_state.active
                are_you_working_message = "
                    You've been working for #{ftime}.\n\n
                    Are you still working?"
            else
                are_you_working_message = "
                    You've been distracted for #{ftime}.\n\n
                    Did you start working?"

        dialogs = [

            [
                message are_you_working_message


                div
                    id: "yes_no_container"
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                    ]
                    button.ui
                        label:'yes'
                        useHighlight:true
                        onClick: =>
                            @setState dialog: 1
                            set_auto_hide_time 10, ->
                                if not activity_state.active
                                    add_log_entry {active: true, date: Date.now()}

                    button.ui
                        label:'no'
                        useHighlight:true
                        title:"I'll ask you again in 5 minutes"
                        onClick: =>
                            add_log_entry {active: false, date: Date.now()}
                            hide_window()
            ]

            [
                message '''
                    What are you working on?
                    '''
                div
                    title:"I'll ask you again in 5 minutes"
                    style: [
                        mixins.rowFlex
                        alignSelf: 'center'
                        width: 'calc(100% - 30px)'
                    ]
                    text_input.ui working_on
                    button.ui
                        label:"I don't know"
                        useHighlight:true
                        onClick: =>
                            set_auto_hide_time Infinity
                            @setState dialog: 0
                            add_log_entry {active: true, date: Date.now()}
                            hide_window()


                message "Time to auto-hide: #{auto_hide_time} s",
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
                left: 4
                width: 'calc(100vw - 10px)'
                height: 'calc(100vh - 13px)'
                backgroundColor: theme.colors.light
                borderRadius: theme.radius.r4
                position: 'absolute'
                overflowX: 'hidden'
                WebkitAppRegion: 'drag'
                mixins.border3d 0.5
                mixins.boxShadow theme.shadows.hard
            ]
            dialog
            # text_input.ui working_on


# Rendering main_component with ReactDOM in our HTML element ```app```
render_all= ->
    ReactDOM.render main_component(), app
render_all()

save_last_date = ->
    localStorage.myoulog_last_date = Date.now()

setInterval save_last_date, 1

window.addEventListener 'resize', render_all
