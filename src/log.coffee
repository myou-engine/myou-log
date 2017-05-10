fs = require 'fs'

class Log
    constructor: (entries=[])->
        @entries = []
        @last_entry = null
        @is_active = false
        @last_activity_change_date = 0
        @add_multiple_entries entries, false

    clear: ->
        @entries = []
        @save()

    save: ->
        fs.writeFile 'log', JSON.stringify(@entries), (err)->
            if err then console.log err
            console.log 'The file was saved!'

    add_multiple_entries: (entries=[], save=true)->
        for e in entries
            @new_entry e, false
        if save then @save()
        return

    new_entry: (entry, save=true)->
        if entry.active != @is_active
            @is_active = entry.active
            @last_activity_change_date = entry.date
            new_entry = true

        if entry.task? and entry.task != @last_task
            @last_task = entry.task
            new_entry = true

        if entry.active and @last_entry? and entry.task != @last_entry.task
            new_entry = true

        if new_entry
            console.log entry
            @last_entry = entry
            @entries.push entry
            if save
                @save()

log = new Log

# This promise is resolved only after read the log file.
log.load_promise = new Promise (resolve, reject) ->
    fs.readFile 'log', 'utf8', (err, data)->
        old_log = []
        if err
            console.log err
            # Reading from localStorage if log file doesn't exist.
            console.log 'Reading deprecated log from localStorage. \nIt will be cleared after this operation.'
            old_log = (localStorage.myoulog? and JSON.parse(localStorage.myoulog)) or []
            localStorage.removeItem 'myoulog'
            # It will also save the log file.
            log.add_multiple_entries old_log
        else
            console.log 'Reading log from file.'
            old_log = JSON.parse data
            # loading without save because, the log will not have any changes.
            log.add_multiple_entries old_log, false

        # using saved date from localStorage.myoulog_last_date
        # to create a new inactivity entry
        if localStorage.myoulog_last_date?
            last_date = parseInt localStorage.myoulog_last_date
            log.new_entry {active:false, date:last_date}

        # Saving date on localStorage.myoulog_last_date
        save_last_date = ->
            localStorage.myoulog_last_date = Date.now()
            setInterval save_last_date, 1

        resolve()

#debug log
window.$log = log

module.exports = log
