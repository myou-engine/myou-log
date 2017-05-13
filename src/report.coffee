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
            last_was_active = false
            last_valid_task = null
            last_task = null

            # Filling undefined active task and combining entries with adjacent with same task
            for {active, task, date}, i in log.entries
                new_entry = false
                if active
                    task = log.get_next_task i
                if active != last_was_active or last_task != task
                    new_entry = true
                    last_was_active = active
                    if active
                        last_task = task
                    final_entries.push {active, task, date}

            # Calculating duration
            for e,i in final_entries
                next_entry = final_entries[i+1]
                if next_entry?
                    e.delta = next_entry.date - e.date
                else
                    e.delta = Date.now() - e.date

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
                for {active, delta, task, date} in final_entries
                    div
                        className: 'entry'
                        style: [
                            padding: 10
                            color: if active then theme.colors.dark else "#bababa"
                            width: "100%"
                            marginLeft: 20
                        ]
                        markdown {}, "
                            #{if active then "__Task__ #{if task then task else ''}" else '__Inactivity__ '}
                            __Duration__ #{format_time delta}
                            __Date__ #{new Date(date).toLocaleString()}"


    # Rendering main_component with ReactDOM in our HTML element `app`
    app = document.getElementById 'app'
    render_all= ->
        ReactDOM.render main_component(), app

    render_all()
