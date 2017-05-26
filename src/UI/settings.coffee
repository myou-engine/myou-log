{react_utils, theme, mixins, components, sounds, format_time, markdown, moment} = require './common.coffee'
{Component, React, ReactDOM} = react_utils
{div, b} = React.DOM

electron = require 'electron'
ewin = electron.remote.getCurrentWindow()

# title = (message)->
#     div
#         style:[
#             theme.fontStyles.titleLightS
#             padding: '30px 10px 10px 0'
#         ]
#         message

{settings, load_settings, save_settings, apply_default_settings, isDebug} = ewin
main_component = Component
    render: ->
        div
            className: 'myoui'
            style:[
                theme.fontStyles.p
                color: theme.colors.t1
                textShadow: theme.shadows.textWhite
                overflow: 'hidden'
                height: '100vh'
            ]
            div
                className: 'Floating bar'
                style: [
                    theme.fontStyles.titleLightS
                    mixins.rowFlex
                    mixins.boxShadow '0 5px 10px rgba(0,0,0,0.1)'
                    width: '100vw'
                    height: 50
                    background: 'white'
                    position: 'fixed'
                    top: 0
                    justifyContent: 'space-around'
                    zIndex: 1000
                ]

                components.button
                    label:"Default settings"
                    useHighlight:true
                    onClick: ->
                        apply_default_settings()
                        save_settings(isDebug)
                        render_all()
            div
                id: 'main_container'
                style: [
                    position: 'absolute'
                    top: 50
                    paddingTop: 20
                    width: '100%'
                    height: 'calc(100vh - 50px)'
                    backgroundColor: theme.colors.light
                    overflowX: 'hidden'
                    WebkitAppRegion: 'drag'
                ]
                components.message 'Global Shortcuts'
                components.text_input
                    label: "yes"
                    read: -> settings.global_shortcuts.yes
                    onSubmit: (v)->
                        settings.global_shortcuts.yes = v
                        save_settings(isDebug)
                components.text_input
                    label: "no"
                    read: -> settings.global_shortcuts.no
                    onSubmit: (v)->
                        settings.global_shortcuts.no = v
                        save_settings(isDebug)

                components.text_input
                    label: "Questions window"
                    read: -> settings.global_shortcuts.main_window
                    onSubmit: (v)->
                        settings.global_shortcuts.main_window = v
                        save_settings(isDebug)

                components.text_input
                    label: "Report window"
                    read: -> settings.global_shortcuts.report_window
                    onSubmit: (v)->
                        settings.global_shortcuts.report_window = v
                        save_settings(isDebug)

                components.text_input
                    label: "Settings window"
                    read: -> settings.global_shortcuts.settings_window
                    onSubmit: (v)->
                        settings.global_shortcuts.settings_window = v
                        save_settings(isDebug)

                components.message 'Timers'

                components.slider
                    label: 'Inactivity check'
                    min: 1/60
                    softMin: 1
                    max: 120 # min
                    step: 1
                    allowManualEdit: true
                    formatValue: (v)->
                        v + ' min'
                    read: ->
                        settings.inactivity_check_interval/60000
                    onSlideEnd: (v)->
                        settings.inactivity_check_interval = v*60000
                        save_settings(isDebug)

                components.slider
                    label: 'Show window'
                    min: 1
                    max: 120 # min
                    step: 1
                    allowManualEdit: true
                    formatValue: (v)->
                        v + ' min'
                    read: -> settings.auto_show_window_timeout/60000
                    onSlideEnd: (v)->
                        settings.auto_show_window_timeout = v*60000
                        save_settings(isDebug)

                components.message "Time to rest"
                components.slider
                    label: 'Reward ratio'
                    min: 1/8
                    max: 1 # min
                    step: 0.125
                    allowManualEdit: true
                    read: ->
                        settings.reward_ratio
                    onSlideEnd: (v)->
                        settings.reward_ratio = v
                        save_settings(settings, isDebug)

                    formatValue: (v)-> v

                components.slider
                    label: 'Reward pack'
                    min: 1
                    max: 120 # min
                    step: 1
                    allowManualEdit: true
                    formatValue: (v)->
                        v + ' min'
                    read: -> settings.reward_pack/60000
                    onSlideEnd: (v)->
                        settings.reward_pack = v*60000
                        save_settings(isDebug)

                components.message 'System'
                components.text_input
                    label: "Log file"
                    read: -> settings.log_file
                    onSubmit: (v)->
                        settings.log_file = v
                        save_settings(isDebug)

                if not isDebug then [
                    components.switch
                        key: 'open_on_startup_option'
                        label: 'Open on startup'
                        read: -> settings.open_on_startup
                        write: (currentState)->
                            settings.open_on_startup = (((currentState + 1) % 2) and true) or false
                            save_settings(isDebug)

                    ]
# Rendering main_component with ReactDOM in our HTML element `app`
app = document.getElementById 'app'
render_all= ->
    ReactDOM.render main_component(), app

render_all()
