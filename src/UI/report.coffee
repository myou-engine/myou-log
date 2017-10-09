{react_utils, theme, mixins, components, sounds, format_time, markdown, moment} = require './common.coffee'
{React, ReactDOM} = react_utils
e = (t, args...) ->
    if not t.prototype?.render? and not t.toLocaleUpperCase?
        debugger
    React.createElement t, args...
{Log} = require '../log'

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

{report_log, get_day, final_entries, entries_by_day, days_state, days} = require '../report_log'

today = 0
update_today = ->
    today = get_day Date.now()

update_today()

class ReportComponent extends React.Component
    constructor: (props={})->
        super props
        @state =
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
        e 'div',
            className: 'myoui'
            style:{
                theme.fontStyles.p...
                color: theme.colors.t1
                textShadow: theme.shadows.textWhite
                overflow: 'hidden'
                height: '100vh'
            }
            e 'div',
                className: 'form_container'
                style: {
                    theme.fontStyles.titleLightS...
                    mixins.rowFlex...
                    boxShadow: '0 5px 10px rgba(0,0,0,0.1)'
                    width: '100vw'
                    background: 'white'
                    position: 'fixed'
                    justifyContent: 'space-around'
                    zIndex: 1000
                }
                e 'form',
                    style:{
                        mixins.rowFlex...
                        width: '100vw'
                        maxWidth: 1000
                        justifyContent: 'space-around'
                        padding: '0 40px 0 40px'
                    }

                    "Date range"
                    e 'div',
                        style:{
                            mixins.rowFlex...
                            theme.fontStyles.p...
                        }
                        "from"
                        e 'input',
                            style:{
                                mixins.border3d(0.1, '1px', true)...
                                padding: 4
                                margin: 10
                                borderRadius: theme.radius.r1
                                background: theme.colors.light
                                boxShadow: '0 0px 10px rgba(0,0,0,0.1) inset'
                            }

                            type: 'date'
                            name: 'date_value'
                            defaultValue: f_min_date_from
                            min: f_min_date_from
                            max: f_max_date_from
                            onChange: (event)=>
                                event.target.value = event.target.value or f_min_date_from
                                @setState {date_from: Date.parse(event.target.value)}
                    e 'div',
                        style:{
                            mixins.rowFlex...
                            theme.fontStyles.p...
                        }
                        "to"
                        e 'input',
                            style:{
                                mixins.border3d(0.1, '1px', true)...
                                padding: 4
                                margin: 10
                                borderRadius: theme.radius.r1
                                background: theme.colors.light
                                boxShadow: '0 0px 10px rgba(0,0,0,0.1) inset'
                            }
                            type: 'date'
                            name: 'date_value'
                            defaultValue: f_max_date_to
                            min: f_min_date_to
                            max: f_max_date_to
                            onChange: (event)=>
                                event.target.value = event.target.value or f_max_date_to
                                @setState {date_to: Date.parse(event.target.value)}

            e 'div',
                id: 'bottom_border_shadow'
                style:
                    width: '100vw'
                    height: 10
                    pointerEvents: 'none'
                    position: 'fixed'
                    bottom: 0
                    zIndex: 1000
                    background: "linear-gradient(to top, rgba(0,0,0,0.1) 0%, transparent 100%)"

            e 'div',
                id: 'main_container'
                style: {
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
                }
                for day,i in days when @state.date_to + 24*60*60*1000 >= day >= @state.date_from
                    date = moment(day)
                    fdate = date.format("dddd [#{if day == today then " (Today)" else ""}\n\n__]MMM Do[__ -] YYYY")

                    day_entries = entries_by_day[day]
                    e 'div',
                        key: 'entry_' + i
                        style:{
                            theme.fontStyles.titleLightS...
                            mixins.columnFlex...
                            fontSize: 18
                            width: '100%'
                            maxWidth: 900
                            margin: '0 auto 0 auto'
                        }
                        e 'div',
                            style:{
                                mixins.rowFlex...
                                width: '100%'
                                justifyContent: 'space-between'
                            }
                            e 'div',
                                style:
                                    width: '40%'
                                e 'div',
                                    # className: 'myoui'
                                    style:
                                        paddingLeft: 40
                                    markdown {}, fdate
                            e 'div',
                                style:{
                                    width: '20%'
                                }
                                e 'div',
                                    key: 'details_' + i
                                    style:
                                        width: 150
                                    components.switch
                                        flip: true
                                        label: 'detailed'
                                        read: do(i)->-> days_state[i].details # details state
                                        write: do(i)->(currentState)->
                                            render_all()
                                            days_state[i].details = (currentState + 1) % 2
                            e 'div',
                                style:
                                    width: '40%'
                                    textAlign: 'right'
                                    paddingRight: 20

                                e 'div', {style: {paddingRight:20}}, format_time days_state[i].activity_duration

                        e 'div',
                            style:{
                                mixins.columnFlex...
                                theme.fontStyles.p...
                                boxShadow: '0 5px 10px rgba(0,0,0,0.1)'
                                width: "calc(100% - 80px)"
                                background: 'white'
                                padding: 10
                                margin: '10px 20px 40px 20px'
                                borderRadius: theme.radius.r2
                            }
                            if days_state[i].details
                                for {task, date, duration, active, pause}, ii in day_entries when not pause?
                                    e 'div',
                                        style:
                                            width: '100%'
                                        e 'div',
                                            style:{
                                                mixins.rowFlex...
                                                opacity: if active then 1 else 0.5
                                                width: '100%'
                                                justifyContent: 'space-between'
                                                padding: '10px 20px 10px 20px'
                                            }
                                            e 'div',
                                                style:{}
                                                e 'b', {}, if active then task or 'Unknown' else "inactivity"
                                            e 'div',
                                                style:{
                                                    mixins.rowFlex...
                                                    justifyContent: 'flex-end'
                                                }
                                                e 'div',
                                                    style:{
                                                        textAlign: 'right'
                                                        overflow: 'hidden'
                                                    }
                                                    format_time duration
                                                e 'div',
                                                    style:{
                                                        textAlign: 'right'
                                                        fontSize: 12
                                                        fontWeight: 100
                                                        width: 80
                                                    }
                                                    moment(date).format('hh:mm:ss a')

                                        if ii+1 < day_entries.length
                                            e 'div',
                                                style:
                                                    borderBottom: "1px solid #{theme.colors.light}"
                                                    width: 'calc(100% - 40px)'
                                                    marginLeft: 20


                            else
                                length = Object.keys(days_state[i].collapsed_entries).length
                                ii = 0
                                for task, duration of days_state[i].collapsed_entries
                                    ii++
                                    e 'div',
                                        style:
                                            width: '100%'
                                        e 'div',
                                            style:{
                                                mixins.rowFlex...
                                                # borderBottom: "1px solid #{theme.colors.light}"
                                                width: '100%'
                                                justifyContent: 'space-between'
                                                padding: '10px 20px 10px 20px'
                                            }
                                            e 'div',
                                                style:{}
                                                e 'b', {}, task or 'Unknown'

                                            e 'div',
                                                style:
                                                    textAlign: 'right'
                                                    overflow: 'hidden'
                                                format_time duration

                                        if ii < length
                                            e 'div',
                                                style:
                                                    borderBottom: "1px solid #{theme.colors.light}"
                                                    width: 'calc(100% - 40px)'
                                                    marginLeft: 20

            # components.button
            #     useHighlight: true
            #     onClick: ->
            #         print()
            #     label: 'Print report'

render_all= ->
    update_today()
    ReactDOM.render e(ReportComponent), app_element

own_log = require('../log').log

report_log own_log

render_all()

window.load_other_log = (path)->
    l = new Log
    l.load path
    report_log l
    return l

addEventListener 'keydown', (event)->
    if event.keyCode == 123
        ewin.webContents.openDevTools({mode:'detach'})
    if (event.ctrlKey and event.keyCode == 82) or event.keyCode == 116 # ctrl + r or F5
        event.preventDefault()
        report_log(own_log)
