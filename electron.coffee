fs = require 'fs'
path = require 'path'

platform = process.platform
is_linux = platform == 'linux'
app_proccess = process.execPath.split(path.sep).pop()

isDebug = /^electron/.test app_proccess
isElectron = /^electron|myou-log/.test  app_proccess

if isElectron
    {app, BrowserWindow, globalShortcut} = require 'electron'
    if not app? # old electron api
        app = require('app') # Module to control application life.
        BrowserWindow = require('browser-window')  # Module to create native browser window.
    path = require 'path'
    url = require 'url'

    # Keep a global reference of the window object, if you don't, the window will
    # be closed automatically when the JavaScript object is garbage collected.

    MYOU_LOG_SETTINGS = {
        "inactivity_check_interval": 300000,
        "auto_show_window_timeout": 300000,
    }

    if isDebug
        MYOU_LOG_SETTINGS.open_on_startup = false
        MYOU_LOG_SETTINGS.autoOpenDevTools = false

    save_settings = (settings)->
        data = JSON.stringify settings, null, 4
        fs.writeFile 'settings.json', data, (err)->
            if err then console.log err
            else console.log data

    ensure_settings_file = new Promise (resolve, reject)->
        if fs.existsSync 'settings.json'
            fs.readFile 'settings.json', 'utf8', (err, data)->
                if err
                    console.log err
                    console.log 'Using default settings.'
                else
                    settings = null
                    try
                        settings = JSON.parse(data)
                        console.log 'Settings file read.'
                    catch err
                        settings = MYOU_LOG_SETTINGS
                        console.log err
                        console.log 'Using default settings.'

                    for k,v of settings
                        if not MYOU_LOG_SETTINGS.k?
                            MYOU_LOG_SETTINGS[k] = v

                    save_settings MYOU_LOG_SETTINGS

                resolve()

        else
            console.log 'Settings file not found. Generating default settings file:'
            save_settings MYOU_LOG_SETTINGS
            resolve()

    create_report_window = ->
        options =
            title: 'MyouLog - Report'
            titleBarStyle: 'hidden-inset'
        win = new BrowserWindow options
        win.loadURL url.format
            pathname: path.join __dirname, '/static_files/report_window.html'
            protocol: 'file:'
            slashes: true
        win.setMenuBarVisibility false

    create_main_window = ->
        options =
            width: 350
            height: 200
            frame: if is_linux then true else false
            transparent: if is_linux then false else true
            show: true
            icon: path.join __dirname, 'static_files/images/icon.png'
            title: 'MyouLog'
            skipTaskbar: true

        # Create the browser window.
        win = new BrowserWindow options

        # Load the html of the app.
        win.loadURL url.format
            pathname: path.join __dirname, '/static_files/main_window.html'
            protocol: 'file:'
            slashes: true


        win.setMenuBarVisibility false
        # Open the DevTools.
        if isDebug and MYOU_LOG_SETTINGS.autoOpenDevTools then win.webContents.openDevTools()

        # Emitted when the window is closed.
        win.on 'closed', =>
            # Dereference the window object, usually you would store windows
            # in an array if your app supports multi windows, this is the time
            # when you should delete the corresponding element.
            win.tray?.destroy()
            win = null

        win.app = app
        win.isDebug = isDebug
        win.create_report_window = create_report_window
        win.MYOU_LOG_SETTINGS = MYOU_LOG_SETTINGS


    # Quit when all windows are closed.
    app.on 'window-all-closed', =>
        # On macOS it is common for applications and their menu bar
        # to stay active until the user quits explicitly with Cmd + Q
        if process.platform != 'darwin'
            app.quit()

    app.on 'will-quit', ->
        globalShortcut.unregisterAll()

    app.on 'activate', ->
        # On macOS it's common to re-create a window in the app when the
        # dock icon is clicked and there are no other windows open.
        if not win?
            create_main_window()

    # In this file you can include the rest of your app's specific main process
    # code. You can also put them in separate files and require them here.

    # This method will be called when Electron has finished
    # initialization and is ready to create browser windows.
    # Some APIs can only be used after this event occurs.
    app.on 'ready', ->
        ensure_settings_file.then -> create_main_window()
else
    electron = require 'electron-prebuilt'
    proc = require 'child_process'
    # spawn electron
    child = proc.spawnSync electron, ["node_modules/coffee-script/bin/coffee", __filename], {stdio: 'inherit', shell: true}
