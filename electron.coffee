fs = require 'fs'
path = require 'path'

platform = process.platform
is_linux = platform == 'linux'
app_proccess = process.execPath.split(path.sep).pop()

isDebug = /^electron/.test app_proccess
isElectron = /^electron|myou-log/.test  app_proccess

if isElectron
    {settings, save_settings, load_settings} = require './src/settings'
    settings_primise = load_settings()


    {app, BrowserWindow, globalShortcut} = require 'electron'
    if not app? # old electron api
        app = require('app') # Module to control application life.
        BrowserWindow = require('browser-window')  # Module to create native browser window.
    path = require 'path'
    url = require 'url'

    # Keep a global reference of the window object, if you don't, the window will
    # be closed automatically when the JavaScript object is garbage collected.

    create_report_window = -> settings_primise.then ->
        options =
            title: 'MyouLog - Report'
            titleBarStyle: 'hidden-inset'
            width: 600
            height: 600
            minWidth: 600
            minHeight: 200
        win = new BrowserWindow options
        win.loadURL url.format
            pathname: path.join __dirname, '/static_files/report_window.html'
            protocol: 'file:'
            slashes: true
        win.setMenuBarVisibility false
        win.settings = settings
        win.isDebug = isDebug
        return Promise.resolve(win)

    create_main_window = -> settings_primise.then ->
        if isDebug
            settings.open_on_startup = false
            if not settings.auto_open_dev_tools? then settings.auto_open_dev_tools = false
            save_settings()

        options =
            width: 350
            height: 220
            frame: if is_linux then true else false
            transparent: if is_linux then false else true
            show: true
            icon: path.join __dirname, 'static_files/images/icon.png'
            title: 'MyouLog'
            skipTaskbar: true
            resizable: false

        # Create the browser window.
        win = new BrowserWindow options

        win.setMenuBarVisibility false
        # Open the DevTools.
        if settings.auto_open_dev_tools
            win.webContents.openDevTools({mode:'detach'})

        # Emitted when the window is closed.
        win.on 'closed', =>
            # Dereference the window object, usually you would store windows
            # in an array if your app supports multi windows, this is the time
            # when you should delete the corresponding element.
            win.tray?.destroy()
            win = null

        win.isDebug = isDebug
        win.create_report_window = create_report_window
        win.settings = settings

        # Load the html of the app.
        win.loadURL url.format
            pathname: path.join __dirname, '/static_files/main_window.html'
            protocol: 'file:'
            slashes: true


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
        create_main_window()
else
    electron = require 'electron-prebuilt'
    proc = require 'child_process'
    # spawn electron
    child = proc.spawnSync electron, ["node_modules/coffee-script/bin/coffee", __filename], {stdio: 'inherit', shell: true}
