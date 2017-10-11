# checking OS
is_linux = process.platform == 'linux'
is_win = process.platform == 'win32'
is_mac = process.platform == 'darwin'

# Electron
electron = require 'electron'
{Tray, Menu, globalShortcut} = electron.remote
ewin = electron.remote.getCurrentWindow()
window.$window = ewin
ewin.setAlwaysOnTop true
ewin.setVisibleOnAllWorkspaces true

app_element = document.getElementById 'app'

# Adjusting window size to include window border
inset_rect = app_element.getClientRects()[0]
size = ewin.getSize()
window_border_width = size[0] - inset_rect.width
new_width = size[0] + window_border_width
min_height = ewin.getMinimumSize()[1]
ewin.setSize new_width, size[1]
ewin.setMinimumSize new_width, min_height

ewin.on 'close', ()->
    report_window?.close()
    settings_window?.close()

win_position = localStorage.myoulog_win_position
if win_position
    win_position = JSON.parse win_position
    ewin.setPosition win_position[0], win_position[1]

addEventListener 'keydown', (event)->
    if event.keyCode == 123 # F12
        ewin.webContents.openDevTools({mode:'detach'})


show_questions_window = ->
    # ewin.setAlwaysOnTop true
    require('./questions').show_window()

report_window = null
show_report_window = ->
    if report_window
        report_window.show()
    else
        report_window = ewin.create_report_window()
        report_window.on 'closed', ->
            report_window = null

settings_window = null
show_settings_window = ->
    if settings_window
        settings_window.show()
    else
        settings_window = ewin.create_settings_window()
        settings_window.on 'closed', ->
            settings_window = null

AutoLaunch = require 'auto-launch'
auto_launcher = window.auto_launcher = new AutoLaunch
    name: 'myou-log'

{settings, add_post_save_callback} = ewin

add_post_save_callback ->
    apply_settings()

show_questions_window_shortcut = false
show_report_window_shortcut = false
show_settings_window_shortcut = false
yes_shortcut = false
no_shortcut = false
# sound_test = false

apply_settings = ->
    if settings.open_on_startup
        auto_launcher.isEnabled().then (enabled)->
            if not enabled
                auto_launcher.enable().then ()->
                    console.log 'Open on system startup ENABLED'
    else
        auto_launcher.isEnabled().then (enabled)->
            if enabled
                auto_launcher.disable().then ()->
                    console.log 'Open on system startup DISABLED'

    if show_questions_window_shortcut
        globalShortcut.unregister show_questions_window_shortcut
    if show_report_window_shortcut
        globalShortcut.unregister show_report_window_shortcut
    if show_settings_window_shortcut
        globalShortcut.unregister show_settings_window_shortcut
    if yes_shortcut
        globalShortcut.unregister yes_shortcut
    if no_shortcut
        globalShortcut.unregister no_shortcut
    # if sound_test_shortcut
    #     globalShortcut.unregister sound_test_shortcut

    questions_registered = globalShortcut.register settings.global_shortcuts.questions_window, show_questions_window
    report_registered = globalShortcut.register settings.global_shortcuts.report_window, show_report_window
    settings_registered = globalShortcut.register settings.global_shortcuts.settings_window, show_settings_window
    # sound_test_registered = globalShortcut.register settings.global_shortcuts.sound_test, -> ui_alarm()

    if questions_registered
        show_questions_window_shortcut = settings.global_shortcuts.questions_window
    else
        show_questions_window_shortcut = false
        console.warn 'Global shorcut in use: ' + settings.global_shortcuts.questions_window
    if report_registered
        show_report_window_shortcut = settings.global_shortcuts.report_window
    else
        show_report_window_shortcut = false
        console.warn 'Global shorcut in use: ' + settings.global_shortcuts.report_window

    if settings_registered
        show_settings_window_shortcut = settings.global_shortcuts.settings_window
    else
        show_settings_window_shortcut = false
        console.warn 'Global shorcut in use: ' + settings.global_shortcuts.settings_window

    # if sound_test_registered
    #     sound_test_shortcut = settings.global_shortcuts.questions_window
    # else
    #     sound_test_shortcut = false
    #     console.warn 'Global shorcut in use: ' + settings.global_shortcuts.sound_test

apply_settings()

trayMenuTemplate = [
    {
       label: 'Show questions',
       click: ->
          show_questions_window()
    }
    {
       label: 'Show report',
       click: ->
          show_report_window()
    }
    {
       label: 'Show settings',
       click: ->
          show_settings_window()
    }
    {
       label: 'Quit',
       click: ->
           localStorage.myoulog_win_position = JSON.stringify ewin.getPosition()
           tray.destroy()
           ewin.close()
    }
]

trayMenu = Menu.buildFromTemplate trayMenuTemplate

if is_win
    icon = '/../../assets/icons/win/icon.ico'
if is_mac
    icon = '/../../assets/icons/mac/icon.icns'
else
    icon = '/../../assets/icons/png/24x24.png'


tray = new Tray __dirname + icon

tray.setContextMenu trayMenu
tray.on 'click', ->
    show_questions_window()

addEventListener 'beforeunload', ->
    tray.destroy()
    globalShortcut.unregisterAll()

show_questions_window()
