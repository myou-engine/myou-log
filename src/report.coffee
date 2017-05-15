{react_utils, theme, mixins, components, sounds, format_time, markdown} = require './common_ui.coffee'
{Component, React, ReactDOM} = react_utils
{div, form, input} = React.DOM
log = require './log'

log.get_load_promise().then ->

    main_component = Component
        # componentDidUpdate: ->
        # componentWillMount: ->
        getInitialState: ->
            date_from: 0
            date_to: Date.now()

        render: ->
            group_entries = true # TODO: group by date?

            final_entries = []
            last_was_active = false
            last_valid_task = null
            last_task = null

            date_now = Date.now()
            # Filling undefined active task and combining entries with adjacent with same task
            for {active, task, date}, i in log.entries
                new_entry = false
                # skiping pauses with duration < 5 min
                if not active and ((log.entries[i + 1]?.date or date_now) - date) < 300000
                    active = true
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
                    e.delta = date_now - e.date

            first_date = final_entries[0].date
            min_date_to = Math.max first_date, @state.date_from
            max_date_from = Math.min date_now, @state.date_to

            f_min_date_from = new Date(first_date).toJSON().split('T')[0]
            f_max_date_from = new Date(max_date_from).toJSON().split('T')[0]
            f_min_date_to = new Date(min_date_to).toJSON().split('T')[0]
            f_max_date_to = new Date(date_now).toJSON().split('T')[0]

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
                form {},
                    "from "
                    input
                        type: 'date'
                        name: 'date_value'
                        defaultValue: f_min_date_from
                        min: f_min_date_from
                        max: f_max_date_from
                        onChange: (e)=>
                            e.target.value = e.target.value or f_min_date_from
                            @setState {date_from: Date.parse(e.target.value)}
                    "to"
                    input
                        type: 'date'
                        name: 'date_value'
                        defaultValue: f_max_date_to
                        min: f_min_date_to
                        max: f_max_date_to
                        onChange: (e)=>
                            e.target.value = e.target.value or f_max_date_to
                            @setState {date_to: Date.parse(e.target.value)}

                for {active, delta, task, date} in final_entries when @state.date_to + 24*60*60*1000 >= date >= @state.date_from
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
