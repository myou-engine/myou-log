# checking OS
is_linux = process.platform == 'linux'
is_win = process.platform == 'win32'
is_mac = process.platform == 'darwin'

# common
{react_utils, theme, mixins, components, sounds} = require './common.coffee'
{React, ReactDOM} = react_utils
e = React.createElement

# Time utils
{Time, format_time} = require './time'

# log
{log} = require '../log'
{get_todays_activity_duration} = require '../report_log'

#Electron window/Settings
electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
{settings, add_post_save_callback} = ewin

# Sound hack for Pulseaudio (using setTimeoutSH instead of setTimeout)
# we play the notification sound muted a little bit before showing
# the window and playing it again to ensure pulseaudio doesn't chop it
setTimeoutSH = (f, t) ->
    timer_id = setTimeout f, t
    hack_id = setTimeout ->
        sounds.notification.muted = true
        sounds.notification.play().then ->
            sounds.notification.src += ''
    , t-1000
    return {timer_id, hack_id}

clearTimeoutSH = (ids) ->
    {timer_id, hack_id} = ids or {}
    clearTimeout hack_id
    clearTimeout timer_id

when_window_was_shown = 0
current_dialog = 0
current_activity = ''
reward = log.get_reward()

#DIALOGS
class AskIfActive extends React.Component
    constructor: (props={})->
        super props

    render: ->
        date_now = Date.now()
        last_activity_duration = log.get_activity_duration(
                log.last_activity_change.hidden.index)
        time_since_show_window = date_now - when_window_was_shown

        question = 'Are you working?'
        log_reward = log.get_reward()
        reward = Math.min(reward, log_reward)

        if log.entries.length
            if log.is_active
                question = e Time,
                    text: "You've been working for\n #time\n\n
                        Are you still working?"
                    time: last_activity_duration
                    no_drag: true
                if time_since_show_window >= settings.reminder_time
                    question = e Time,
                        text: "It looks like you've \nbeen distracted for\n#time\n\n
                            Were you working?"
                        time: time_since_show_window
                        no_drag: true

            else
                reminder_time = null
                question = e Time,
                    text: "You've been distracted for\n#time\n\n
                        Did you start working?"
                    time: last_activity_duration
                    no_drag: true

        [
            e 'div',
                title: 'Work time so far today\n' + format_time(
                        get_todays_activity_duration(log)
                    )
                style: WebkitAppRegion: 'no-drag'
                components.message question
            e 'div',
                key: 'yes_no_container'
                style: {
                    mixins.rowFlex...
                    alignSelf: 'center'
                }
                components.button
                    label:'yes'
                    useHighlight:true
                    title: "Global Shortcut: #{settings.global_shortcuts.yes}"
                    onClick: =>
                        set_inactivity_check()
                        set_dialog 'AskActivity'
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
                        log.new_entry {active: false, date: when_window_was_shown}
                        hide_window()

                if log_reward
                    components.button
                        label: 'rest'
                        useHighlight: true
                        title: "Available time:\n#{format_time log_reward}"
                        onClick: =>
                            reward = Math.max(
                                settings.reward_pack
                                Math.min(
                                    reward
                                    log_reward
                                )
                            )
                            set_dialog 'Reward'
        ]


class AskActivity extends React.Component
    constructor: (props={})->
        super props
        @state =
            auto_highlight: true

    render: ->
        auto_highlight = @state.auto_highlight and (auto_hide_time != Infinity)
        if not @state.writing_working_on
            current_activity = log.last_task
        working_on_submit = ()=>
            @setState {
                auto_highlight: true
                writing_working_on: false
            }
            if current_activity
                log.new_entry {active: true, date: Date.now(), task: current_activity}
            else
                log.new_entry {active: true, date: Date.now()}

            set_auto_hide_time Infinity
            hide_window()
            set_dialog 'AskIfActive'

        [
            components.message '''
                What are you working on?
                '''
            e 'div',
                key: 'waywo_answer'
                title:"I'll ask you again in 5 minutes"
                style: {
                    mixins.rowFlex...
                    alignSelf: 'center'
                    width: 'calc(100% - 30px)'
                }
                components.text_input
                    theme: UIElement:{theme.UIElement..., cursor:'pointer'}
                    autoFocus: true
                    forceHighlight: auto_highlight and log.last_entry?.task
                    label: "I'm working on"
                    read: -> current_activity
                    onSubmit: working_on_submit
                    onChange: (new_value)=>
                        if not @state.writing_working_on
                            set_auto_hide_time Infinity
                            @setState {writing_working_on:true}
                        current_activity = new_value
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


class Reward extends React.Component
    constructor: (props={})->
        super props
    render: ->
        log_reward = log.get_reward()

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
                read: -> reward
                onSlideEnd: (v)-> reward = v

            e 'div',
                key: 'cancel_ok_container'
                style: {
                    mixins.rowFlex...
                    alignSelf: 'center'
                    margin: "10px 0 10px 0"
                }
                components.button
                    label:'cancel'
                    useHighlight:true
                    title:"Back to the previous dialog"
                    onClick: =>
                        set_dialog 'AskIfActive'

                components.button
                    label:'ok'
                    useHighlight:true
                    title: "I'll ask you again after your break time."
                    onClick: =>
                        log.new_entry {pause: true, date: Date.now()}
                        set_dialog 'AskIfActive'
                        hide_window reward
            ]

dialogs = {AskIfActive, AskActivity, Reward}

hidden_window = false
show_window_timeout = null
hide_window = (break_time=0)->
    hidden_window = true
    break_time = break_time or settings.auto_show_window_timeout
    ewin.hide()
    console.log "Set timeout to show window in #{format_time break_time}."
    show = ->
        show_window(true)
    show_window_timeout = setTimeoutSH show, break_time

ewin.on 'minimize', ->
    hide_window()

exports.show_window = show_window = (alarm)->
    hidden_window = false
    ewin.show()
    ewin.blur()
    when_window_was_shown = Date.now()
    clearTimeoutSH show_window_timeout
    # play again (not pause)
    if log.is_paused
        log.new_entry {pause:false, date:when_window_was_shown}
    if alarm
        ui_alarm?()
    else
        render_all?()
    reminder_time = null
    set_inactivity_check?()

add_post_save_callback ->
    clearTimeoutSH show_window_timeout
    clearTimeoutSH last_check_inactivity_interval
    show_window()

last_check_inactivity_interval = null
last_reminder_interval = null
set_inactivity_check = ->
    clearTimeoutSH last_check_inactivity_interval
    clearTimeoutSH last_reminder_interval
    check_inactivity = ->
        if not hidden_window
            last_check_inactivity_interval = setTimeoutSH check_inactivity,
                settings.inactivity_check_interval
            set_dialog 'AskIfActive'
            log.new_entry {active:false, date:when_window_was_shown}
            ui_alarm()
    check_reminder = ->
        if log.is_active and not hidden_window
            last_reminder_interval = setTimeoutSH check_reminder, settings.reminder_time
            ui_alarm()

    last_check_inactivity_interval = setTimeoutSH check_inactivity,
        settings.inactivity_check_interval
    last_reminder_interval = setTimeoutSH check_reminder, settings.reminder_time


addEventListener 'click', set_inactivity_check
addEventListener 'keydown', -> if current_dialog == 1 then set_inactivity_check()

auto_hide_time = Infinity
last_auto_hide_interval = null
set_auto_hide_time = (time=10, callback)->
    clearInterval last_auto_hide_interval
    auto_hide_time = time
    if auto_hide_time == Infinity
        render_all()
        return

    auto_hide_interval = ->
        auto_hide_time -= 1
        if auto_hide_time == 0
            set_auto_hide_time Infinity
            set_dialog 'AskIfActive'
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

{globalShortcut} = electron.remote

class MainComponent extends React.Component
    constructor: (props={})->
        super props
        @state = dialog: 'AskIfActive'

    componentDidUpdate: ->
        current_dialog = @state.dialog

    componentWillReceiveProps: (next_props)->
        log_reward = log.get_reward()
        if @state.dialog == 'Reward'
            if not log_reward
                set_dialog 'AskIfActive'
        else
            reward = log_reward

    componentWillMount: ->
        current_dialog = @state.dialog

        ui_alarm = (duration=1000)=>
            @setState {alarm:true}
            sounds.notification.muted = false
            sounds.notification.play()
            disable_alarm = =>
                @setState {alarm:false}
            setTimeout disable_alarm, duration

        set_inactivity_check()
        set_dialog = (dialog='AskIfActive')=>
            if dialog == 'AskIfActive'
                set_inactivity_check()
            @setState {dialog}

        yes_sc = globalShortcut.register settings.global_shortcuts.yes, =>
            if @state.dialog == 'AskIfActive'
                @setState dialog: 'AskActivity'
                ewin.focus()
                set_inactivity_check()
                set_auto_hide_time 10, ->
                    if not log.is_active
                        log.new_entry {active: true, date: Date.now()}

        no_sc = globalShortcut.register settings.global_shortcuts.no, =>
            if @state.dialog == 'AskIfActive'
                log.new_entry {active: false, date: when_window_was_shown}
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


    render: ->
        if hidden_window
            return null

        dialog = dialogs[@state.dialog]

        if not dialog?
            throw "Unexpected dialog state: #{@state.dialog}"
            return

        e 'div',
            id: 'main_container'
            style: {
                mixins.columnFlex...
                justifyContent: 'center'
                alignItems: 'center'
                top: '0'
                backgroundColor: if @state.alarm then theme.colors.green else theme.colors.light
                position: 'absolute'
                overflowX: 'hidden'
                WebkitAppRegion: 'drag'
                mixins.transition('0.5s', 'background-color')...
                (if is_linux
                    left: 0
                    width: '100vw'
                    height: '100vh'
                    borderRadius: 0
                else {
                    mixins.border3d(0.5)...
                    left: 4
                    width: 'calc(100vw - 10px)'
                    height: 'calc(100vh - 13px)'
                    borderRadius: theme.radius.r4
                    boxShadow: theme.shadows.hard
                }
                )...

            }
            e dialog


# Rendering main_component with ReactDOM in our HTML element `app`
app_element = document.getElementById 'app'
render_all= ->
    ReactDOM.render e(MainComponent), app_element

log.enable_last_date_checker()
show_window()

window.addEventListener 'resize', render_all
