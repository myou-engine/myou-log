electron = require 'electron'
ewin = electron.remote.getCurrentWindow()
settings = ewin.settings

tzoffset = (new Date()).getTimezoneOffset()*60*1000
get_day = (date)-> Math.floor((date-tzoffset)/1000/60/60/24)*1000*60*60*24 + tzoffset

get_todays_activity_duration = (log)->
    {entries_by_day, today} = report_log log
    total = 0
    entries = entries_by_day[today] or []
    for entry in entries when entry.active
        total += entry.duration or 0
    return total

report_log = (log)->
    final_entries = []
    entries_by_day = {}
    days_state = []
    days = []
    today = 0

    last_was_active = false
    last_task = null
    entries = log.get_clean_entries()
    log.add_duration(entries)

    # add day boundaries
    {day_boundary_inactivity} = settings
    day = 0
    previous = 0
    final_entries = []
    for entry in entries
        real_day = get_day entry.date
        if day==0 or entry.date - Math.max(previous, real_day) > day_boundary_inactivity
            day = real_day
        previous = entry.date
        entry.day = day
        final_entries.push entry
    # calculate today with same boundary logic
    now = Date.now()
    real_day = get_day now
    if now - Math.max(previous, real_day) > day_boundary_inactivity
        today = real_day
    else
        today = day

    final_entries.reverse()

    for k,entry of entries_by_day
        entry.splice 0, entry.length

    for entry,i in final_entries
        entry.details = 0
        day = entry.day
        if day not in days
            days.push day
            days_state.push
                details:0
                collapsed_entries:{}
                activity_duration: 0
                inactivity_duration: 0
        if entries_by_day[day]?
            entries_by_day[day].push entry
        else
            entries_by_day[day] = [entry]
        day_state = days_state[days.length-1]
        if entry.active
            task = entry.task or 'Unknown'
            day_state.activity_duration += entry.duration
            if day_state.collapsed_entries[task]?
                day_state.collapsed_entries[task] += entry.duration
            else
                day_state.collapsed_entries[task] = entry.duration

        else
            day_state.inactivity_duration += entry.duration

    return {final_entries, entries_by_day, days_state, days, today}

module.exports = {get_todays_activity_duration, report_log}
