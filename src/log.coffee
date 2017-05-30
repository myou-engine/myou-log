fs = require 'fs'
electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
settings = ewin.settings

class Log
    constructor: (entries=[])->
        @entries = []
        @last_entry = null
        @is_active = false
        @last_activity_change = 0
        @is_paused = false
        @add_multiple_entries entries, false

    clear: ->
        @entries = []
        @save()

    # This promise is resolved only after read the log file.
    load: (log_file=settings.log_file)->
        if log_file != 'log.json' and not fs.existsSync(log_file) and fs.existsSync 'log.json'
            fs.rename 'log.json', log_file
            console.log 'Moving log.json to ' + log_file

        file_exists = fs.existsSync(log_file)
        if file_exists
            console.log 'log file found here: ' + log_file
        else
            console.log 'file not found: ' + log_file

        old_log = []
        try
            data = fs.readFileSync(log_file, 'utf8').toString()
            console.log 'Reading log from file.'
            old_log = JSON.parse data or '[]'
            # loading without save because, the log will not have any changes.
            @add_multiple_entries old_log, false
        catch err
            if not file_exists
                console.log err
                # Reading from localStorage if log file doesn't exist.
                console.warn 'Reading deprecated log from localStorage. \nIt will be cleared after this operation.'
                old_log = (localStorage.myoulog? and JSON.parse(localStorage.myoulog)) or []
                # moved to myoulog_backup to save it in case of loose your log
                localStorage.myoulog_backup = localStorage.myoulog
                localStorage.removeItem 'myoulog'
                # It will also save the log file.
                @add_multiple_entries old_log, false
                @save log_file

    save: (log_file=settings.log_file)->
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
                    reward -= 1/settings.reward_ratio * duration
                    reward = Math.max 0, reward


        return Math.floor((reward * settings.reward_ratio) / settings.reward_pack)*settings.reward_pack

    _get_segment_duration: (index, exclude_pauses=true, entries=@entries)->
        entry = entries[index]
        next_entry = entries[index + 1]
        if next_entry?
            if exclude_pauses and entry.pause
                duration = 0
            else
                duration = next_entry.date - entry.date
        else
            duration = Date.now() - entry.date
        return duration

    get_duration: (index, entries=@entries)->
        duration = 0
        first = log.entries[index]
        if not first then return 0
        for i in [index...entries.length]
            e = log.entries[i]
            if not e.pause? and ((e.task != first.task) or (e.active != first.active)) then break
            duration += @_get_segment_duration i, false, entries

        return duration

    get_activity_duration: (index, entries=@entries)->
        duration = 0
        first = entries[index]
        if not first then return 0
        for i in [index...entries.length]
            e = log.entries[i]
            if not e.pause? and e.active != first.active then break
            duration += @_get_segment_duration i, false, entries

        return duration

    add_multiple_entries: (entries=[], save=true)->
        for e in entries
            @new_entry e, false
        if save then @save()
        return

    get_clean_entries: (entries=@entries)->
        # Filling undefined active task and combining entries with adjacent with same task
        output = []
        last_date = 0
        for {active, task, date, pause}, i in entries
            if entries[i+1]? and date >= entries[i+1].date
                continue

            if pause?
                output.push {pause, date}
                continue

            # getting task
            if active
                for ii in [i...entries.length]
                    e = entries[ii]
                    if e?.task
                        task = e.task
                        break

            activity_changed = active != last_was_active
            task_changed = task != last_task
            if activity_changed or task_changed
                if task_changed
                    last_task = task
                last_was_active = active
                last_date = date
                output.push {active, task, date}

        return output

    add_duration: (entries=@entries)->
        for e,i in entries
            if not e.pause?
                e.duration = @get_duration i, entries

    new_entry: (entry, save=true)->
        {active, task, date, pause} = entry
        if @last_entry and entry.date < @last_entry.date
            # Avoid negative entries
            # TODO: try to reproduce bug that causes this
            entry.date = date = Math.max date, @last_entry.date

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
        task_changed = task != @last_entry?.task
        if activity_changed or task_changed
            entry.index = @entries.length
            if activity_changed
                @last_activity_change = entry
            if entry.active and task_changed
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
log.load()

interruption_check = ->
    # using saved date from localStorage.myoulog_last_date
    # to create a new inactivity entry
    if localStorage.myoulog_last_date?
        last_date = parseInt localStorage.myoulog_last_date
        if (Date.now() - last_date) > settings.inactivity_check_interval
            log.new_entry {active:false, date:last_date, auto: true}

log.enable_last_date_checker = ->
    interruption_check()
    # Saving date on localStorage.myoulog_last_date
    save_last_date = ->
        interruption_check()
        localStorage.myoulog_last_date = Date.now()
    setInterval save_last_date, 1000


module.exports = {log, Log}
