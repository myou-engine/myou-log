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
            for i,e of log.entries when e.active
                i = parseInt i
                if not e.task
                    next_i = log.get_next_task_index(i)
                    if next_i then e.task = log.entries[next_i].task


            final_entries = []
            last_task = undefined
            for i,e of log.entries
                if not final_entries.length
                    final_entries.push e
                    continue

                i = parseInt i
                if e.task == final_entries[final_entries.length-1].task
                    continue
                final_entries.push e


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

                for i,e of final_entries
                    i = parseInt i
                    next_entry = final_entries[i + 1]
                    if next_entry? then duration = next_entry.date - e.date
                    else duration = Date.now() - e.date
                    div
                        className: 'entry'
                        style: [
                            padding: 10
                            color: theme.colors.dark
                            width: "100%"
                            marginLeft: 20
                        ]
                        markdown {}, "
                            __Task:__ #{e.task}
                            __Duration:__ #{format_time duration}
                            __Date:__ #{new Date(e.date).toLocaleString()}
                            "


    # Rendering main_component with ReactDOM in our HTML element `app`
    app = document.getElementById 'app'
    render_all= ->
        ReactDOM.render main_component(), app

    render_all()
