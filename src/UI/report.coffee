{react_utils, theme, mixins, components, sounds, format_time, markdown, moment} = require './common.coffee'
{Component, React, ReactDOM} = react_utils
{div, form, input, b} = React.DOM
{Log, log} = require '../log'

electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
app_element = document.getElementById 'app'

# Adjusting window size to include window border
inset_rect = app_element.getClientRects()[0]
size = ewin.getSize()
window_border_width = size[0] - inset_rect.width
new_width = parseInt size[0] + window_border_width
min_height = ewin.getMinimumSize()[1]
ewin.setSize new_width, size[1]
ewin.setMinimumSize new_width, min_height

last_date = null

final_entries = []
entries_by_day = {}
days_state = []
days = []

get_day = (date)-> Math.floor(date/1000/60/60/24)*1000*60*60*24

today = 0
update_today = ->
    today = get_day Date.now()

update_today()

main_component = Component
    # componentDidUpdate: ->
    # componentWillMount: ->
    getInitialState: ->
        date_from: 0
        date_to: Date.now()

    render: ->
        date_now = Date.now()

        group_entries = true # TODO: group by date?

        first_date = final_entries[final_entries.length-1]?.date or 0
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
                        maxWidth: 1000
                        justifyContent: 'space-around'
                        padding: '0 40px 0 40px'
                    ]

                    "Date range"
                    div
                        style:[
                            mixins.rowFlex
                            theme.fontStyles.p
                        ]
                        "from"
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
                    fdate = date.format("dddd [#{if day == today then " (Today)" else ""}\n\n__]MMM Do[__ -] YYYY")

                    day_entries = entries_by_day[day]
                    div
                        key: 'entry_' + i
                        style:[
                            theme.fontStyles.titleLightS
                            fontSize: 18
                            width: '100%'
                            maxWidth: 900
                            margin: '0 auto 0 auto'
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
                                    width: '20%'
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
                                    width: '40%'
                                    textAlign: 'right'
                                    paddingRight: 20
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

                            ]
                            if days_state[i].details
                                for {task, date, duration, active, pause}, ii in day_entries when not pause?
                                    div
                                        style:
                                            width: '100%'
                                        div
                                            style:[
                                                mixins.rowFlex
                                                opacity: if active then 1 else 0.5
                                                width: '100%'
                                                justifyContent: 'space-between'
                                                padding: '10px 20px 10px 20px'
                                            ]
                                            div
                                                style:[
                                                ]
                                                b {}, if active then task or 'Unknown' else "inactivity"
                                            div
                                                style:[
                                                    mixins.rowFlex
                                                    justifyContent: 'flex-end'
                                                ]
                                                div
                                                    style:[
                                                        textAlign: 'right'
                                                        overflow: 'hidden'
                                                    ]
                                                    div
                                                        format_time duration
                                                div
                                                    style:[
                                                        textAlign: 'right'
                                                        fontSize: 12
                                                        fontWeight: 100
                                                        width: 80
                                                    ]
                                                    div
                                                        style: []
                                                        moment(date).format('hh:mm:ss a')

                                        if ii+1 < day_entries.length
                                            div
                                                style:
                                                    borderBottom: "1px solid #{theme.colors.light}"
                                                    width: 'calc(100% - 40px)'
                                                    marginLeft: 20


                            else
                                length = Object.keys(days_state[i].collapsed_entries).length
                                ii = 0
                                for task, duration of days_state[i].collapsed_entries
                                    ii++
                                    div
                                        style:
                                            width: '100%'
                                        div
                                            style:[
                                                mixins.rowFlex
                                                # borderBottom: "1px solid #{theme.colors.light}"
                                                width: '100%'
                                                justifyContent: 'space-between'
                                                padding: '10px 20px 10px 20px'
                                            ]
                                            div
                                                style:[
                                                ]
                                                b {}, task or 'Unknown'

                                            div
                                                style:[
                                                    textAlign: 'right'
                                                    overflow: 'hidden'
                                                ]
                                                div
                                                    format_time duration

                                        if ii < length
                                            div
                                                style:
                                                    borderBottom: "1px solid #{theme.colors.light}"
                                                    width: 'calc(100% - 40px)'
                                                    marginLeft: 20

            # components.button
            #     useHighlight: true
            #     onClick: ->
            #         print()
            #     label: 'Print report'

# Rendering main_component with ReactDOM in our HTML element `app`
render_all= ->
    update_today()
    ReactDOM.render main_component(), app_element

load_log = ->
    final_entries = []
    entries_by_day = {}
    days_state = []
    days = []

    last_was_active = false
    last_task = null
    entries = log.get_clean_entries()
    log.add_duration(entries)

    # invert entries
    final_entries = for i in [0...entries.length]
        entries.pop()

    for e in final_entries
        day = get_day e.date
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
        day_state = days_state[days.length-1]
        if e.active
            task = e.task or 'Unknown'
            day_state.activity_duration += e.duration
            if day_state.collapsed_entries[task]?
                day_state.collapsed_entries[task] += e.duration
            else
                day_state.collapsed_entries[task] = e.duration

        else
            day_state.inactivity_duration += e.duration

    render_all()

load_log()

addEventListener 'keydown', (event)->
    if event.keyCode == 123
        ewin.webContents.openDevTools({mode:'detach'})
    if (event.ctrlKey and event.keyCode == 82) or event.keyCode == 116 # ctrl + r or F5
        event.preventDefault()
        load_log()
