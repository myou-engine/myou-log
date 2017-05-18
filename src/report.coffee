{react_utils, theme, mixins, components, sounds, format_time, markdown} = require './common_ui.coffee'
{Component, React, ReactDOM} = react_utils
{div, form, input} = React.DOM
log = require './log'

MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
WEEK_DAYS = ['sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
last_date = null

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
            last_task = null
            date_now = Date.now()

            # Filling undefined active task and combining entries with adjacent with same task
            for {active, task, date, pause}, i in log.entries
                if pause?
                    final_entries.push {pause, date}
                    continue

                # getting task
                if active
                    for ii in [i...log.entries.length]
                        e =log.entries[ii]
                        if e?.task
                            task = e.task
                            break

                activity_changed = active != last_was_active
                task_changed = task != last_task
                if activity_changed or task_changed
                    if task_changed
                        last_task = task
                    last_was_active = active
                    final_entries.push {active, task, date}

            # Calculating duration
            for e,i in final_entries
                if not e.pause?
                    e.duration = log.get_duration i, final_entries
                    console.log (if e.active then 1 else 0), e.task, e.duration , e.pause
            first_date = final_entries[0]?.date or 0
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
                form
                    style:
                        margin: 20
                    "Date range from "
                    input
                        style:
                            marginLeft: 10
                            marginRight: 10
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
                        style:
                            marginLeft: 10
                            marginRight: 10
                        type: 'date'
                        name: 'date_value'
                        defaultValue: f_max_date_to
                        min: f_min_date_to
                        max: f_max_date_to
                        onChange: (e)=>
                            e.target.value = e.target.value or f_max_date_to
                            @setState {date_to: Date.parse(e.target.value)}

                for {active, duration, task, date, pause} in final_entries when not pause? and @state.date_to + 24*60*60*1000 >= date >= @state.date_from
                    date = new Date(date)

                    day = date.getDate()
                    month = MONTHS[date.getMonth()]
                    week_day = WEEK_DAYS[date.getDay()]
                    year = date.getFullYear()

                    f_date = "#{week_day}, __#{day} #{month}__ - #{year}"
                    [if last_date != f_date
                        last_date = f_date
                        div {style:{margin:'40px 0 10px 20px'}}, markdown({}, f_date)
                    div
                        className: 'entry'
                        style: [
                            padding: 10
                            color: if active then theme.colors.dark else "#bababa"
                            width: "100%"
                            marginLeft: 20
                        ]
                        markdown {}, "
                            #{if active then "__#{task or 'Activity'}__&nbsp;&nbsp;-&nbsp;" else "__Inactivity__&nbsp;&nbsp;-&nbsp;"}
                            #{format_time duration}
                            _(#{date.toLocaleTimeString()})_"]

                # components.button
                #     useHighlight: true
                #     onClick: ->
                #         print()
                #     label: 'Print report'

    # Rendering main_component with ReactDOM in our HTML element `app`
    app = document.getElementById 'app'
    render_all= ->
        ReactDOM.render main_component(), app

    render_all()
