fs = require 'fs'
electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
{log_file, reward_ratio, reward_pack, inactivity_check_interval} = ewin.settings
class Log
    constructor: (entries=[])->
        @entries = []
        @last_entry = null
        @is_active = false
        @last_activity_change = null
        @is_paused = false
        @add_multiple_entries entries, false

    clear: ->
        @entries = []
        @save()

    save: ->
        str_entries = JSON.stringify(@entries, null, if ewin.isDebug then 4 else null)
        #saving backup
        localStorage.myoulog_backup = str_entries
        console.log 'Saving log file...'
        fs.writeFile log_file, str_entries, (err)->
            if err
                console.log err
            else
                console.log 'Log file saved here: ', log_file

    get_reward: (date_range=[0,Date.now()])->
        reward = 0
        last_active = 0
        for {active, date, pause}, i in @entries
            if date_range[1] > date > date_range[0]
                if not pause?
                    last_active = active
                duration = @_get_segment_duration(i,false)
                add = true
                if pause?
                    if pause
                        add = false
                    else
                        add = last_active
                else
                    add = active

                if add
                    reward += duration
                else
                    reward -= 1/reward_ratio * duration
                    reward = Math.max 0, reward


        return Math.floor((reward * reward_ratio) / reward_pack)*reward_pack

    _get_segment_duration: (index, exclude_pauses=true)->
        entry = @entries[index]
        next_entry = @entries[index + 1]
        if next_entry?
            if exclude_pauses and entry.pause
                duration = 0
            else
                duration = next_entry.date - entry.date
        else
            duration = Date.now() - entry.date
        return duration

    get_duration: (index)->
        duration = 0
        first = log.entries[index]
        if not first then return 0
        for i in [index...log.entries.length]
            e = log.entries[i]
            if not e.pause? and ((e.task != first.task) or (e.active != first.active)) then break
            duration += @_get_segment_duration i

        return duration

    get_activity_duration: (index)->
        duration = 0
        first = log.entries[index]
        if not first then return 0
        for i in [index...log.entries.length]
            e = log.entries[i]
            if not e.pause? and e.active != first.active then break
            duration += @_get_segment_duration i

        return duration

    add_multiple_entries: (entries=[], save=true)->
        for e in entries
            @new_entry e, false
        if save then @save()
        return

    new_entry: (entry, save=true)->
        {active, task, date, pause} = entry
        if pause?
            console.log "%c#{if pause then 'PAUSE' else 'PLAY'}
                #{new Date(date).toLocaleString()}",
                "color:#{if pause then 'red' else 'green'}"
            entry.index = @entries.length
            @is_paused = pause
            @entries.push entry
            if save
                @save()
            return

        activity_changed = active != @is_active
        task_changed = task != @last_task
        if activity_changed or task_changed
            entry.index = @entries.length
            if activity_changed
                @last_activity_change = entry
            if task_changed
                @last_task = task
            @is_active = active
            @is_paused = false
            console.log "%c#{if active then 'working on' else 'distracted'}
                 #{if task then task else if active then 'UNKNOWN' else ''}
                 #{new Date(date).toLocaleString()}",
                 "color:#{if active then 'blue' else 'gray'}"
            @entries.push entry
            @last_entry = entry
            if save
                @save()
            return

log = new Log

# This promise is resolved only after read the log file.
log.get_load_promise = ->
    new Promise (resolve, reject) ->
        if fs.existsSync 'log'
            fs.rename 'log', log_file
            console.log 'Old log file found. moved to ' + log_file

        if log_file != 'log.json' and not fs.existsSync(log_file) and fs.existsSync 'log.json'
            fs.rename 'log.json', log_file
            console.log 'Moving log.json to ' + log_file

        fs.readFile log_file, 'utf8', (err, data)->
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
        if (Date.now() - last_date) > inactivity_check_interval
            log.new_entry {active:false, date:last_date}

    # Saving date on localStorage.myoulog_last_date
    save_last_date = ->
        localStorage.myoulog_last_date = Date.now()
    setInterval save_last_date, 1000


#debug log
window.$log = log

module.exports = log
