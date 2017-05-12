{react_utils, theme, mixins, components, sounds, format_time, markdown} = require './common_ui.coffee'
{Component, React, ReactDOM} = react_utils
{div} = React.DOM
log = require './log'

log.get_load_promise().then ->

    main_component = Component
        # componentDidUpdate: ->
        # componentWillMount: ->
        # getInitialState: ->
        render: ->
            group_entries = true # TODO: group by date?

            final_entries = []
            last_active_entry = null
            last_was_active = false
            for {active, task, date},i in log.entries
                next_entry = log.entries[i+1]
                delta = (next_entry?.date or Date.now()) - date
                if active
                    if last_active_entry?
                        if task and not last_active_entry.task
                            last_active_entry.task = task
                        if last_was_active or group_entries
                            if last_active_entry.task == task
                                last_active_entry.delta += delta
                                continue
                    last_active_entry = {delta, task, date}
                    final_entries.push last_active_entry
                last_was_active = active

            div
                id: 'main_container'
                className: 'myoui'
                style: [
                    mixins.columnFlex
                    justifyContent: 'flex-start'
                    alignItems: 'flex-start'
                    top: 20
                    left: 0
                    minHeight: '100vh'
                    borderRadius: 0
                    # backgroundColor: theme.colors.light
                    position: 'absolute'
                    # overflowX: 'hidden'
                    WebkitAppRegion: 'drag'
                ]
                for {delta, task, date} in final_entries
                    div
                        className: 'entry'
                        style: [
                            padding: 10
                            color: theme.colors.dark
                            width: "100%"
                            marginLeft: 20
                        ]
                        markdown {}, "
                            __Task:__ #{task}
                            __Duration:__ #{format_time delta}
                            __Date:__ #{new Date(date).toLocaleString()}
                            "


    # Rendering main_component with ReactDOM in our HTML element `app`
    app = document.getElementById 'app'
    render_all= ->
        ReactDOM.render main_component(), app

    render_all()
