{react_utils, theme, mixins, components, sounds, format_time, markdown, moment} = require './common.coffee'
{Component, React, ReactDOM} = react_utils
{div, b} = React.DOM

electron = require 'electron'
ewin = electron.remote.getCurrentWindow()

box_style = [
    mixins.boxShadow '0 5px 10px rgba(0,0,0,0.1)'
    background: 'white'
    padding: '10px 10px 10px 0'
    margin: '0 20px 0 20px'
    borderRadius: theme.radius.r2
]

electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
app_element = document.getElementById 'app'

# Adjusting window size to include window border
inset_rect = app_element.getClientRects()[0]
size = ewin.getSize()
window_border_width = size[0] - inset_rect.width
new_width = size[0] + window_border_width
min_height = ewin.getMinimumSize()[1]
ewin.setSize new_width, size[1]
ewin.setMinimumSize new_width, min_height

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
                width: '100%'
                backgroundColor: theme.colors.light
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
                    label:"Set default settings"
                    useHighlight:true
                    onClick: ->
                        apply_default_settings()
                        save_settings(isDebug)
                        render_all()
            div
                id: 'main_container'
                style: [
                    width: '100%'
                    height: 'calc(100vh - 50px)'
                    overflowX: 'hidden'
                    WebkitAppRegion: 'drag'
                    marginTop: 50

                ]
                div
                    style:
                        maxWidth: 1000
                        margin: '0 auto'
                        paddingTop: 10

                    div
                        style:[
                            mixins.rowFlex
                            alignItems: 'flex-start'
                            justifyContent: 'center'
                            ]

                        div
                            style:[
                                width: '50%'
                            ]

                            components.message 'Timers'

                            div {style:box_style},
                                components.slider
                                    label: 'Inactivity check'
                                    min: 1
                                    softMax: 60
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
                                    label: 'Inactivity reminder'
                                    min: 1
                                    softMax: 60
                                    step: 1
                                    allowManualEdit: true
                                    formatValue: (v)->
                                        v + ' min'
                                    read: ->
                                        settings.reminder_time/60000
                                    onSlideEnd: (v)->
                                        settings.reminder_time = v*60000
                                        save_settings(isDebug)
                                components.slider
                                    label: 'Show window'
                                    min: 1
                                    softMax: 60
                                    step: 1
                                    allowManualEdit: true
                                    formatValue: (v)->
                                        v + ' min'
                                    read: -> settings.auto_show_window_timeout/60000
                                    onSlideEnd: (v)->
                                        settings.auto_show_window_timeout = v*60000
                                        save_settings(isDebug)

                            components.message "Time to rest"
                            div {style:box_style},
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


                        div
                            style:[
                                width: '50%'
                            ]

                            components.message 'Global Shortcuts'
                            div {style:box_style},
                                components.text_input
                                    label: "Answer YES"
                                    read: -> settings.global_shortcuts.yes
                                    onSubmit: (v)->
                                        settings.global_shortcuts.yes = v
                                        save_settings(isDebug)
                                components.text_input
                                    label: "Answer NO"
                                    read: -> settings.global_shortcuts.no
                                    onSubmit: (v)->
                                        settings.global_shortcuts.no = v
                                        save_settings(isDebug)
                                components.text_input
                                    label: "Show Questions"
                                    read: -> settings.global_shortcuts.main_window
                                    onSubmit: (v)->
                                        settings.global_shortcuts.main_window = v
                                        save_settings(isDebug)
                                components.text_input
                                    label: "Show Report"
                                    read: -> settings.global_shortcuts.report_window
                                    onSubmit: (v)->
                                        settings.global_shortcuts.report_window = v
                                        save_settings(isDebug)
                                components.text_input
                                    label: "Show Settings"
                                    read: -> settings.global_shortcuts.settings_window
                                    onSubmit: (v)->
                                        settings.global_shortcuts.settings_window = v
                                        save_settings(isDebug)

                    components.message 'System'

                    div
                        style: [
                            box_style
                            mixins.rowFlex
                            width: 'calc(100% - 40px)'
                        ]
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
render_all= ->
    ReactDOM.render main_component(), app_element

render_all()
