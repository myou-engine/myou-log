{React, ReactDOM} = require('./common.coffee').react_utils
e = React.createElement

moment = require 'moment'

format_time = (time=Date.now())->
    sec = Math.floor (time / 1000) % 60
    min = Math.floor (time / (1000*60)) % 60
    hours = Math.floor (time / (1000*60*60)) % 24
    days = Math.floor time / (1000*60*60*24)

    formated_time = ''
    if days or hours or min or sec
        if not(hours or days)
            formated_time = "#{sec} sec"
        if days or hours or min
            if not (days)
                formated_time = "#{min} min " + formated_time
            if days or hours
                formated_time = "#{hours} hour#{if hours > 1 then 's' else ''} " + formated_time
                if days
                    formated_time = "#{days} day#{if days > 1 then 's' else ''} " + formated_time
    return formated_time or '0 sec'

class Time extends React.Component
    constructor: (props={})->
        super props
        @state =
            time: props.time
            start_time: Date.now()
            formated_time: format_time props.time

    componentWillMount: ->
        @interval = setInterval =>
            elapsed_time =  Date.now() - @state.start_time
            time = @state.time + elapsed_time
            formated_time = format_time time
            if @state.formated_time != formated_time
                @setState {formated_time}
        , 1000
    componentWillUnmount: ->
        clearInterval @interval
    render: ->
        e 'div',
            style:
                WebkitAppRegion: (@props.no_drag and 'no-drag') or ''
            @props.text.replace('#time', @state.formated_time)

module.exports = {moment, format_time, Time}
