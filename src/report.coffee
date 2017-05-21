{react_utils, theme, mixins, components, sounds, format_time, markdown, moment} = require './common_ui.coffee'
{Component, React, ReactDOM} = react_utils
{div, form, input} = React.DOM
log = require './log'

last_date = null

final_entries = []
last_was_active = false
last_task = null
entries_by_day = {}
window.days_state = []
window.days = []
log.get_load_promise().then ->
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

    for e in final_entries
        day = Math.floor(e.date/1000/60/60/24)*1000*60*60*24
        e.details = 0
        if day not in days
            days.push day
            days_state.push
                details:0
                collapsed_entries:{}
                activity_duration: 0
                inactivity_duration: 0
        if entries_by_day[day]?
            entries_by_day[day].push e
        else
            entries_by_day[day] = [e]
        if e.active
            task = e.task or 'Unknown'
            day_state = days_state[days.length-1]
            day_state.activity_duration += e.duration
            console.log task
            if day_state.collapsed_entries[task]?
                day_state.collapsed_entries[task] += e.duration
            else
                day_state.collapsed_entries[task] = e.duration
        else
            day_state.inactivity_duration += e.duration

    render_all()



main_component = Component
    # componentDidUpdate: ->
    # componentWillMount: ->
    getInitialState: ->
        date_from: 0
        date_to: Date.now()

    render: ->
        date_now = Date.now()

        group_entries = true # TODO: group by date?

        first_date = final_entries[0]?.date or 0
        min_date_to = Math.max first_date, @state.date_from
        max_date_from = Math.min date_now, @state.date_to

        f_min_date_from = new Date(first_date).toJSON().split('T')[0]
        f_max_date_from = new Date(max_date_from).toJSON().split('T')[0]
        f_min_date_to = new Date(min_date_to).toJSON().split('T')[0]
        f_max_date_to = new Date(date_now).toJSON().split('T')[0]
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
                className: 'form_container'
                style: [
                    theme.fontStyles.titleLightS
                    mixins.rowFlex
                    mixins.boxShadow '0 5px 10px rgba(0,0,0,0.1)'
                    width: '100vw'
                    background: 'white'
                    position: 'fixed'
                    justifyContent: 'space-around'
                    zIndex: 1000
                ]
                form
                    style:[
                        mixins.rowFlex
                        width: '100vw'
                        maxWidth: 600
                        justifyContent: 'space-around'
                    ]

                    "Date range"
                    div
                        style:[
                            mixins.rowFlex
                            theme.fontStyles.p
                        ]
                        "from "
                        input
                            style:[
                                padding: 4
                                margin: 10
                                borderRadius: theme.radius.r1
                                background: theme.colors.light
                                mixins.border3d 0.1, '1px', true
                                mixins.boxShadow '0 0px 10px rgba(0,0,0,0.1) inset'

                            ]

                            type: 'date'
                            name: 'date_value'
                            defaultValue: f_min_date_from
                            min: f_min_date_from
                            max: f_max_date_from
                            onChange: (e)=>
                                e.target.value = e.target.value or f_min_date_from
                                @setState {date_from: Date.parse(e.target.value)}
                    div
                        style:[
                            mixins.rowFlex
                            theme.fontStyles.p
                        ]
                        "to"
                        input
                            style:[
                                padding: 4
                                margin: 10
                                borderRadius: theme.radius.r1
                                background: theme.colors.light
                                mixins.border3d 0.1, '1px', true
                                mixins.boxShadow '0 0px 10px rgba(0,0,0,0.1) inset'

                            ]
                            type: 'date'
                            name: 'date_value'
                            defaultValue: f_max_date_to
                            min: f_min_date_to
                            max: f_max_date_to
                            onChange: (e)=>
                                e.target.value = e.target.value or f_max_date_to
                                @setState {date_to: Date.parse(e.target.value)}

            div
                id: 'bottom_border_shadow'
                style:
                    width: '100vw'
                    height: 10
                    pointerEvents: 'none'
                    position: 'fixed'
                    bottom: 0
                    zIndex: 1000
                    background: "linear-gradient(to top, rgba(0,0,0,0.1) 0%, transparent 100%)"

            div
                id: 'main_container'
                style: [
                    # mixins.columnFlex
                    justifyContent: 'flex-start'
                    alignItems: 'flex-start'
                    left: 0
                    top: 50
                    paddingTop: 20
                    width: '100%'
                    height: 'calc(100vh - 50px)'
                    borderRadius: 0
                    backgroundColor: theme.colors.light
                    position: 'absolute'
                    overflowX: 'hidden'
                    WebkitAppRegion: 'drag'
                ]
                for day,i in days when @state.date_to + 24*60*60*1000 >= day >= @state.date_from
                    date = moment(day)
                    fdate = date.format("dddd [\n\n__]MMM Do[__ -] YYYY")

                    day_entries = entries_by_day[day]
                    console.log days_state[i].activity_duration
                    div
                        key: 'entry_' + i
                        style:[
                            theme.fontStyles.titleLightS
                            fontSize: 18
                            width: '100%'
                            mixins.columnFlex
                        ]
                        div
                            style:[
                                width: '100%'
                                mixins.rowFlex
                                justifyContent: 'space-between'
                            ]
                            div
                                style:[
                                    width: '40%'
                                ]
                                div
                                    # className: 'myoui'
                                    style: [
                                        paddingLeft:40

                                    ]
                                    markdown {}, fdate
                            div
                                style:[
                                    width: '40%'
                                ]
                                div
                                    key: 'details_' + i
                                    style:[
                                        width: 150
                                    ]
                                    components.switch
                                        flip: true
                                        label: 'detailed'
                                        read: do(i)->-> days_state[i].details # details state
                                        write: do(i)->(currentState)->
                                            render_all()
                                            days_state[i].details = (currentState + 1) % 2
                            div
                                style:[
                                    width: '20%'
                                    textAlign: 'center'
                                ]
                                div {style: {paddingRight:20}}, format_time days_state[i].activity_duration

                        div
                            style:[
                                mixins.columnFlex
                                mixins.boxShadow '0 5px 10px rgba(0,0,0,0.1)'
                                theme.fontStyles.p
                                width: "calc(100% - 80px)"
                                background: 'white'
                                padding: 10
                                margin: '10px 20px 40px 20px'
                                borderRadius: theme.radius.r2
                                mixins.transition '1s', 'height'

                            ]
                            if days_state[i].details
                                for {task, date, duration, active, pause} in day_entries when not pause?
                                    markdown {}, "
                                        #{if active then "__#{task or 'Unknown'}__
                                        &nbsp;&nbsp;-&nbsp;" else "__Inactivity__
                                        &nbsp;&nbsp;-&nbsp;"} #{format_time duration}
                                        _(#{moment(date).format('h:mm:ss a')})_"

                            else
                                for task, duration of days_state[i].collapsed_entries
                                    markdown {}, "
                                        __#{task or 'Activity'}__&nbsp;&nbsp;-&nbsp; #{format_time duration}"

            # components.button
            #     useHighlight: true
            #     onClick: ->
            #         print()
            #     label: 'Print report'

# Rendering main_component with ReactDOM in our HTML element `app`
app = document.getElementById 'app'
render_all= ->
    ReactDOM.render main_component(), app
