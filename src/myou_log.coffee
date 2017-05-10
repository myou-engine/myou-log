class MyouLog
    constructor: (entries=[])->
        @entries = []
        @last_entry = null
        @is_active = false
        @last_activity_change_date = 0
        for e in entries
            @add_log_entry e

    clear_log: ->
        @entries.clear()

    add_log_entry: (entry)->
        if entry.active != @active
            @is_active = entry.active
            @last_activity_change_date = entry.date
            new_entry = true

        if entry.task? and entry.task != @last_task
            @last_task = entry.task
            new_entry = true

        if entry.active and @last_entry? and entry.task != @last_entry.task
            new_entry = true

        if new_entry
            @last_entry = entry
            @entries.push entry

module.exports = MyouLog
