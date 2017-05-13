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
        str_entries = JSON.stringify(@entries)
        #saving backup
        localStorage.myoulog_backup = str_entries
        fs.writeFile 'log', str_entries, (err)->
            if err then console.log err
            console.log 'The file was saved!'

    add_multiple_entries: (entries=[], save=true)->
        for e in entries
            @new_entry e, false
        if save then @save()
        return

    get_duration: (index)->
        entry = @entries[index]
        next_entry = @entries[index + 1]
        if next_entry?
            return next_entry.date - entry.date
        else
            return Date.now() - entry.date

    get_next_task: (index)->
        for i in [index..@entries.length]
            e = @entries[i]
            if e?.task then return e.task

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
            console.log "%c#{if entry.active then 'working on' else 'distracted'}
                #{if entry.task then entry.task else if entry.active then 'UNKNOWN' else ''}
                #{new Date(entry.date).toLocaleString()}",
                "color:#{if entry.active then 'blue' else 'gray'}"
            @last_entry = entry
            @entries.push entry
            if save
                @save()

log = new Log

# This promise is resolved only after read the log file.
log.get_load_promise = ->
    new Promise (resolve, reject) ->
        fs.readFile 'log', 'utf8', (err, data)->
            old_log = []
            if err
                console.log err
                # Reading from localStorage if log file doesn't exist.
                console.warn 'Reading deprecated log from localStorage. \nIt will be cleared after this operation.'
                old_log = (localStorage.myoulog? and JSON.parse(localStorage.myoulog)) or []
                # moved to myoulog_backup to save it in case of loose your log
                localStorage.myoulog_backup = localStorage.myoulog
                localStorage.removeItem 'myoulog'
                # It will also save the log file.
                log.add_multiple_entries old_log
            else
                console.log 'Reading log from file.'
                old_log = JSON.parse data or '[]'
                # loading without save because, the log will not have any changes.
                log.add_multiple_entries old_log, false

            resolve()

log.enable_last_date_checker = ->
    # using saved date from localStorage.myoulog_last_date
    # to create a new inactivity entry
    if localStorage.myoulog_last_date?
        last_date = parseInt localStorage.myoulog_last_date
        log.new_entry {active:false, date:last_date}

    # Saving date on localStorage.myoulog_last_date
    save_last_date = ->
        localStorage.myoulog_last_date = Date.now()
    setInterval save_last_date, 1000


#debug log
window.$log = log

module.exports = log
